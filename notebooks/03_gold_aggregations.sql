-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 — Agregações da Camada Gold
-- MAGIC
-- MAGIC ## Objetivo
-- MAGIC
-- MAGIC Transformar os dados tratados da camada Silver em produtos analíticos
-- MAGIC prontos para consumo, alinhados às perguntas de negócio do desafio.
-- MAGIC
-- MAGIC A camada Gold cria três tabelas Delta pré-agregadas:
-- MAGIC
-- MAGIC - beneficiários por operadora;
-- MAGIC - beneficiários por faixa etária;
-- MAGIC - beneficiários por município.
-- MAGIC
-- MAGIC ## Entrada
-- MAGIC
-- MAGIC `healthcare_silver.ans_beneficiarios`
-- MAGIC
-- MAGIC ## Saídas
-- MAGIC
-- MAGIC - `healthcare_gold.gold_operadora_beneficiarios`
-- MAGIC - `healthcare_gold.gold_faixa_etaria_beneficiarios`
-- MAGIC - `healthcare_gold.gold_municipio_beneficiarios`
-- MAGIC
-- MAGIC ## Decisão de performance
-- MAGIC
-- MAGIC As agregações são materializadas em tabelas Delta para evitar o
-- MAGIC recálculo das métricas a cada consulta. Como a primeira versão possui
-- MAGIC apenas uma competência e volume moderado, não foi aplicado
-- MAGIC particionamento físico. Em um cenário histórico, seria avaliado
-- MAGIC clustering ou particionamento por `competencia`.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 1 — Agregação por operadora
-- MAGIC
-- MAGIC Cria uma visão consolidada por competência e operadora, somando as
-- MAGIC quantidades de beneficiários ativos, aderidos e cancelados.
-- MAGIC
-- MAGIC **Grão:** uma linha por competência e operadora.

-- COMMAND ----------

-- DBTITLE 1,Criação da Gold por operadora
CREATE OR REPLACE TABLE healthcare_gold.gold_operadora_beneficiarios
USING DELTA
COMMENT 'Beneficiários agregados por competência e operadora'
AS
SELECT
    competencia,
    codigo_operadora,
    razao_social,
    cnpj,
    modalidade_operadora,
    SUM(quantidade_beneficiarios_ativos) AS quantidade_beneficiarios_ativos,
    SUM(quantidade_beneficiarios_aderidos) AS quantidade_beneficiarios_aderidos,
    SUM(quantidade_beneficiarios_cancelados) AS quantidade_beneficiarios_cancelados
FROM healthcare_silver.ans_beneficiarios
GROUP BY
    competencia,
    codigo_operadora,
    razao_social,
    cnpj,
    modalidade_operadora;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 2 — Agregação por faixa etária
-- MAGIC
-- MAGIC Consolida a quantidade de beneficiários ativos por faixa etária.
-- MAGIC A coluna `ordem_faixa_etaria` permite ordenar as faixas de forma
-- MAGIC cronológica, evitando ordenação alfabética incorreta.
-- MAGIC
-- MAGIC **Grão:** uma linha por competência e faixa etária.

-- COMMAND ----------

-- DBTITLE 1,Criação da Gold por faixa etária
CREATE OR REPLACE TABLE healthcare_gold.gold_faixa_etaria_beneficiarios
USING DELTA
COMMENT 'Beneficiários ativos agregados por competência e faixa etária'
AS
SELECT
    competencia,
    faixa_etaria,
    CASE
        WHEN faixa_etaria = '0 a 4 anos' THEN 1
        WHEN faixa_etaria = '5 a 9 anos' THEN 2
        WHEN faixa_etaria = '10 a 14 anos' THEN 3
        WHEN faixa_etaria = '15 a 19 anos' THEN 4
        WHEN faixa_etaria = '20 a 24 anos' THEN 5
        WHEN faixa_etaria = '25 a 29 anos' THEN 6
        WHEN faixa_etaria = '30 a 34 anos' THEN 7
        WHEN faixa_etaria = '35 a 39 anos' THEN 8
        WHEN faixa_etaria = '40 a 44 anos' THEN 9
        WHEN faixa_etaria = '45 a 49 anos' THEN 10
        WHEN faixa_etaria = '50 a 54 anos' THEN 11
        WHEN faixa_etaria = '55 a 59 anos' THEN 12
        WHEN faixa_etaria = '60 a 64 anos' THEN 13
        WHEN faixa_etaria = '65 a 69 anos' THEN 14
        WHEN faixa_etaria = '70 a 74 anos' THEN 15
        WHEN faixa_etaria = '75 a 79 anos' THEN 16
        WHEN faixa_etaria = '80 anos ou mais' THEN 17
        ELSE 99
    END AS ordem_faixa_etaria,
    SUM(quantidade_beneficiarios_ativos) AS quantidade_beneficiarios_ativos
FROM healthcare_silver.ans_beneficiarios
GROUP BY
    competencia,
    faixa_etaria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 3 — Agregação por município
-- MAGIC
-- MAGIC Consolida a quantidade de beneficiários ativos por município e
-- MAGIC competência.
-- MAGIC
-- MAGIC **Grão:** uma linha por competência, UF e município.

-- COMMAND ----------

-- DBTITLE 1,Criação da Gold por município
CREATE OR REPLACE TABLE healthcare_gold.gold_municipio_beneficiarios
USING DELTA
COMMENT 'Beneficiários ativos agregados por competência e município'
AS
SELECT
    competencia,
    uf,
    codigo_municipio,
    municipio,
    SUM(quantidade_beneficiarios_ativos) AS quantidade_beneficiarios_ativos
FROM healthcare_silver.ans_beneficiarios
GROUP BY
    competencia,
    uf,
    codigo_municipio,
    municipio;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 4 — Volumetria das tabelas Gold
-- MAGIC
-- MAGIC Apresenta a quantidade de linhas produzidas em cada produto analítico.

-- COMMAND ----------

-- DBTITLE 1,Resumo das tabelas Gold
SELECT
    'gold_operadora_beneficiarios' AS objeto,
    COUNT(*) AS quantidade_registros
FROM healthcare_gold.gold_operadora_beneficiarios

UNION ALL

SELECT
    'gold_faixa_etaria_beneficiarios',
    COUNT(*)
FROM healthcare_gold.gold_faixa_etaria_beneficiarios

UNION ALL

SELECT
    'gold_municipio_beneficiarios',
    COUNT(*)
FROM healthcare_gold.gold_municipio_beneficiarios;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 5 — Reconciliação das métricas
-- MAGIC
-- MAGIC Compara o total de beneficiários ativos da Silver com os totais
-- MAGIC materializados nas três tabelas Gold. As diferenças esperadas são zero.

-- COMMAND ----------

-- DBTITLE 1,Reconciliação Silver versus Gold
WITH silver_total AS (
    SELECT
        SUM(quantidade_beneficiarios_ativos) AS total_ativos
    FROM healthcare_silver.ans_beneficiarios
),
gold_operadora AS (
    SELECT
        SUM(quantidade_beneficiarios_ativos) AS total_ativos
    FROM healthcare_gold.gold_operadora_beneficiarios
),
gold_faixa AS (
    SELECT
        SUM(quantidade_beneficiarios_ativos) AS total_ativos
    FROM healthcare_gold.gold_faixa_etaria_beneficiarios
),
gold_municipio AS (
    SELECT
        SUM(quantidade_beneficiarios_ativos) AS total_ativos
    FROM healthcare_gold.gold_municipio_beneficiarios
)
SELECT
    s.total_ativos AS silver_total_ativos,
    o.total_ativos AS gold_operadora_total_ativos,
    f.total_ativos AS gold_faixa_total_ativos,
    m.total_ativos AS gold_municipio_total_ativos,
    s.total_ativos - o.total_ativos AS diferenca_operadora,
    s.total_ativos - f.total_ativos AS diferenca_faixa,
    s.total_ativos - m.total_ativos AS diferenca_municipio
FROM silver_total s
CROSS JOIN gold_operadora o
CROSS JOIN gold_faixa f
CROSS JOIN gold_municipio m;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 6 — Amostras dos produtos analíticos
-- MAGIC
-- MAGIC Exibe os principais resultados para uma validação funcional rápida.

-- COMMAND ----------

-- DBTITLE 1,Top 5 operadoras por beneficiários ativos
SELECT
    competencia,
    codigo_operadora,
    razao_social,
    modalidade_operadora,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_operadora_beneficiarios
ORDER BY quantidade_beneficiarios_ativos DESC
LIMIT 5;

-- COMMAND ----------

-- DBTITLE 1,Faixas etárias por beneficiários ativos
SELECT
    competencia,
    faixa_etaria,
    ordem_faixa_etaria,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_faixa_etaria_beneficiarios
ORDER BY quantidade_beneficiarios_ativos DESC;

-- COMMAND ----------

-- DBTITLE 1,Municípios por beneficiários ativos
SELECT
    competencia,
    uf,
    codigo_municipio,
    municipio,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_municipio_beneficiarios
ORDER BY quantidade_beneficiarios_ativos DESC, municipio
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Resultado esperado
-- MAGIC
-- MAGIC Ao final da execução:
-- MAGIC
-- MAGIC - as três tabelas Gold devem existir em formato Delta;
-- MAGIC - cada tabela deve respeitar o grão documentado;
-- MAGIC - as métricas agregadas devem reconciliar com a camada Silver;
-- MAGIC - as diferenças da reconciliação devem ser iguais a zero;
-- MAGIC - os produtos devem estar prontos para responder às consultas do desafio.
-- MAGIC
-- MAGIC ## Próximo notebook
-- MAGIC
-- MAGIC `04_analytical_queries.sql`

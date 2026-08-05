-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 04 — Consultas Analíticas
-- MAGIC
-- MAGIC ## Objetivo
-- MAGIC
-- MAGIC Apresentar as respostas às três perguntas de negócio solicitadas no
-- MAGIC desafio, utilizando exclusivamente os produtos analíticos materializados
-- MAGIC na camada Gold.
-- MAGIC
-- MAGIC ## Tabelas utilizadas
-- MAGIC
-- MAGIC - `healthcare_gold.gold_operadora_beneficiarios`
-- MAGIC - `healthcare_gold.gold_faixa_etaria_beneficiarios`
-- MAGIC - `healthcare_gold.gold_municipio_beneficiarios`
-- MAGIC
-- MAGIC As consultas priorizam legibilidade, ordenação determinística e
-- MAGIC explicitação da competência analisada.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Pergunta 1 — Quais são as 5 operadoras com maior número de beneficiários ativos?
-- MAGIC
-- MAGIC A consulta ordena as operadoras pela quantidade total de beneficiários
-- MAGIC ativos em ordem decrescente e retorna as cinco primeiras posições.
-- MAGIC
-- MAGIC Em caso de empate, o código da operadora é utilizado como critério
-- MAGIC adicional de ordenação para garantir resultado determinístico.

-- COMMAND ----------

-- DBTITLE 1,Top 5 operadoras por beneficiários ativos
SELECT
    competencia,
    codigo_operadora,
    razao_social,
    modalidade_operadora,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_operadora_beneficiarios
ORDER BY
    quantidade_beneficiarios_ativos DESC,
    codigo_operadora
LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Pergunta 2 — Qual é a faixa etária com mais beneficiários e quantos são?
-- MAGIC
-- MAGIC A consulta identifica a faixa etária com a maior quantidade agregada de
-- MAGIC beneficiários ativos.
-- MAGIC
-- MAGIC Em caso de empate, a coluna `ordem_faixa_etaria` preserva a ordem
-- MAGIC cronológica das faixas.

-- COMMAND ----------

-- DBTITLE 1,Faixa etária com maior quantidade de beneficiários ativos
SELECT
    competencia,
    faixa_etaria,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_faixa_etaria_beneficiarios
ORDER BY
    quantidade_beneficiarios_ativos DESC,
    ordem_faixa_etaria
LIMIT 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Pergunta 3 — Qual é a quantidade de beneficiários por município?
-- MAGIC
-- MAGIC A consulta apresenta todos os municípios em ordem decrescente de
-- MAGIC beneficiários ativos. O nome do município é utilizado como segundo
-- MAGIC critério de ordenação para tornar o resultado determinístico.

-- COMMAND ----------

-- DBTITLE 1,Beneficiários ativos por município
SELECT
    competencia,
    uf,
    codigo_municipio,
    municipio,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_municipio_beneficiarios
ORDER BY
    quantidade_beneficiarios_ativos DESC,
    municipio;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Validação complementar — participação percentual das maiores operadoras
-- MAGIC
-- MAGIC Esta consulta não é obrigatória no desafio, mas demonstra como o produto
-- MAGIC Gold pode ser reutilizado para análises adicionais sem novo processamento
-- MAGIC da camada Silver.

-- COMMAND ----------

-- DBTITLE 1,Participação percentual das 5 maiores operadoras
WITH operadoras AS (
    SELECT
        competencia,
        codigo_operadora,
        razao_social,
        quantidade_beneficiarios_ativos,
        SUM(quantidade_beneficiarios_ativos)
            OVER (PARTITION BY competencia) AS total_competencia
    FROM healthcare_gold.gold_operadora_beneficiarios
),
ranking AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY competencia
            ORDER BY quantidade_beneficiarios_ativos DESC, codigo_operadora
        ) AS posicao
    FROM operadoras
)
SELECT
    competencia,
    posicao,
    codigo_operadora,
    razao_social,
    quantidade_beneficiarios_ativos,
    ROUND(
        100.0 * quantidade_beneficiarios_ativos / NULLIF(total_competencia, 0),
        2
    ) AS percentual_sobre_total
FROM ranking
WHERE posicao <= 5
ORDER BY competencia, posicao;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Resultado esperado
-- MAGIC
-- MAGIC Ao final da execução, o notebook deve apresentar:
-- MAGIC
-- MAGIC - as cinco operadoras com maior quantidade de beneficiários ativos;
-- MAGIC - a faixa etária com maior quantidade de beneficiários ativos;
-- MAGIC - a relação completa dos municípios em ordem decrescente;
-- MAGIC - uma análise complementar da participação percentual das maiores
-- MAGIC   operadoras.
-- MAGIC
-- MAGIC Os resultados exibidos neste notebook devem ser utilizados como
-- MAGIC evidências da entrega.
-- MAGIC
-- MAGIC ## Próximo notebook
-- MAGIC
-- MAGIC `05_validation_queries.sql`

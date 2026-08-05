-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 — Gold Layer
-- MAGIC Agregações orientadas às perguntas analíticas do desafio.

-- COMMAND ----------

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
GROUP BY competencia, faixa_etaria;

-- COMMAND ----------

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

SELECT 'operadoras' AS objeto, COUNT(*) AS quantidade
FROM healthcare_gold.gold_operadora_beneficiarios
UNION ALL
SELECT 'faixas_etarias', COUNT(*)
FROM healthcare_gold.gold_faixa_etaria_beneficiarios
UNION ALL
SELECT 'municipios', COUNT(*)
FROM healthcare_gold.gold_municipio_beneficiarios;

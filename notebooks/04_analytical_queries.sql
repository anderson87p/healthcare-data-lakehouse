-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 04 — Consultas Analíticas
-- MAGIC Respostas às perguntas solicitadas no desafio.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1. Cinco operadoras com maior número de beneficiários ativos

-- COMMAND ----------

SELECT
    codigo_operadora,
    razao_social,
    modalidade_operadora,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_operadora_beneficiarios
ORDER BY quantidade_beneficiarios_ativos DESC
LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2. Faixa etária com mais beneficiários

-- COMMAND ----------

SELECT
    faixa_etaria,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_faixa_etaria_beneficiarios
ORDER BY quantidade_beneficiarios_ativos DESC
LIMIT 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3. Quantidade de beneficiários por município em ordem decrescente

-- COMMAND ----------

SELECT
    uf,
    codigo_municipio,
    municipio,
    quantidade_beneficiarios_ativos
FROM healthcare_gold.gold_municipio_beneficiarios
ORDER BY quantidade_beneficiarios_ativos DESC, municipio;

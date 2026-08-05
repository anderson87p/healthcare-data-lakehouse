-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 05 — Validações
-- MAGIC Verificações de volumetria, domínio e consistência.

-- COMMAND ----------

SELECT
    (SELECT COUNT(*) FROM healthcare_bronze.ans_beneficiarios_raw) AS bronze_registros,
    (SELECT COUNT(*) FROM healthcare_silver.ans_beneficiarios) AS silver_registros,
    (SELECT COUNT(*) FROM healthcare_quarantine.ans_beneficiarios_invalidos) AS quarantine_registros;

-- COMMAND ----------

SELECT
    COUNT(*) AS quantidades_negativas
FROM healthcare_silver.ans_beneficiarios
WHERE quantidade_beneficiarios_ativos < 0
   OR quantidade_beneficiarios_aderidos < 0
   OR quantidade_beneficiarios_cancelados < 0;

-- COMMAND ----------

SELECT
    uf,
    COUNT(*) AS registros
FROM healthcare_silver.ans_beneficiarios
GROUP BY uf
ORDER BY registros DESC;

-- COMMAND ----------

SELECT
    competencia,
    SUM(quantidade_beneficiarios_ativos) AS silver_ativos,
    (
        SELECT SUM(quantidade_beneficiarios_ativos)
        FROM healthcare_gold.gold_municipio_beneficiarios
    ) AS gold_municipio_ativos
FROM healthcare_silver.ans_beneficiarios
GROUP BY competencia;

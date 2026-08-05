-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 05 — Validações do Pipeline
-- MAGIC
-- MAGIC ## Objetivo
-- MAGIC
-- MAGIC Executar verificações finais de consistência para confirmar que o
-- MAGIC pipeline foi processado corretamente e que as camadas Bronze, Silver
-- MAGIC e Gold estão reconciliadas.
-- MAGIC
-- MAGIC ## Escopo das validações
-- MAGIC
-- MAGIC - volumetria das camadas;
-- MAGIC - reconciliação Silver x Gold;
-- MAGIC - registros em Quarantine;
-- MAGIC - domínio de competência e UF;
-- MAGIC - valores negativos;
-- MAGIC - status geral do pipeline.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 1 — Volumetria das camadas

-- COMMAND ----------

SELECT
    (SELECT COUNT(*) FROM healthcare_bronze.ans_beneficiarios_raw) AS bronze_registros,
    (SELECT COUNT(*) FROM healthcare_silver.ans_beneficiarios) AS silver_registros,
    (SELECT COUNT(*) FROM healthcare_quarantine.ans_beneficiarios_invalidos) AS quarantine_registros,
    (SELECT COUNT(*) FROM healthcare_gold.gold_operadora_beneficiarios) AS gold_operadora,
    (SELECT COUNT(*) FROM healthcare_gold.gold_faixa_etaria_beneficiarios) AS gold_faixa_etaria,
    (SELECT COUNT(*) FROM healthcare_gold.gold_municipio_beneficiarios) AS gold_municipio;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 2 — Validação de valores negativos

-- COMMAND ----------

SELECT
    COUNT(*) AS quantidades_negativas
FROM healthcare_silver.ans_beneficiarios
WHERE quantidade_beneficiarios_ativos < 0
   OR quantidade_beneficiarios_aderidos < 0
   OR quantidade_beneficiarios_cancelados < 0;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 3 — Validação da competência

-- COMMAND ----------

SELECT
    competencia,
    COUNT(*) AS registros
FROM healthcare_silver.ans_beneficiarios
GROUP BY competencia;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 4 — Validação da UF

-- COMMAND ----------

SELECT
    uf,
    COUNT(*) AS registros
FROM healthcare_silver.ans_beneficiarios
GROUP BY uf
ORDER BY registros DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 5 — Reconciliação Silver x Gold

-- COMMAND ----------

WITH silver AS (
SELECT SUM(quantidade_beneficiarios_ativos) total FROM healthcare_silver.ans_beneficiarios
),
operadora AS (
SELECT SUM(quantidade_beneficiarios_ativos) total FROM healthcare_gold.gold_operadora_beneficiarios
),
faixa AS (
SELECT SUM(quantidade_beneficiarios_ativos) total FROM healthcare_gold.gold_faixa_etaria_beneficiarios
),
municipio AS (
SELECT SUM(quantidade_beneficiarios_ativos) total FROM healthcare_gold.gold_municipio_beneficiarios
)
SELECT
silver.total AS silver_total,
operadora.total AS gold_operadora_total,
faixa.total AS gold_faixa_total,
municipio.total AS gold_municipio_total,
silver.total-operadora.total AS diff_operadora,
silver.total-faixa.total AS diff_faixa,
silver.total-municipio.total AS diff_municipio
FROM silver
CROSS JOIN operadora
CROSS JOIN faixa
CROSS JOIN municipio;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Etapa 6 — Status do Pipeline

-- COMMAND ----------

SELECT
CASE
WHEN
(SELECT COUNT(*) FROM healthcare_quarantine.ans_beneficiarios_invalidos)=0
AND
(SELECT COUNT(*) FROM healthcare_silver.ans_beneficiarios
WHERE quantidade_beneficiarios_ativos<0
OR quantidade_beneficiarios_aderidos<0
OR quantidade_beneficiarios_cancelados<0)=0
THEN 'SUCCESS'
ELSE 'CHECK REQUIRED'
END AS pipeline_status;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Resultado esperado
-- MAGIC
-- MAGIC Ao final da execução:
-- MAGIC
-- MAGIC - todas as consultas devem executar sem erro;
-- MAGIC - a reconciliação Silver x Gold deve apresentar diferenças iguais a zero;
-- MAGIC - não devem existir quantidades negativas;
-- MAGIC - o pipeline deve retornar o status **SUCCESS**;
-- MAGIC - estas consultas servem como evidência da execução do desafio.

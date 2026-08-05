-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 01 — Ingestão da Camada Bronze
-- MAGIC
-- MAGIC ## Objetivo
-- MAGIC
-- MAGIC Ingerir o arquivo público da ANS no formato CSV e persistir seu
-- MAGIC conteúdo em uma tabela Delta, preservando o layout original.
-- MAGIC
-- MAGIC A camada Bronze:
-- MAGIC
-- MAGIC - mantém as colunas de origem sem regras de negócio;
-- MAGIC - lê os campos como texto para evitar conversões implícitas;
-- MAGIC - acrescenta metadados técnicos de rastreabilidade;
-- MAGIC - registra volumetria, competência e unidade federativa recebidas.
-- MAGIC
-- MAGIC **Arquivo esperado:** `pda-024-icb-TO-2025_08.csv`

-- COMMAND ----------

-- DBTITLE 1,Validação do arquivo de entrada
LIST '/Volumes/workspace/healthcare_landing/source/';

-- COMMAND ----------

-- DBTITLE 1,Criação da tabela Delta Bronze
CREATE OR REPLACE TABLE healthcare_bronze.ans_beneficiarios_raw
USING DELTA
COMMENT 'Dados brutos de beneficiários da ANS preservados com metadados técnicos'
AS
SELECT
    source.*,
    source._metadata.file_path AS _source_file,
    source._metadata.file_name AS _source_file_name,
    current_timestamp() AS _ingestion_timestamp,
    'TO_2025_08' AS _batch_id
FROM read_files(
    '/Volumes/workspace/healthcare_landing/source/*.csv',
    format => 'csv',
    header => true,
    sep => ';',
    encoding => 'UTF-8',
    inferSchema => false,
    mode => 'FAILFAST'
) AS source;

-- COMMAND ----------

-- DBTITLE 1,Amostra dos dados ingeridos
SELECT *
FROM healthcare_bronze.ans_beneficiarios_raw
LIMIT 20;

-- COMMAND ----------

-- DBTITLE 1,Volumetria da ingestão
SELECT
    COUNT(*) AS quantidade_registros,
    COUNT(DISTINCT _source_file) AS quantidade_arquivos,
    COUNT(DISTINCT _batch_id) AS quantidade_batches,
    MIN(_ingestion_timestamp) AS primeira_ingestao,
    MAX(_ingestion_timestamp) AS ultima_ingestao
FROM healthcare_bronze.ans_beneficiarios_raw;

-- COMMAND ----------

-- DBTITLE 1,Validação da competência recebida
SELECT
    ID_CMPT_MOVEL AS competencia_origem,
    COUNT(*) AS quantidade_registros
FROM healthcare_bronze.ans_beneficiarios_raw
GROUP BY ID_CMPT_MOVEL
ORDER BY ID_CMPT_MOVEL;

-- COMMAND ----------

-- DBTITLE 1,Validação da unidade federativa
SELECT
    SG_UF AS uf_origem,
    COUNT(*) AS quantidade_registros
FROM healthcare_bronze.ans_beneficiarios_raw
GROUP BY SG_UF
ORDER BY quantidade_registros DESC;

-- COMMAND ----------

-- DBTITLE 1,Validação inicial das colunas essenciais
SELECT
    SUM(CASE WHEN CD_OPERADORA IS NULL OR TRIM(CD_OPERADORA) = '' THEN 1 ELSE 0 END)
        AS registros_sem_operadora,
    SUM(CASE WHEN CD_MUNICIPIO IS NULL OR TRIM(CD_MUNICIPIO) = '' THEN 1 ELSE 0 END)
        AS registros_sem_municipio,
    SUM(CASE WHEN QT_BENEFICIARIO_ATIVO IS NULL OR TRIM(QT_BENEFICIARIO_ATIVO) = '' THEN 1 ELSE 0 END)
        AS registros_sem_quantidade_ativos,
    SUM(CASE WHEN ID_CMPT_MOVEL IS NULL OR TRIM(ID_CMPT_MOVEL) = '' THEN 1 ELSE 0 END)
        AS registros_sem_competencia
FROM healthcare_bronze.ans_beneficiarios_raw;

-- COMMAND ----------

-- DBTITLE 1,Resumo da tabela criada
DESCRIBE DETAIL healthcare_bronze.ans_beneficiarios_raw;

-- COMMAND ----------

-- DBTITLE 1,Resumo da ingestão
SELECT
    COUNT(*) AS quantidade_registros,
    COUNT(DISTINCT CD_OPERADORA) AS operadoras,
    COUNT(DISTINCT CD_MUNICIPIO) AS municipios,
    COUNT(DISTINCT CD_PLANO) AS planos
FROM healthcare_bronze.ans_beneficiarios_raw;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Resultado esperado
-- MAGIC
-- MAGIC Ao final da execução:
-- MAGIC
-- MAGIC - a tabela `healthcare_bronze.ans_beneficiarios_raw` deve existir;
-- MAGIC - o arquivo deve estar persistido em formato Delta;
-- MAGIC - as colunas originais devem estar preservadas;
-- MAGIC - os metadados `_source_file`, `_source_file_name`,
-- MAGIC   `_ingestion_timestamp` e `_batch_id` devem estar disponíveis;
-- MAGIC - a competência e a UF devem corresponder ao arquivo fornecido.
-- MAGIC
-- MAGIC ## Próximo notebook
-- MAGIC
-- MAGIC `02_silver_layer.sql`
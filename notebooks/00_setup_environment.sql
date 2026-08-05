-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 00 — Configuração do ambiente
-- MAGIC
-- MAGIC Este notebook prepara os objetos necessários para o pipeline:
-- MAGIC
-- MAGIC - schemas das camadas Landing, Bronze, Silver, Gold e Quarantine;
-- MAGIC - Volume para armazenamento do arquivo CSV de origem;
-- MAGIC - validação dos objetos criados.
-- MAGIC
-- MAGIC O catálogo atual é obtido automaticamente pelo Databricks.

-- COMMAND ----------

-- DBTITLE 1,Catálogo atual
SELECT current_catalog() AS catalogo_atual;

-- COMMAND ----------

-- DBTITLE 1,Criação dos schemas
CREATE SCHEMA IF NOT EXISTS healthcare_landing
COMMENT 'Área de entrada dos arquivos públicos da ANS';

CREATE SCHEMA IF NOT EXISTS healthcare_bronze
COMMENT 'Camada Bronze com dados brutos preservados';

CREATE SCHEMA IF NOT EXISTS healthcare_silver
COMMENT 'Camada Silver com dados tratados e validados';

CREATE SCHEMA IF NOT EXISTS healthcare_gold
COMMENT 'Camada Gold com agregações analíticas';

CREATE SCHEMA IF NOT EXISTS healthcare_quarantine
COMMENT 'Registros que não atendem às regras de qualidade';

-- COMMAND ----------

-- DBTITLE 1,Criação do Volume de entrada
CREATE VOLUME IF NOT EXISTS healthcare_landing.source
COMMENT 'Arquivos CSV de entrada da ANS';

-- COMMAND ----------

-- DBTITLE 1,Validação dos schemas
SHOW SCHEMAS LIKE 'healthcare_*';

-- COMMAND ----------

-- DBTITLE 1,Validação do Volume
SHOW VOLUMES IN healthcare_landing;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Próximo passo
-- MAGIC
-- MAGIC Faça o upload do arquivo:
-- MAGIC
-- MAGIC
-- MAGIC `pda-024-icb-TO-2025_08.csv`
-- MAGIC
-- MAGIC
-- MAGIC para o caminho:
-- MAGIC
-- MAGIC
-- MAGIC `/Volumes/workspace/healthcare_landing/source/`
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02 — Transformação da Camada Silver
-- MAGIC
-- MAGIC ## Objetivo
-- MAGIC
-- MAGIC Transformar os dados brutos da camada Bronze em um conjunto de dados
-- MAGIC confiável, tipado e preparado para consumo analítico.
-- MAGIC
-- MAGIC Nesta etapa são aplicadas as principais regras de qualidade e padronização
-- MAGIC dos dados, preservando a rastreabilidade da origem e separando registros
-- MAGIC inválidos para a camada de Quarantine.
-- MAGIC
-- MAGIC ## Principais transformações
-- MAGIC
-- MAGIC - Conversão explícita dos tipos de dados;
-- MAGIC - Padronização dos nomes das colunas em `snake_case`;
-- MAGIC - Limpeza e normalização de valores textuais;
-- MAGIC - Criação de uma chave técnica (`chave_registro`) baseada nos principais
-- MAGIC   atributos dimensionais;
-- MAGIC - Validação das regras de qualidade;
-- MAGIC - Separação de registros inválidos para Quarantine;
-- MAGIC - Deduplicação determinística quando aplicável.
-- MAGIC
-- MAGIC ## Entrada
-- MAGIC
-- MAGIC healthcare_bronze.ans_beneficiarios_raw
-- MAGIC
-- MAGIC ## Saídas
-- MAGIC
-- MAGIC healthcare_silver.ans_beneficiarios
-- MAGIC
-- MAGIC healthcare_quarantine.ans_beneficiarios_invalidos

-- COMMAND ----------

-- DBTITLE 1,Padronização e tipagem dos dados
CREATE OR REPLACE TEMP VIEW vw_ans_beneficiarios_typed AS
SELECT
    to_date(concat(trim(ID_CMPT_MOVEL), '-01'), 'yyyy-MM-dd') AS competencia,
    trim(CD_OPERADORA) AS codigo_operadora,
    trim(NM_RAZAO_SOCIAL) AS razao_social,
    lpad(regexp_replace(trim(NR_CNPJ), '[^0-9]', ''), 14, '0') AS cnpj,
    upper(trim(MODALIDADE_OPERADORA)) AS modalidade_operadora,
    upper(trim(SG_UF)) AS uf,
    trim(CD_MUNICIPIO) AS codigo_municipio,
    initcap(trim(NM_MUNICIPIO)) AS municipio,
    upper(trim(TP_SEXO)) AS sexo,
    trim(DE_FAIXA_ETARIA) AS faixa_etaria,
    trim(DE_FAIXA_ETARIA_REAJ) AS faixa_etaria_reajuste,
    trim(CD_PLANO) AS codigo_plano,
    upper(trim(TP_VIGENCIA_PLANO)) AS tipo_vigencia_plano,
    trim(DE_CONTRATACAO_PLANO) AS contratacao_plano,
    trim(DE_SEGMENTACAO_PLANO) AS segmentacao_plano,
    trim(DE_ABRG_GEOGRAFICA_PLANO) AS abrangencia_geografica,
    trim(COBERTURA_ASSIST_PLAN) AS cobertura_assistencial,
    trim(TIPO_VINCULO) AS tipo_vinculo,
    try_cast(QT_BENEFICIARIO_ATIVO AS BIGINT) AS quantidade_beneficiarios_ativos,
    try_cast(QT_BENEFICIARIO_ADERIDO AS BIGINT) AS quantidade_beneficiarios_aderidos,
    try_cast(QT_BENEFICIARIO_CANCELADO AS BIGINT) AS quantidade_beneficiarios_cancelados,
    to_date(trim(DT_CARGA), 'yyyy-MM-dd') AS data_carga,
    _source_file,
    _ingestion_timestamp,
    _batch_id
FROM healthcare_bronze.ans_beneficiarios_raw;

-- COMMAND ----------

-- DBTITLE 1,Validação das regras de qualidade
CREATE OR REPLACE TEMP VIEW vw_ans_beneficiarios_quality AS
SELECT
    *,
    CASE
        WHEN competencia IS NULL THEN 'COMPETENCIA_INVALIDA'
        WHEN codigo_operadora IS NULL OR codigo_operadora = '' THEN 'OPERADORA_INVALIDA'
        WHEN uf IS NULL OR uf = '' THEN 'UF_INVALIDA'
        WHEN codigo_municipio IS NULL OR codigo_municipio = '' THEN 'MUNICIPIO_INVALIDO'
        WHEN quantidade_beneficiarios_ativos IS NULL THEN 'QUANTIDADE_ATIVOS_INVALIDA'
        WHEN quantidade_beneficiarios_aderidos IS NULL THEN 'QUANTIDADE_ADERIDOS_INVALIDA'
        WHEN quantidade_beneficiarios_cancelados IS NULL THEN 'QUANTIDADE_CANCELADOS_INVALIDA'
        WHEN quantidade_beneficiarios_ativos < 0 THEN 'QUANTIDADE_ATIVOS_NEGATIVA'
        WHEN quantidade_beneficiarios_aderidos < 0 THEN 'QUANTIDADE_ADERIDOS_NEGATIVA'
        WHEN quantidade_beneficiarios_cancelados < 0 THEN 'QUANTIDADE_CANCELADOS_NEGATIVA'
        ELSE NULL
    END AS motivo_quarentena
FROM vw_ans_beneficiarios_typed;

-- COMMAND ----------

-- DBTITLE 1,Persistência da camada Silver
CREATE OR REPLACE TABLE healthcare_silver.ans_beneficiarios
USING DELTA
COMMENT 'Dados de beneficiários tipados, normalizados e deduplicados'
AS
WITH validos AS (
    SELECT *
    FROM vw_ans_beneficiarios_quality
    WHERE motivo_quarentena IS NULL
),
deduplicados AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY
                competencia,
                codigo_operadora,
                cnpj,
                uf,
                codigo_municipio,
                sexo,
                faixa_etaria,
                faixa_etaria_reajuste,
                codigo_plano,
                tipo_vigencia_plano,
                contratacao_plano,
                segmentacao_plano,
                abrangencia_geografica,
                cobertura_assistencial,
                tipo_vinculo,
                quantidade_beneficiarios_ativos,
                quantidade_beneficiarios_aderidos,
                quantidade_beneficiarios_cancelados,
                data_carga
            ORDER BY _ingestion_timestamp DESC
        ) AS _dedup_rank
    FROM validos
)
SELECT
    sha2(
        concat_ws(
            '||',
            cast(competencia AS STRING),
            codigo_operadora,
            coalesce(codigo_municipio, ''),
            coalesce(sexo, ''),
            coalesce(faixa_etaria, ''),
            coalesce(codigo_plano, ''),
            coalesce(tipo_vinculo, '')
        ),
        256
    ) AS chave_registro,
    competencia,
    codigo_operadora,
    razao_social,
    cnpj,
    modalidade_operadora,
    uf,
    codigo_municipio,
    municipio,
    sexo,
    faixa_etaria,
    faixa_etaria_reajuste,
    codigo_plano,
    tipo_vigencia_plano,
    contratacao_plano,
    segmentacao_plano,
    abrangencia_geografica,
    cobertura_assistencial,
    tipo_vinculo,
    quantidade_beneficiarios_ativos,
    quantidade_beneficiarios_aderidos,
    quantidade_beneficiarios_cancelados,
    data_carga,
    _source_file,
    _ingestion_timestamp,
    _batch_id
FROM deduplicados
WHERE _dedup_rank = 1;

-- COMMAND ----------

-- DBTITLE 1,Persistência da Quarantine
CREATE OR REPLACE TABLE healthcare_quarantine.ans_beneficiarios_invalidos
USING DELTA
COMMENT 'Registros inválidos identificados durante o tratamento Silver'
AS
SELECT *
FROM vw_ans_beneficiarios_quality
WHERE motivo_quarentena IS NOT NULL;

-- COMMAND ----------

-- DBTITLE 1,Resumo da camada Silver
SELECT
    'silver' AS camada,
    COUNT(*) AS quantidade_registros
FROM healthcare_silver.ans_beneficiarios
UNION ALL
SELECT
    'quarantine',
    COUNT(*)
FROM healthcare_quarantine.ans_beneficiarios_invalidos;


-- COMMAND ----------

-- DBTITLE 1,Análise da cardinalidade da chave técnica
SELECT
    COUNT(*) AS quantidade_registros,
    COUNT(DISTINCT codigo_operadora) AS operadoras,
    COUNT(DISTINCT municipio) AS municipios,
    COUNT(DISTINCT codigo_plano) AS planos,
    COUNT(DISTINCT chave_registro) AS chaves_tecnicas
FROM healthcare_silver.ans_beneficiarios;

-- COMMAND ----------

-- DBTITLE 1,Resumo da Quarentena
SELECT
    motivo_quarentena,
    COUNT(*) AS quantidade
FROM healthcare_quarantine.ans_beneficiarios_invalidos
GROUP BY motivo_quarentena
ORDER BY quantidade DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Resultado esperado
-- MAGIC
-- MAGIC Ao final da execução:
-- MAGIC
-- MAGIC - a tabela `healthcare_silver.ans_beneficiarios` deve conter registros
-- MAGIC   válidos, tipados e padronizados;
-- MAGIC
-- MAGIC - a tabela
-- MAGIC   `healthcare_quarantine.ans_beneficiarios_invalidos`
-- MAGIC   deve armazenar registros rejeitados juntamente com o motivo da rejeição;
-- MAGIC
-- MAGIC - todas as colunas devem possuir tipos apropriados para consumo analítico;
-- MAGIC
-- MAGIC - uma chave técnica (`chave_registro`) deve ser gerada a partir dos
-- MAGIC   principais atributos dimensionais para facilitar rastreabilidade e
-- MAGIC   integração entre camadas;
-- MAGIC
-- MAGIC - os indicadores apresentados ao final permitem validar a qualidade do
-- MAGIC   processamento e compreender a cardinalidade dos registros processados.
-- MAGIC
-- MAGIC ## Próximo notebook
-- MAGIC
-- MAGIC `03_gold_aggregation.sql`
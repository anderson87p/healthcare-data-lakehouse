# Arquitetura da Solução

## Visão Geral

Este projeto implementa um pipeline de Engenharia de Dados utilizando a arquitetura **Medallion** no Databricks, organizada em três camadas principais (**Bronze**, **Silver** e **Gold**) e uma camada auxiliar de **Quarantine** para tratamento de registros inválidos.

A separação por camadas permite isolar as responsabilidades de ingestão, tratamento, qualidade dos dados e consumo analítico, tornando o pipeline mais simples de manter e evoluir.

## Arquitetura do Pipeline

```text
                          Arquivo CSV ANS
                                 │
                                 ▼
                    Unity Catalog Volume (Landing)
                                 │
                                 ▼
                         Bronze (Delta Lake)
                  Dados brutos + metadados técnicos
                                 │
                                 ▼
                         Silver (Delta Lake)
              Tipagem • Limpeza • Qualidade • Deduplicação
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
        Silver Validada                 Quarantine
     Dados prontos para uso       Registros inválidos
                 │
                 ▼
                     Gold (Delta Lake)
      ┌────────────────┬─────────────────┬─────────────────┐
      ▼                ▼                 ▼
 Operadoras      Faixa Etária       Municípios
      └────────────────┴─────────────────┘
                       │
                       ▼
             Consultas Analíticas
                       │
                       ▼
              Validação do Pipeline
```

---

# Camadas

## Bronze

A camada Bronze preserva integralmente o conteúdo do arquivo de origem.

Nesta etapa são adicionados metadados técnicos que permitem rastrear o processo de ingestão:

- `_source_file`;
- `_ingestion_timestamp`;
- `_batch_id`.

Nenhuma regra de negócio é aplicada nesta camada.

---

## Silver

A camada Silver concentra as principais transformações do pipeline.

São realizadas as seguintes atividades:

- padronização dos nomes das colunas;
- conversão explícita dos tipos de dados;
- limpeza e normalização dos campos textuais;
- validação das regras de qualidade;
- deduplicação determinística;
- geração da chave técnica (`chave_registro`);
- separação dos registros inválidos para a Quarantine.

### Chave técnica

A coluna `chave_registro` é construída a partir dos principais atributos dimensionais do dataset.

Seu objetivo é facilitar rastreabilidade, auditoria e futuras integrações entre camadas.

Como o conjunto de dados da ANS pode conter múltiplos registros para uma mesma combinação dimensional, essa chave **não representa uma chave natural única**.

---

## Quarantine

A Quarantine armazena registros que não atendem às regras mínimas de qualidade.

Cada registro permanece disponível para auditoria juntamente com o motivo da rejeição, evitando perda de informação durante o processamento.

---

## Gold

A camada Gold materializa produtos analíticos preparados para consumo pelas consultas de negócio.

São produzidas três tabelas:

- `gold_operadora_beneficiarios`
- `gold_faixa_etaria_beneficiarios`
- `gold_municipio_beneficiarios`

Cada tabela possui um grão específico e evita recálculos sobre a Silver.

---

# Fluxo de Execução

Os notebooks devem ser executados na seguinte ordem:

```text
00_setup_environment

↓

01_bronze_ingestion

↓

02_silver_transformations

↓

03_gold_aggregations

↓

04_analytical_queries

↓

05_validation_queries
```

---

# Granularidade da Origem

Cada linha do arquivo representa uma combinação de atributos da ANS, incluindo:

- competência;
- operadora;
- município;
- faixa etária;
- sexo;
- plano;
- tipo de contratação;
- segmentação;
- abrangência;
- vínculo.

Cada registro possui ainda as métricas de:

- beneficiários ativos;
- beneficiários aderidos;
- beneficiários cancelados.

---

# Decisões de Performance

Para esta primeira versão do projeto foram adotadas as seguintes decisões:

- utilização do Delta Lake como formato persistente;
- materialização das agregações da camada Gold;
- separação dos registros inválidos em Quarantine;
- ausência de particionamento físico devido ao baixo volume da carga inicial;
- possibilidade de evolução futura para particionamento ou clustering por `competencia` em cenários com múltiplas competências.

---

# Evoluções Futuras

As principais evoluções previstas são:

- ingestão incremental por competência;
- processamento utilizando `MERGE`;
- automação com Databricks Workflows;
- testes automatizados;
- monitoramento da Quarantine;
- observabilidade do pipeline;
- integração com processos de CI/CD.
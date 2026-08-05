# Healthcare Data Lakehouse

Pipeline de dados desenvolvido em **Databricks SQL** utilizando a arquitetura **Medallion** (Bronze, Silver e Gold), **Delta Lake** e **Unity Catalog** para processamento e análise de dados públicos da Agência Nacional de Saúde Suplementar (ANS).

O projeto demonstra um pipeline completo de Engenharia de Dados, incluindo ingestão, tratamento, validação da qualidade dos dados, agregações analíticas e validações finais do processamento.

## Objetivo

A solução realiza a ingestão de um arquivo público da Agência Nacional de Saúde Suplementar (ANS), organiza os dados nas camadas Bronze, Silver e Gold e disponibiliza produtos analíticos capazes de responder às seguintes perguntas de negócio:

1. Quais são as cinco operadoras com maior número de beneficiários ativos?
2. Qual é a faixa etária com maior quantidade de beneficiários?
3. Qual é a quantidade de beneficiários por município em ordem decrescente?

## Observação sobre a fonte

O enunciado menciona dados do estado de São Paulo, porém o arquivo disponibilizado corresponde ao estado do Tocantins (`SG_UF = 'TO'`). A implementação utiliza exatamente o arquivo oficial fornecido:

```text
pda-024-icb-TO-2025_08.csv
```

## Arquitetura

```mermaid
flowchart LR
    A[Arquivo CSV ANS]
        --> B[Unity Catalog Volume]

    B --> C[Bronze Delta<br/>dados brutos]

    C --> D[Silver Delta<br/>limpeza, tipagem e qualidade]

    D --> Q[Quarantine<br/>registros inválidos]

    D --> E1[Gold Operadoras]
    D --> E2[Gold Faixas Etárias]
    D --> E3[Gold Municípios]

    E1 --> F[Consultas Analíticas]
    E2 --> F
    E3 --> F

    F --> G[Validação do Pipeline]
```

Mais detalhes em [`docs/architecture.md`](docs/architecture.md).

## Tecnologias

- Databricks Free Edition;
- Databricks SQL;
- Delta Lake;
- Unity Catalog;
- SQL;
- Git e GitHub.
- GitHub
- Mermaid

## Estrutura do projeto

```text
healthcare-data-lakehouse/
├── notebooks/
│   ├── 00_setup_environment.sql
│   ├── 01_bronze_ingestion.sql
│   ├── 02_silver_transformations.sql
│   ├── 03_gold_aggregations.sql
│   ├── 04_analytical_queries.sql
│   └── 05_validation_queries.sql
├── docs/
│   ├── architecture.md
│   ├── decisions.md
│   └── images/
├── evidence/
├── README.md
```

## Camadas

### Bronze

A camada Bronze preserva integralmente o conteúdo original do arquivo CSV, adicionando metadados técnicos para rastreabilidade do processo de ingestão.

Metadados adicionados:

- `_source_file`;
- `_ingestion_timestamp`;
- `_batch_id`.

### Silver

A camada Silver aplica as principais regras de qualidade e padronização dos dados.

Transformações realizadas:

- renomeação das colunas para `snake_case`;
- tipagem explícita das colunas;
- limpeza e normalização dos dados;
- validação de regras de qualidade;
- deduplicação determinística;
- geração da chave técnica (`chave_registro`) para rastreabilidade;
- separação de registros inválidos para a Quarantine.

### Gold

A camada Gold materializa produtos analíticos preparados para consumo pelas consultas do desafio.

São produzidas três tabelas:

- `gold_operadora_beneficiarios`;
- `gold_faixa_etaria_beneficiarios`;
- `gold_municipio_beneficiarios`.

## Resultados

Ao final da execução do pipeline são produzidos:

- Bronze persistida em Delta Lake;
- Silver validada;
- Quarantine para registros inválidos;
- três tabelas Gold;
- consultas analíticas;
- notebook de validação do pipeline.

## Como executar no Databricks

1. Importe a pasta `notebooks/` para o Workspace.
2. Execute `00_setup_environment.sql`.
3. Envie o CSV para o Volume exibido pelo notebook:
   ```text
   /Volumes/<catalogo_atual>/healthcare_landing/source/
   ```
4. Execute os notebooks de `01` a `05` na ordem.
5. Salve evidências das tabelas e consultas na pasta `evidence/`.

## Ordem de execução

| Ordem | Notebook | Responsabilidade |
|---:|---|---|
| 00 | `00_setup_environment.sql` | Criação dos schemas e Volume |
| 01 | `01_bronze_ingestion.sql` | Ingestão do CSV como tabela Delta Bronze |
| 02 | `02_silver_transformations.sql` | Limpeza, tipagem, deduplicação e qualidade |
| 03 | `03_gold_aggregations.sql` | Criação das agregações Gold |
| 04 | `04_analytical_queries.sql` | Respostas às três perguntas do desafio |
| 05 | `05_validation_queries.sql` | Validações de volumetria e qualidade |

## Decisões de performance

- Delta Lake como formato persistente;
- Gold pré-agregada para evitar repetição de cálculos;
- `OPTIMIZE` opcional, condicionado ao suporte do ambiente e ao volume;
- não foi aplicado particionamento físico ao arquivo mensal inicial, pois o volume é pequeno;
- em cenário histórico, as tabelas seriam avaliadas para particionamento ou clustering por `competencia`.
- utilização da Quarantine para preservar registros inválidos sem interromper o processamento;

## Limitações e evolução

Esta primeira versão atende ao escopo do desafio. Evoluções futuras possíveis:

- ingestão mensal incremental;
- `MERGE` por competência e chave técnica;
- testes automatizados;
- Databricks Workflows;
- CI/CD;
- observabilidade e alertas;
- histórico de múltiplas competências;
- catálogo e políticas de acesso mais granulares;
- carga full para uma única competência;
- monitoramento da Quarantine;

## Autor

**Anderson de Alencar Pereira**  
Senior Data Engineer | Analytics Engineering | Business Intelligence

# Decisões Arquiteturais

## Objetivo

Este documento descreve as principais decisões técnicas adotadas durante o desenvolvimento do pipeline, bem como os trade-offs considerados para atender aos requisitos do desafio.

---

# Arquitetura Medallion

## Decisão

Adotar a arquitetura Medallion dividida nas camadas Bronze, Silver e Gold.

## Justificativa

Essa abordagem separa claramente as responsabilidades de ingestão, tratamento e consumo analítico, facilitando manutenção, rastreabilidade e futuras evoluções do pipeline.

### Benefícios

- separação de responsabilidades;
- maior organização do pipeline;
- facilidade de manutenção;
- evolução independente de cada camada.

---

# Databricks SQL

## Decisão

Implementar todo o pipeline utilizando Databricks SQL.

## Justificativa

O desafio foi direcionado para utilização da plataforma Databricks e não exigia processamento distribuído complexo.

Para o volume disponibilizado, SQL apresentou uma solução simples, legível e totalmente aderente ao escopo.

### Trade-off

Em cenários com regras de negócio muito complexas ou processamento em larga escala, PySpark poderia oferecer maior flexibilidade.

---

# Delta Lake

## Decisão

Persistir todas as tabelas utilizando Delta Lake.

## Justificativa

Delta Lake oferece:

- transações ACID;
- integração nativa com Databricks;
- melhor gerenciamento dos dados;
- possibilidade de evolução futura para cargas incrementais utilizando MERGE.

---

# Camada Bronze

## Decisão

Preservar integralmente o arquivo original.

## Justificativa

A Bronze representa a fonte oficial do pipeline.

Nenhuma transformação de negócio é realizada nesta camada, permitindo:

- auditoria;
- reprocessamento;
- rastreabilidade.

Também são adicionados metadados técnicos para identificar arquivo, lote e momento da ingestão.

---

# Camada Silver

## Decisão

Centralizar todas as regras de qualidade nesta camada.

## Justificativa

Nesta etapa são executadas:

- tipagem;
- padronização;
- limpeza;
- validações;
- deduplicação;
- geração da chave técnica.

Essa separação evita que consumidores precisem implementar novamente regras de tratamento.

---

# Chave Técnica

## Decisão

Gerar uma chave técnica (`chave_registro`) baseada nos principais atributos dimensionais.

## Justificativa

A chave técnica foi criada para facilitar:

- rastreabilidade;
- auditoria;
- futuras integrações;
- possíveis cargas incrementais.

## Observação

Durante as validações foi identificado que a origem possui múltiplas ocorrências para a mesma combinação dimensional.

Por esse motivo, a chave técnica não representa uma chave natural única e não foi utilizada como restrição de unicidade.

---

# Quarantine

## Decisão

Separar registros inválidos em uma camada específica.

## Justificativa

Ao invés de interromper o processamento, os registros inválidos permanecem disponíveis para auditoria juntamente com o motivo da rejeição.

### Benefícios

- preservação das informações;
- rastreabilidade;
- facilidade de investigação;
- melhoria da qualidade dos dados.

---

# Camada Gold

## Decisão

Materializar as agregações analíticas.

## Justificativa

As perguntas do desafio são respondidas diretamente pelas tabelas Gold.

Essa abordagem reduz recálculos sobre a Silver e simplifica consultas analíticas.

Foram criadas três tabelas:

- beneficiários por operadora;
- beneficiários por faixa etária;
- beneficiários por município.

---

# Particionamento

## Decisão

Não utilizar particionamento físico nesta primeira versão.

## Justificativa

O conjunto de dados contém apenas uma competência e possui volume reduzido.

A utilização de particionamento adicionaria complexidade sem ganho significativo de desempenho.

## Evolução

Em cenários com múltiplas competências será avaliado:

- particionamento por competência;
- clustering;
- otimizações adicionais do Delta Lake.

---

# Estratégia de Carga

## Decisão

Implementar carga completa (Full Load).

## Justificativa

O desafio disponibiliza apenas um arquivo referente a uma competência.

Essa estratégia simplifica a implementação e atende integralmente ao escopo.

## Evolução

Uma versão futura poderá utilizar MERGE incremental por competência e chave técnica.

---

# Validação do Pipeline

## Decisão

Criar um notebook exclusivo para validação.

## Justificativa

O notebook `05_validation_queries.sql` executa verificações de:

- volumetria;
- reconciliação Silver × Gold;
- valores negativos;
- competência;
- UF;
- status geral do pipeline.

Essa etapa fornece uma evidência objetiva de que o processamento foi executado corretamente.

---

# Trade-offs

Durante o desenvolvimento foram considerados os seguintes trade-offs:

| Decisão | Benefício | Trade-off |
|----------|-----------|-----------|
| Databricks SQL | Simplicidade e legibilidade | Menor flexibilidade que PySpark |
| Full Load | Implementação simples | Não suporta incremental |
| Sem particionamento | Menor complexidade | Pode exigir revisão em grandes volumes |
| Gold materializada | Consultas rápidas | Consome armazenamento adicional |
| Quarantine | Preserva registros inválidos | Exige gerenciamento adicional |

---

# Evoluções Futuras

As principais evoluções previstas para o projeto são:

- ingestão incremental;
- MERGE utilizando Delta Lake;
- Databricks Workflows;
- CI/CD;
- testes automatizados;
- monitoramento da Quarantine;
- observabilidade do pipeline;
- múltiplas competências;
- catálogo de dados e governança.
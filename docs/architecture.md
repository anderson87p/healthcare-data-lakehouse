# Arquitetura da Solução

## Visão geral

O pipeline utiliza arquitetura Medallion para separar dados brutos, dados tratados e dados preparados para consumo analítico.

```text
Arquivo CSV ANS
      |
      v
Unity Catalog Volume
      |
      v
Bronze Delta
      |
      v
Silver Delta
      |
      +-------------------+------------------+
      v                   v                  v
Gold Operadoras     Gold Faixas       Gold Municípios
      \                   |                  /
       \__________________|_________________/
                          |
                          v
                Consultas Analíticas
```

## Bronze

A Bronze preserva o layout original do arquivo, mantendo todas as colunas como texto. Metadados técnicos permitem rastrear arquivo, lote e instante de ingestão.

## Silver

A Silver converte o dataset para um modelo tabular confiável:

- tipos apropriados;
- nomes de colunas padronizados;
- métricas não negativas;
- textos normalizados;
- registros duplicados removidos;
- registros inválidos segregados.

## Gold

A Gold oferece tabelas agregadas alinhadas às perguntas de negócio:

- uma linha por operadora e competência;
- uma linha por faixa etária e competência;
- uma linha por município e competência.

## Granularidade da origem

Cada linha da origem representa uma combinação de competência, operadora, município, sexo, faixa etária, plano, contratação, segmentação, abrangência e vínculo, acompanhada das quantidades de beneficiários ativos, aderidos e cancelados.

## Performance

Como a primeira entrega utiliza uma única competência e volume moderado, não há necessidade de particionamento físico. Para múltiplas competências, seria avaliado o uso de clustering ou particionamento por `competencia`, conforme perfil das consultas e volume real.

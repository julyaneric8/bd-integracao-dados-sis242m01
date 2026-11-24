# Parte 4 – Validação com o cliente (fevereiro de 2025)

As consultas citadas estão em `sql/04_validacao.sql` (conferência: A1 a A3; erros: E01 a E19).

## 1. Pontos que eu validaria com o cliente

### 1.1 Números de fevereiro/2025 para o cliente confirmar

Consulta A2 (com a base importada):

| Tabela | Linhas | Quantidade | Valor (R$) |
| --- | --- | --- | --- |
| `venda` (por `data_emissao`) | 14 | 173,22 | 14.093,17 |
| `pedido_compra` (por `data_pedido`) | 17 | 619 | 28.396,93 |
| `entradas_mercadoria` (por `data_entrada`) | 10 | 468 | 36.722,92 |

Vendas por filial (A3): filial 1 com 13 linhas (R$ 13.545,64) e filial 2 com 1 linha (R$ 547,53).

Perguntar: esses totais batem com o relatório do sistema de origem? O período de cada tabela deve mesmo ser medido pela sua própria data (emissão, pedido, entrada)?

### 1.2 Cadastro

- Os produtos P21 a P28 foram vendidos, mas não estão em `produtos_filial`. Devem ser cadastrados? São produtos de outra carga?
- As filiais 2 e 3 existem? Só a filial 1 tem produtos cadastrados.
- Os fornecedores F14, F15 e F16 não têm nenhum produto. Estão inativos?

### 1.3 Fornecedor

- O `fornecedor_id` do pedido (1 a 20) corresponde ao `idfornecedor` (`F1` a `F20`)? Qual é a chave oficial?
- Mesmo supondo que sim, o fornecedor do pedido difere do fornecedor do cadastro do produto em 22 dos 29 pedidos. Qual vale?

### 1.4 Pedidos de compra

- Os pedidos 19 a 29 têm `ordem_compra = 0`. Qual é o número correto? (Os pedidos 1 a 18 têm `ordem_compra` igual ao `pedido_id`.)
- 20 dos 29 pedidos têm data de entrega anterior à data do pedido. A coluna `data_entrega` é a prevista ou a realizada?
- Há 9 pares de linhas repetidas (P12 a P20, pedidos 12 a 20 e 21 a 29). São duplicidade ou pedidos distintos?

### 1.5 Recebimento

- As entradas das ordens 19 e 20 não encontram pedido (consequência de `ordem_compra = 0`).
- 7 de 18 entradas receberam mais do que foi pedido. É recebimento a mais, devolução ou erro de digitação?
- `qtde_recebida` difere de `qtde_entregue` do pedido em todas as 18 entradas ligadas. Qual das duas é a quantidade oficial?
- 9 entradas são anteriores à data do pedido.
- O custo da entrada difere do preço do pedido nas 18 entradas.

### 1.6 Vendas e preços

- 5 vendas em unidade `UN` têm quantidade fracionada (por exemplo, 38,6). A unidade está errada ou a quantidade está?
- Todas as vendas registram o horário `08:00:00`. É valor padrão?
- 8 pares de produtos diferentes têm exatamente o mesmo valor unitário (P13 e P21, P14 e P22, ...). Confirmar.
- O valor vendido difere do `preco_venda` cadastrado em todas as 20 vendas que têm cadastro. O cadastro está desatualizado ou houve desconto?
- 4 produtos (P1, P8, P15 e P18) têm custo maior que o preço de venda.
- O `preco_compra` do cadastro difere do `preco_compra` dos pedidos em todos os 20 produtos, e ainda há um terceiro valor, o custo da entrada. Qual é o custo oficial?
- O que significa `preco_unitario` em `produtos_filial`, já que existem também `preco_compra` e `preco_venda`?

### 1.7 Definições de negócio

- O que conta como "requisitado" e como "recebido"? Foi usada a ligação `ordem_compra` mais `produto_id`.
- Existem devoluções, cancelamentos ou vendas estornadas que deveriam aparecer?

## 2. Técnicas para garantir a exatidão dos dados

1. **Reconciliação de contagens:** comparar as linhas da planilha com as do banco, tabela a tabela (consulta A1 e saída do `importar.py`). As linhas rejeitadas ou duplicadas ficam registradas em `rejeitados_<tabela>.csv`.
2. **Totais de controle:** comparar somas de quantidade e de valor (A2 e A3) com um relatório do sistema de origem, fornecido pelo cliente.
3. **Integridade referencial:** procurar registros órfãos (venda sem produto, entrada sem pedido, produto sem fornecedor): E01, E02, E12.
4. **Duplicidade:** agrupar pela chave de negócio e procurar `COUNT(*) > 1`: E09.
5. **Consistência entre tabelas:** cruzar pedido, entrada e cadastro (quantidades, datas, custos e fornecedores): E06, E11, E13 a E18.
6. **Regras de domínio:** datas fora de ordem, quantidade fracionada em unidade inteira, valor padrão suspeito, código placeholder como `ordem_compra = 0`: E03, E05, E07, E08, E15.
7. **Perfil dos dados:** contar nulos, valores distintos, mínimos e máximos por coluna antes de carregar.
8. **Amostragem manual:** conferir um conjunto de linhas com os documentos originais (nota fiscal, pedido).
9. **Importação rastreável:** nenhuma linha é descartada em silêncio, nenhum vazio é trocado por valor inventado e as consultas de validação ficam versionadas no repositório, para repetir o teste a cada nova carga.

## 3. Consultas prontas (`sql/04_validacao.sql`)

| Consulta | Finalidade |
| --- | --- |
| A1 | Linhas por tabela (comparar com a planilha: 33, 29, 20, 20 e 20) |
| A2 | Resumo de fevereiro/2025 por tabela |
| A3 | Vendas de fevereiro por filial |
| E01 a E19 | Uma consulta para cada erro da seção 4 |

## 4. Erros encontrados nos dados

| Nº | Tabela | Erro | Ocorrências | Consulta |
| --- | --- | --- | --- | --- |
| E01 | `venda` | Produto vendido sem cadastro em `produtos_filial` (P21 a P28; vendas 21 a 33) | 13 linhas | E01 |
| E02 | `venda` | Filiais que não existem em `produtos_filial` | filiais 2 e 3 | E02 |
| E03 | `venda` | Quantidade fracionada em unidade `UN` (vendas 4, 8, 12, 16 e 26) | 5 linhas | E03 |
| E04 | `venda` | Mesmo valor unitário para produtos diferentes | 8 pares | E04 |
| E05 | `venda` | Horário único (`08:00:00`) em todas as vendas | 33 vendas | E05 |
| E06 | `venda` | Valor vendido diferente do `preco_venda` cadastrado | 20 linhas | E06 |
| E07 | `pedido_compra` | `ordem_compra = 0`, impedindo ligar o pedido à entrada (pedidos 19 a 29) | 11 linhas | E07 |
| E08 | `pedido_compra` | Data de entrega anterior à data do pedido | 20 linhas | E08 |
| E09 | `pedido_compra` | Linhas repetidas (mesmo produto, filial, datas e preço; P12 a P20) | 9 grupos | E09 |
| E10 | `pedido_compra` | `fornecedor_id` numérico (1 a 20) não casa com `fornecedor` (`F1` a `F20`) | 29 linhas | E10 |
| E11 | `pedido_compra` | Mesmo prefixando `F`, o fornecedor do pedido difere do cadastro do produto | 22 linhas | E11 |
| E12 | `entradas_mercadoria` | Entrada sem pedido correspondente (NFE19 e NFE20) | 2 linhas | E12 |
| E13 | `entradas_mercadoria` | Quantidade recebida maior que a pedida | 7 linhas | E13 |
| E14 | `entradas_mercadoria` | `qtde_recebida` diferente da `qtde_entregue` do pedido | 18 linhas | E14 |
| E15 | `entradas_mercadoria` | Data de entrada anterior à data do pedido | 9 linhas | E15 |
| E16 | `entradas_mercadoria` | `custo_unitario` diferente do `preco_compra` do pedido | 18 linhas | E16 |
| E17 | `produtos_filial` | `preco_compra` maior que `preco_venda` (P1, P8, P15 e P18) | 4 linhas | E17 |
| E18 | `produtos_filial` | `preco_compra` do cadastro diferente do `preco_compra` dos pedidos | 20 linhas | E18 |
| E19 | `fornecedor` | Fornecedores sem nenhum produto (F14, F15 e F16) | 3 linhas | E19 |

Não há chaves duplicadas nem células vazias nas cinco abas.

Impacto nas consultas da Parte 2 (`sql/02_consultas.sql`): por causa de E07, os pedidos 19 a 29 aparecem como "requisitados e não recebidos" mesmo que parte deles tenha chegado (as entradas das ordens 19 e 20 existem, E12).
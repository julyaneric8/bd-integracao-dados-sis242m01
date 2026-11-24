# Parte 1 – Implantação e importação

Banco: PostgreSQL 17. Planilha: `dados/base_teste.xlsx` (5 abas, sem alterações).

## 1. Erros do DDL do enunciado (`sql/01_ddl_enunciado.sql`)

Ao rodar o DDL original, só `venda` e `pedido_compra` são criadas. As outras três tabelas falham.

### Erros que impedem a criação da tabela

| # | Tabela | Erro | Correção |
| --- | --- | --- | --- |
| 1 | `entradas_mercadoria` | A PK usa `ordem_compra`, mas a coluna não existe na tabela. É justamente o campo que liga a entrada ao pedido. | Criada a coluna `ordem_compra bigint NOT NULL`. |
| 2 | `produtos_filial` | Falta a vírgula depois de `idfonecedor int4 NULL`, antes do `CONSTRAINT` (erro de sintaxe). | Vírgula adicionada. |
| 3 | `produtos_filial` | A PK usa `idproduto`, que não existe (a coluna se chama `produto_id`). | PK `(filial_id, produto_id)`. |
| 4 | `fornecedor` | A PK `(idforncedor, idproduto)` usa `idproduto`, que não pertence à tabela. | PK somente com `idfornecedor`. |

### Erros de digitação nos nomes

| Nome no DDL | Nome correto | Onde |
| --- | --- | --- |
| `decricao` | `descricao` | `produtos_filial` |
| `idfonecedor` | `idfornecedor` | `produtos_filial` |
| `idforncedor` | `idfornecedor` | `fornecedor` |
| `pk_consumo` | `pk_venda` | PK da tabela `venda` |

### Erros de modelagem

| # | Problema | Correção |
| --- | --- | --- |
| 5 | `pedido_id`, `item` e `ordem_compra` são `float8`, inclusive dentro de chave primária. | `bigint` / `integer`. |
| 6 | Valores em dinheiro como `float8` (`preco_compra`, `preco_unitario`, `preco_venda`) e quantidades como `float8`. | `numeric(12,4)` para preços e `numeric(14,3)` para quantidades. |
| 7 | Tipos inconsistentes entre tabelas: `produto_id` é `varchar(25)` em umas e `varchar(255)` em outra; `filial_id` é `int8` em `venda` e `int4` nas demais; o id do fornecedor é `varchar(25)` em `fornecedor` e `int4` em `produtos_filial`, mas a planilha traz texto (`F8`). | Padronizados: `produto_id varchar(25)`, `filial_id integer`, `idfornecedor varchar(25)`. |
| 8 | Nenhuma chave estrangeira. | FK `produtos_filial.idfornecedor` para `fornecedor`. |
| 9 | Defaults sem sentido: `produto_id DEFAULT ''` e `DEFAULT '0'`; `DEFAULT '0'` (texto) em coluna numérica. | Removidos. Um identificador não deve ter valor padrão. |
| 10 | Colunas obrigatórias aceitando NULL: `filial_id` em `produtos_filial` (faz parte da PK) e as quantidades. | `NOT NULL`. |
| 11 | `qtde_pendente` é redundante (`qtde_pedida - qtde_entregue`) e não existe na planilha. | Coluna calculada pelo próprio banco (`GENERATED ALWAYS AS ... STORED`). |
| 12 | `horariomov varchar(8)` guarda hora como texto e `unidade_medida varchar(3)` é estreita. | `time` e `varchar(10)`. |

Versões corrigidas: `sql/01_ddl_postgres.sql` (executada e validada) e `sql/01_ddl_mysql.sql` (adaptação da sintaxe, **não testada** em MySQL).

## 2. Erros do script do estagiário (`scripts/importar.py`)

| # | Erro | Efeito | Correção |
| --- | --- | --- | --- |
| 1 | `excel_para_data` só entende número serial do Excel. As datas da planilha são datas reais, então `int()` falha, o `except:` engole o erro e devolve `None`. | Testado: **0 de 33** datas de `venda` são lidas. Como `data_emissao` é `NOT NULL`, nenhuma venda entraria. | Conversor aceita serial, data real e texto. |
| 2 | `conn.rollback()` dentro do loop, com `commit` só no fim de cada tabela. | Um único erro desfaz todas as linhas já inseridas daquela tabela. | `autocommit`: cada linha é independente. |
| 3 | A mensagem "N registros inseridos" imprime `len(df)`. | Conta linhas lidas, não inseridas. O `ON CONFLICT DO NOTHING` descarta duplicadas sem avisar. | Conta inseridas, duplicadas e rejeitadas, e mostra o `COUNT(*)` real do banco. Rejeitadas vão para `rejeitados_<tabela>.csv`. |
| 4 | Valores inventados no lugar de vazio: `NaN` vira 0 (`ordem_compra`, quantidades, preços) e `filial_id` vira 1. | Esconde dado faltante e pode ligar entradas a pedidos errados. | Vazio vira `NULL`; o banco decide se aceita. |
| 5 | `str(NaN)` vira o texto `"nan"` e ids numéricos podem virar `12345.0`; `float()` em ids e itens. | Ids errados. | Leitura com `dtype=str` e conversores por tipo. |
| 6 | Senha `1234` escrita no código. | Proibido pelo enunciado. | Configuração por variáveis de ambiente (`PGPASSWORD`, `PGHOST`, ...). |
| 7 | Mensagem final "Importação concluída com sucesso!" sempre aparece. | Mesmo com erros. | Resumo por tabela com os números reais. |
| 8 | Comentário diz que a porta do MySQL é 3006 (é 3306); `except:` genérico. | Confusão e erros engolidos. | Porta corrigida; `except Exception`. |
| 9 | O script insere nas colunas `descricao`, `idfornecedor` e `ordem_compra`, que o DDL original não tinha (`decricao`, `idfonecedor` e nenhuma `ordem_compra`). | Script e DDL eram incompatíveis entre si. | DDL corrigido. |

Observações:
- O corte `iloc[:, :12]` em `pedido_compra` existe porque a aba tem 11 colunas vazias a mais. Não é erro, mas o script novo seleciona as colunas por nome.
- A planilha não tem `qtde_pendente`. O script antigo a calculava; agora o banco faz isso.

## 3. Conferência das linhas

Comando: `python scripts/importar.py`. Saída:

```
Importando fornecedor...
  lidas na planilha: 20 | inseridas: 20 | rejeitadas/duplicadas: 0 | COUNT(*) no banco: 20
Importando produtos_filial...
  lidas na planilha: 20 | inseridas: 20 | rejeitadas/duplicadas: 0 | COUNT(*) no banco: 20
Importando pedido_compra...
  lidas na planilha: 29 | inseridas: 29 | rejeitadas/duplicadas: 0 | COUNT(*) no banco: 29
Importando entradas_mercadoria...
  lidas na planilha: 20 | inseridas: 20 | rejeitadas/duplicadas: 0 | COUNT(*) no banco: 20
Importando venda...
  lidas na planilha: 33 | inseridas: 33 | rejeitadas/duplicadas: 0 | COUNT(*) no banco: 33
```

| Tabela | Linhas na planilha | Linhas no banco | Rejeitadas |
| --- | --- | --- | --- |
| `fornecedor` | 20 | 20 | 0 |
| `produtos_filial` | 20 | 20 | 0 |
| `pedido_compra` | 29 | 29 | 0 |
| `entradas_mercadoria` | 20 | 20 | 0 |
| `venda` | 33 | 33 | 0 |

A contagem também pode ser refeita direto no banco com a consulta A1 de `sql/04_validacao.sql`.

## 4. Como reproduzir

```
pip install pandas psycopg2-binary openpyxl
psql -U postgres -h localhost -d postgres -f sql/01_ddl_postgres.sql
set "PGPASSWORD=<senha>"
python scripts/importar.py
```

A senha não fica no código: o script a lê da variável de ambiente `PGPASSWORD`.

## 5. Decisões e suposições

- **`pedido_compra.fornecedor_id` ficou inteiro e sem chave estrangeira.** A planilha traz 1 a 20, enquanto `fornecedor` usa `F1` a `F20`. Converter seria uma suposição sobre o dado do cliente, então fica como pergunta para a reunião de validação (erros E10 e E11 da Parte 4).
- **Pedidos com `ordem_compra = 0` foram importados como vieram.** O dado é do cliente. O problema é apontado na Parte 4 (E07).
- **`ordem_compra` não é única em `pedido_compra`**, por isso a ligação com `entradas_mercadoria` não tem FK. Foram criados índices para acelerar o join.
- A planilha original não foi alterada.
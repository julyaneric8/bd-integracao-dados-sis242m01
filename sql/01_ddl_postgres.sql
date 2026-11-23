-- DDL corrigido (PostgreSQL)
-- Ordem de criacao: fornecedor -> produtos_filial -> venda -> pedido_compra -> entradas_mercadoria
-- Ajuste os tipos se a planilha mostrar algo diferente (ex.: unidade_medida maior, id de fornecedor texto).

DROP TABLE IF EXISTS entradas_mercadoria, pedido_compra, venda, produtos_filial, fornecedor CASCADE;

-- Corrigido: PK so com o id (antes incluia idproduto, que nao existe); typo idforncedor -> idfornecedor
CREATE TABLE fornecedor (
    idfornecedor  varchar(25)  NOT NULL,   -- na planilha e texto: 'F1', 'F2'...
    razao_social  varchar(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

-- Corrigido: virgula faltando, PK com idproduto -> produto_id, typos decricao/idfonecedor,
-- precos float8 -> numeric, filial_id NOT NULL, produto_id varchar(25), FK para fornecedor
CREATE TABLE produtos_filial (
    filial_id       integer       NOT NULL,
    produto_id      varchar(25)   NOT NULL,
    descricao       varchar(255)  NOT NULL,
    estoque         numeric(14,3) NOT NULL DEFAULT 0,
    preco_unitario  numeric(12,4) NOT NULL DEFAULT 0,
    preco_compra    numeric(12,4) NOT NULL DEFAULT 0,
    preco_venda     numeric(12,4) NOT NULL DEFAULT 0,
    idfornecedor    varchar(25),           -- na planilha e texto: 'F8'; no DDL original era int4
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor)
);

-- Corrigido: nome da PK (pk_consumo -> pk_venda), filial_id int4, qtde float8 -> numeric NOT NULL,
-- horariomov varchar -> time, sem default '' em produto_id, unidade_medida maior
CREATE TABLE venda (
    venda_id        bigint        NOT NULL,
    data_emissao    date          NOT NULL,
    horariomov      time          NOT NULL DEFAULT '00:00:00',
    produto_id      varchar(25)   NOT NULL,
    qtde_vendida    numeric(14,3) NOT NULL,
    valor_unitario  numeric(12,4) NOT NULL DEFAULT 0,
    filial_id       integer       NOT NULL DEFAULT 1,
    item            integer       NOT NULL DEFAULT 0,
    unidade_medida  varchar(10),
    CONSTRAINT pk_venda PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);
-- Obs.: FK venda -> produtos_filial pode ser adicionada depois de limpar os dados.

-- Corrigido: ids/itens float8 -> bigint/integer, valores float8 -> numeric
CREATE TABLE pedido_compra (
    pedido_id          bigint        NOT NULL,
    data_pedido        date,
    item               integer       NOT NULL,
    produto_id         varchar(25)   NOT NULL,
    descricao_produto  varchar(255),
    ordem_compra       bigint        NOT NULL,
    qtde_pedida        numeric(14,3) NOT NULL,
    filial_id          integer       NOT NULL,
    data_entrega       date,
    qtde_entregue      numeric(14,3) NOT NULL DEFAULT 0,
    -- qtde_pendente nao existe na planilha: vira coluna calculada pelo proprio banco
    qtde_pendente      numeric(14,3) GENERATED ALWAYS AS (qtde_pedida - qtde_entregue) STORED,
    preco_compra       numeric(12,4) NOT NULL DEFAULT 0,
    fornecedor_id      integer,   -- planilha traz 1..20, mas fornecedor usa 'F1'..'F20': sem FK ate validar com o cliente
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item)
);
-- ordem_compra nao e unica, entao nao serve de FK; o indice acelera o join com entradas_mercadoria.
CREATE INDEX idx_pedido_ordem_compra ON pedido_compra (ordem_compra);

-- Corrigido: coluna ordem_compra criada (a PK usava uma coluna inexistente), item float8 -> integer,
-- qtde NOT NULL
CREATE TABLE entradas_mercadoria (
    ordem_compra       bigint        NOT NULL,
    data_entrada       date,
    nro_nfe            varchar(255)  NOT NULL,
    item               integer       NOT NULL,
    produto_id         varchar(25)   NOT NULL,
    descricao_produto  varchar(255),
    qtde_recebida      numeric(14,3) NOT NULL,
    filial_id          integer       NOT NULL,
    custo_unitario     numeric(12,4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);
CREATE INDEX idx_entradas_ordem_compra ON entradas_mercadoria (ordem_compra);

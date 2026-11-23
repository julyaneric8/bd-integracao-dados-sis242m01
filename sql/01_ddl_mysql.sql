-- DDL corrigido (MySQL)
-- Mesmas correcoes do DDL PostgreSQL, adaptado a sintaxe do MySQL.
-- Ordem de criacao: fornecedor -> produtos_filial -> venda -> pedido_compra -> entradas_mercadoria

DROP TABLE IF EXISTS entradas_mercadoria;
DROP TABLE IF EXISTS pedido_compra;
DROP TABLE IF EXISTS venda;
DROP TABLE IF EXISTS produtos_filial;
DROP TABLE IF EXISTS fornecedor;

-- Corrigido: PK so com o id (antes incluia idproduto, que nao existe); typo idforncedor -> idfornecedor
CREATE TABLE fornecedor (
    idfornecedor  VARCHAR(25)  NOT NULL,   -- na planilha e texto: 'F1', 'F2'...
    razao_social  VARCHAR(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

-- Corrigido: virgula faltando, PK com idproduto -> produto_id, typos decricao/idfonecedor,
-- precos float -> decimal, filial_id NOT NULL, produto_id varchar(25), FK para fornecedor
CREATE TABLE produtos_filial (
    filial_id       INT           NOT NULL,
    produto_id      VARCHAR(25)   NOT NULL,
    descricao       VARCHAR(255)  NOT NULL,
    estoque         DECIMAL(14,3) NOT NULL DEFAULT 0,
    preco_unitario  DECIMAL(12,4) NOT NULL DEFAULT 0,
    preco_compra    DECIMAL(12,4) NOT NULL DEFAULT 0,
    preco_venda     DECIMAL(12,4) NOT NULL DEFAULT 0,
    idfornecedor    VARCHAR(25),           -- na planilha e texto: 'F8'; no DDL original era int
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor)
);

-- Corrigido: nome da PK (pk_consumo -> pk_venda), qtde float -> decimal NOT NULL,
-- horariomov varchar -> time, sem default '' em produto_id, unidade_medida maior
CREATE TABLE venda (
    venda_id        BIGINT        NOT NULL,
    data_emissao    DATE          NOT NULL,
    horariomov      TIME          NOT NULL DEFAULT '00:00:00',
    produto_id      VARCHAR(25)   NOT NULL,
    qtde_vendida    DECIMAL(14,3) NOT NULL,
    valor_unitario  DECIMAL(12,4) NOT NULL DEFAULT 0,
    filial_id       INT           NOT NULL DEFAULT 1,
    item            INT           NOT NULL DEFAULT 0,
    unidade_medida  VARCHAR(10),
    CONSTRAINT pk_venda PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

-- Corrigido: ids/itens float -> bigint/int, valores float -> decimal
CREATE TABLE pedido_compra (
    pedido_id          BIGINT        NOT NULL,
    data_pedido        DATE,
    item               INT           NOT NULL,
    produto_id         VARCHAR(25)   NOT NULL,
    descricao_produto  VARCHAR(255),
    ordem_compra       BIGINT        NOT NULL,
    qtde_pedida        DECIMAL(14,3) NOT NULL,
    filial_id          INT           NOT NULL,
    data_entrega       DATE,
    qtde_entregue      DECIMAL(14,3) NOT NULL DEFAULT 0,
    -- qtde_pendente nao existe na planilha: coluna calculada pelo proprio banco
    qtde_pendente      DECIMAL(14,3) GENERATED ALWAYS AS (qtde_pedida - qtde_entregue) STORED,
    preco_compra       DECIMAL(12,4) NOT NULL DEFAULT 0,
    fornecedor_id      INT,   -- planilha traz 1..20, mas fornecedor usa 'F1'..'F20': sem FK ate validar com o cliente
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item),
    INDEX idx_pedido_ordem_compra (ordem_compra)  -- ordem_compra nao e unica: serve so para acelerar o join
);

-- Corrigido: coluna ordem_compra criada (a PK usava uma coluna inexistente), item float -> int,
-- qtde NOT NULL
CREATE TABLE entradas_mercadoria (
    ordem_compra       BIGINT        NOT NULL,
    data_entrada       DATE,
    nro_nfe            VARCHAR(100)  NOT NULL,
    item               INT           NOT NULL,
    produto_id         VARCHAR(25)   NOT NULL,
    descricao_produto  VARCHAR(255),
    qtde_recebida      DECIMAL(14,3) NOT NULL,
    filial_id          INT           NOT NULL,
    custo_unitario     DECIMAL(12,4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe),
    INDEX idx_entradas_ordem_compra (ordem_compra)
);
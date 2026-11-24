-- 04_validacao
-- Nome: Julyan Eric Lopes Pinto
-- Consultas para a validacao dos dados de fevereiro de 2025.
-- A: conferencia com o cliente. E01-E19: erros encontrados nos dados (resultado esperado entre parenteses).

-- A1. Linhas por tabela (comparar com a planilha)
SELECT 'venda' AS tabela, COUNT(*) AS linhas FROM venda
UNION ALL SELECT 'pedido_compra', COUNT(*) FROM pedido_compra
UNION ALL SELECT 'entradas_mercadoria', COUNT(*) FROM entradas_mercadoria
UNION ALL SELECT 'produtos_filial', COUNT(*) FROM produtos_filial
UNION ALL SELECT 'fornecedor', COUNT(*) FROM fornecedor;

-- A2. Resumo de fevereiro de 2025 por tabela (linhas, quantidade e valor)
SELECT 'venda' AS tabela, COUNT(*) AS linhas, SUM(qtde_vendida) AS quantidade,
       SUM(qtde_vendida * valor_unitario) AS valor
FROM venda
WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01'
UNION ALL
SELECT 'pedido_compra', COUNT(*), SUM(qtde_pedida), SUM(qtde_pedida * preco_compra)
FROM pedido_compra
WHERE data_pedido >= '2025-02-01' AND data_pedido < '2025-03-01'
UNION ALL
SELECT 'entradas_mercadoria', COUNT(*), SUM(qtde_recebida), SUM(qtde_recebida * custo_unitario)
FROM entradas_mercadoria
WHERE data_entrada >= '2025-02-01' AND data_entrada < '2025-03-01';

-- A3. Vendas de fevereiro por filial
SELECT filial_id, COUNT(*) AS linhas, SUM(qtde_vendida * valor_unitario) AS valor
FROM venda
WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01'
GROUP BY filial_id
ORDER BY filial_id;

-- E01. venda: produto vendido sem cadastro em produtos_filial (P21 a P28) (13 linhas)
SELECT v.venda_id, v.data_emissao, v.produto_id, v.filial_id
FROM venda v
LEFT JOIN produtos_filial pf ON pf.filial_id = v.filial_id AND pf.produto_id = v.produto_id
WHERE pf.produto_id IS NULL
ORDER BY v.venda_id;

-- E02. venda: filiais que nao existem em produtos_filial (filiais 2 e 3)
SELECT DISTINCT filial_id
FROM venda
WHERE filial_id NOT IN (SELECT filial_id FROM produtos_filial)
ORDER BY filial_id;

-- E03. venda: quantidade fracionada em unidade UN (5 linhas)
SELECT venda_id, produto_id, qtde_vendida, unidade_medida
FROM venda
WHERE unidade_medida = 'UN' AND qtde_vendida <> FLOOR(qtde_vendida)
ORDER BY venda_id;

-- E04. venda: mesmo valor_unitario para produtos diferentes (P13/P21, P14/P22 ...) (8 pares)
SELECT DISTINCT a.produto_id AS produto_a, b.produto_id AS produto_b, a.valor_unitario
FROM venda a
JOIN venda b ON a.valor_unitario = b.valor_unitario AND a.produto_id < b.produto_id
ORDER BY a.valor_unitario;

-- E05. venda: horario unico em todas as vendas (parece valor padrao) (1 linha: 08:00:00)
SELECT horariomov, COUNT(*) AS vendas
FROM venda
GROUP BY horariomov;

-- E06. venda: valor vendido diferente do preco_venda cadastrado (20 linhas)
SELECT v.venda_id, v.produto_id, v.valor_unitario AS vendido, pf.preco_venda AS cadastrado
FROM venda v
JOIN produtos_filial pf ON pf.filial_id = v.filial_id AND pf.produto_id = v.produto_id
WHERE v.valor_unitario <> pf.preco_venda
ORDER BY v.venda_id;

-- E07. pedido_compra: ordem_compra = 0 (impede ligar o pedido a entrada) (11 linhas)
SELECT pedido_id, produto_id, ordem_compra
FROM pedido_compra
WHERE ordem_compra = 0
ORDER BY pedido_id;

-- E08. pedido_compra: data de entrega anterior a data do pedido (20 linhas)
SELECT pedido_id, produto_id, data_pedido, data_entrega
FROM pedido_compra
WHERE data_entrega < data_pedido
ORDER BY pedido_id;

-- E09. pedido_compra: linhas repetidas (mesmo produto, filial, datas e preco) (9 grupos)
SELECT produto_id, filial_id, data_pedido, data_entrega, preco_compra, COUNT(*) AS ocorrencias
FROM pedido_compra
GROUP BY produto_id, filial_id, data_pedido, data_entrega, preco_compra
HAVING COUNT(*) > 1
ORDER BY produto_id;

-- E10. pedido_compra: fornecedor_id e numero (1..20) e fornecedor usa 'F1'..'F20' (29 linhas)
SELECT p.pedido_id, p.fornecedor_id
FROM pedido_compra p
LEFT JOIN fornecedor f ON f.idfornecedor = CAST(p.fornecedor_id AS VARCHAR(25))
WHERE f.idfornecedor IS NULL
ORDER BY p.pedido_id;

-- E11. pedido_compra: mesmo apos prefixar 'F', o fornecedor do pedido difere do cadastro do produto (22 linhas)
SELECT p.pedido_id, p.produto_id, p.fornecedor_id AS fornecedor_no_pedido,
       pf.idfornecedor AS fornecedor_no_cadastro
FROM pedido_compra p
JOIN produtos_filial pf ON pf.filial_id = p.filial_id AND pf.produto_id = p.produto_id
WHERE ('F' || p.fornecedor_id) <> pf.idfornecedor
ORDER BY p.pedido_id;

-- E12. entradas_mercadoria: entrada sem pedido correspondente (ordem_compra + produto) (2 linhas)
SELECT e.nro_nfe, e.ordem_compra, e.produto_id
FROM entradas_mercadoria e
WHERE NOT EXISTS (
    SELECT 1 FROM pedido_compra p
    WHERE p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
)
ORDER BY e.nro_nfe;

-- E13. entradas_mercadoria: quantidade recebida maior que a pedida (7 linhas)
SELECT e.nro_nfe, e.produto_id, p.qtde_pedida, e.qtde_recebida
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.qtde_recebida > p.qtde_pedida
ORDER BY e.nro_nfe;

-- E14. entradas_mercadoria: qtde_recebida diferente da qtde_entregue do pedido (18 linhas)
SELECT e.nro_nfe, e.produto_id, p.qtde_entregue, e.qtde_recebida
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.qtde_recebida <> p.qtde_entregue
ORDER BY e.nro_nfe;

-- E15. entradas_mercadoria: data de entrada anterior a data do pedido (9 linhas)
SELECT e.nro_nfe, e.produto_id, p.data_pedido, e.data_entrada
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.data_entrada < p.data_pedido
ORDER BY e.nro_nfe;

-- E16. entradas_mercadoria: custo_unitario diferente do preco_compra do pedido (18 linhas)
SELECT e.nro_nfe, e.produto_id, p.preco_compra AS preco_no_pedido, e.custo_unitario AS custo_na_entrada
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.custo_unitario <> p.preco_compra
ORDER BY e.nro_nfe;

-- E17. produtos_filial: preco_compra maior que preco_venda (venda abaixo do custo) (4 linhas)
SELECT filial_id, produto_id, preco_compra, preco_venda
FROM produtos_filial
WHERE preco_compra > preco_venda
ORDER BY produto_id;

-- E18. produtos_filial: preco_compra do cadastro diferente do preco_compra dos pedidos (20 linhas)
SELECT pf.produto_id, pf.preco_compra AS cadastro, pc.preco_compra AS pedido
FROM produtos_filial pf
JOIN (SELECT DISTINCT produto_id, preco_compra FROM pedido_compra) pc ON pc.produto_id = pf.produto_id
WHERE pf.preco_compra <> pc.preco_compra
ORDER BY pf.produto_id;

-- E19. fornecedor: fornecedores sem nenhum produto (3 linhas)
SELECT f.idfornecedor, f.razao_social
FROM fornecedor f
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial pf WHERE pf.idfornecedor = f.idfornecedor)
ORDER BY f.idfornecedor;
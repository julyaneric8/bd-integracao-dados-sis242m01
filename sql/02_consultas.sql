-- Consulta 1: total vendido por produto em fevereiro de 2025

SELECT
    produto_id,
    SUM(qtde_vendida)                  AS total_quantidade,
    SUM(qtde_vendida * valor_unitario) AS total_reais
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao <  '2025-03-01'
GROUP BY produto_id
ORDER BY produto_id;

-- Consulta 2: produtos requisitados e nao recebidos

SELECT
    p.pedido_id,
    p.produto_id,
    p.descricao_produto,
    p.ordem_compra,
    p.qtde_pedida
FROM pedido_compra p
WHERE NOT EXISTS (
    SELECT 1
    FROM entradas_mercadoria e
    WHERE e.ordem_compra = p.ordem_compra
      AND e.produto_id   = p.produto_id
)
ORDER BY p.pedido_id;
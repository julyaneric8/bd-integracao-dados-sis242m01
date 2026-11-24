-- 03_transformacoes
-- Nome: Julyan Eric Lopes Pinto

-- Produto concatenado, data DD/MM/YYYY e filtro de "mais de 10 vezes"
-- Interpretacao de "mais de 10 vezes": quantidade requisitada (qtde_pedida) maior que 10 em cada
-- requisicao, como no exemplo do enunciado (15 unidades em 01/01/2025). Contar requisicoes
-- (COUNT > 10) nao retorna nada nesta base, pois cada produto tem no maximo 2 pedidos.
-- Periodo: fevereiro de 2025 (altere as datas do WHERE para mudar).
SELECT
    CONCAT_WS(' - ', p.produto_id, NULLIF(TRIM(p.descricao_produto), '')) AS "Produto",
    CAST(p.qtde_pedida AS double precision)                                AS "Qtde Requisitada",
    TO_CHAR(p.data_pedido, 'DD/MM/YYYY')                                   AS "Data Solicitação"
FROM pedido_compra p
WHERE p.data_pedido >= '2025-02-01'
  AND p.data_pedido <  '2025-03-01'
  AND p.qtde_pedida > 10
ORDER BY p.data_pedido, p.produto_id;

-- Trigger: se o produto entra sem fornecedor, cria um novo fornecedor (F21, F22...)
-- e grava o novo idfornecedor em produtos_filial.
CREATE OR REPLACE FUNCTION fn_gera_idfornecedor()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_num integer;
    v_id  varchar(25);
BEGIN
    SELECT COALESCE(MAX(SUBSTRING(idfornecedor FROM 2)::integer), 0) + 1
      INTO v_num
      FROM fornecedor
     WHERE idfornecedor ~ '^F[0-9]+$';

    v_id := 'F' || v_num;

    INSERT INTO fornecedor (idfornecedor, razao_social)
    VALUES (v_id, 'Fornecedor ' || v_num || ' (gerado automaticamente)');

    NEW.idfornecedor := v_id;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_gera_idfornecedor ON produtos_filial;
CREATE TRIGGER trg_gera_idfornecedor
    BEFORE INSERT ON produtos_filial
    FOR EACH ROW
    WHEN (NEW.idfornecedor IS NULL)
    EXECUTE FUNCTION fn_gera_idfornecedor();

-- Teste (o ROLLBACK desfaz tudo): P99 deve receber F21
BEGIN;
INSERT INTO produtos_filial (filial_id, produto_id, descricao)
VALUES (1, 'P99', 'Produto de teste');

SELECT produto_id, idfornecedor FROM produtos_filial WHERE produto_id = 'P99';
SELECT * FROM fornecedor WHERE idfornecedor = 'F21';
ROLLBACK;
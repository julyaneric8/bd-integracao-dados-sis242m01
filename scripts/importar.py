"""Importa dados/base_teste.xlsx para o PostgreSQL.
A senha vem da variavel de ambiente PGPASSWORD (nao fica no codigo).
Linhas rejeitadas ou duplicadas vao para rejeitados_<tabela>.csv.
"""
import os
from datetime import datetime, timedelta

import pandas as pd
import psycopg2

ARQUIVO = os.getenv("ARQUIVO_XLSX", "dados/base_teste.xlsx")
DB = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": int(os.getenv("PGPORT", "5432")),
    "database": os.getenv("PGDATABASE", "postgres"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", ""),
    "sslmode": os.getenv("PGSSLMODE", "prefer"),
}

ALIAS = {
    "idproduto": "produto_id",
    "idforncedor": "idfornecedor",
    "idfonecedor": "idfornecedor",
    "decricao": "descricao",
}

def txt(v):
    if pd.isna(v) or str(v).strip() == "":
        return None
    s = str(v).strip()
    if s.endswith(".0") and s[:-2].isdigit():
        s = s[:-2]
    return s

def numero(v):
    s = txt(v)
    return None if s is None else float(s.replace(",", "."))

def inteiro(v):
    n = numero(v)
    if n is None:
        return None
    if n != int(n):
        raise ValueError(f"valor nao inteiro: {n}")
    return int(n)

def data(v):
    s = txt(v)
    if s is None:
        return None
    if s.replace(".", "", 1).isdigit() and 1 < float(s) < 80000:
        return (datetime(1899, 12, 30) + timedelta(days=float(s))).date()
    iso = s[:4].isdigit() and s[4:5] == "-"
    return pd.to_datetime(s, dayfirst=not iso).date()

def hora(v):
    s = txt(v)
    if s is None:
        return "00:00:00"
    try:
        f = float(s)
        if 0 <= f < 1:
            seg = round(f * 86400)
            return f"{seg // 3600:02d}:{seg % 3600 // 60:02d}:{seg % 60:02d}"
    except ValueError:
        pass
    return s.split()[-1][:8]

ESPEC = {
    "fornecedor": [
        ("idfornecedor", txt), ("razao_social", txt)],
    "produtos_filial": [
        ("filial_id", inteiro), ("produto_id", txt), ("descricao", txt),
        ("estoque", numero), ("preco_unitario", numero), ("preco_compra", numero),
        ("preco_venda", numero), ("idfornecedor", txt)],
    "pedido_compra": [
        ("pedido_id", inteiro), ("data_pedido", data), ("item", inteiro),
        ("produto_id", txt), ("descricao_produto", txt), ("ordem_compra", inteiro),
        ("qtde_pedida", numero), ("filial_id", inteiro), ("data_entrega", data),
        ("qtde_entregue", numero),
        ("preco_compra", numero), ("fornecedor_id", inteiro)],
    "entradas_mercadoria": [
        ("ordem_compra", inteiro), ("data_entrada", data), ("nro_nfe", txt),
        ("item", inteiro), ("produto_id", txt), ("descricao_produto", txt),
        ("qtde_recebida", numero), ("filial_id", inteiro), ("custo_unitario", numero)],
    "venda": [
        ("venda_id", inteiro), ("data_emissao", data), ("horariomov", hora),
        ("produto_id", txt), ("qtde_vendida", numero), ("valor_unitario", numero),
        ("filial_id", inteiro), ("item", inteiro), ("unidade_medida", txt)],
}

def importar(conn, tabela, colunas):
    print(f"Importando {tabela}...")
    df = pd.read_excel(ARQUIVO, sheet_name=tabela, dtype=str)  # dtype=str: ids nao viram float
    df.columns = [ALIAS.get(c.strip().lower(), c.strip().lower()) for c in df.columns]

    nomes = [c for c, _ in colunas]
    faltam = [c for c in nomes if c not in df.columns]
    if faltam:
        print(f"  ERRO: colunas ausentes na aba: {faltam}")
        print(f"  Colunas encontradas: {list(df.columns)}\n")
        return

    sql = (f"INSERT INTO public.{tabela} ({', '.join(nomes)}) "
           f"VALUES ({', '.join(['%s'] * len(nomes))}) ON CONFLICT DO NOTHING")
    inseridas, rejeitadas = 0, []

    with conn.cursor() as cur:
        for i, row in df.iterrows():
            try:
                cur.execute(sql, [f(row[c]) for c, f in colunas])
                if cur.rowcount == 1:
                    inseridas += 1
                else:
                    rejeitadas.append({"linha_excel": i + 2, "motivo": "duplicada (PK repetida)", **row.to_dict()})
            except Exception as e:
                rejeitadas.append({"linha_excel": i + 2, "motivo": str(e).strip().splitlines()[0], **row.to_dict()})
        cur.execute(f"SELECT COUNT(*) FROM public.{tabela}")
        no_banco = cur.fetchone()[0]

    print(f"  lidas na planilha: {len(df)} | inseridas: {inseridas} | "
          f"rejeitadas/duplicadas: {len(rejeitadas)} | COUNT(*) no banco: {no_banco}")
    if rejeitadas:
        arq = f"rejeitados_{tabela}.csv"
        pd.DataFrame(rejeitadas).to_csv(arq, index=False)
        print(f"  detalhes em {arq}")
    print()

def main():
    print("Conectando no PostgreSQL...")
    try:
        conn = psycopg2.connect(**DB)
    except UnicodeDecodeError as e:
        print("Falha ao conectar:", e.object.decode("cp1252", errors="replace"))
        raise SystemExit(1)
    conn.autocommit = True  # erro em uma linha nao desfaz as outras
    print("Conectado!\n")
    # a ordem importa por causa das chaves estrangeiras
    for tabela in ["fornecedor", "produtos_filial", "pedido_compra",
                   "entradas_mercadoria", "venda"]:
        importar(conn, tabela, ESPEC[tabela])
    conn.close()
    print("Fim. Confira os numeros acima e os arquivos rejeitados_*.csv.")

if __name__ == "__main__":
    main()
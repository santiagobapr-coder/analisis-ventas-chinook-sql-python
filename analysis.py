"""Análisis de ventas de Chinook: ejecuta las consultas de queries.sql y genera gráficos.

Uso:
    python analysis.py ruta/a/Chinook_Sqlite.sqlite
Requiere: pandas y matplotlib.
"""
import re
import sqlite3
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

DB = sys.argv[1] if len(sys.argv) > 1 else "Chinook_Sqlite.sqlite"
OUT = Path("resultados")
OUT.mkdir(exist_ok=True)


def cargar_consultas(ruta: str = "queries.sql") -> dict:
    """Lee queries.sql y devuelve {nombre: sql}."""
    texto = Path(ruta).read_text(encoding="utf-8")
    partes = re.split(r"^-- name:\s*(\w+)\s*$", texto, flags=re.MULTILINE)
    return {partes[i]: partes[i + 1].strip() for i in range(1, len(partes), 2)}


def main() -> None:
    con = sqlite3.connect(DB)
    resultados = {n: pd.read_sql_query(q, con) for n, q in cargar_consultas().items()}
    con.close()

    for nombre, df in resultados.items():
        df.to_csv(OUT / f"{nombre}.csv", index=False)
        print(f"\n== {nombre} ==")
        print(df.to_string(index=False))

    # Gráfico 1: ingresos por año
    anual = resultados["ingresos_por_anio"]
    plt.figure(figsize=(7, 4))
    plt.bar(anual["anio"], anual["ingresos"], color="#2a6f97")
    plt.title("Ingresos por año")
    plt.ylabel("Ingresos (USD)")
    plt.tight_layout()
    plt.savefig(OUT / "ingresos_por_anio.png", dpi=150)
    plt.close()

    # Gráfico 2: ingresos por género (top 10)
    gen = resultados["ingresos_por_genero"].sort_values("ingresos")
    plt.figure(figsize=(7, 4))
    plt.barh(gen["genero"], gen["ingresos"], color="#2a6f97")
    plt.title("Ingresos por género (top 10)")
    plt.xlabel("Ingresos (USD)")
    plt.tight_layout()
    plt.savefig(OUT / "ingresos_por_genero.png", dpi=150)
    plt.close()

    # Gráfico 3: ingresos por país (top 10)
    pais = resultados["top_paises"].sort_values("ingresos")
    plt.figure(figsize=(7, 4))
    plt.barh(pais["pais"], pais["ingresos"], color="#2a6f97")
    plt.title("Ingresos por país (top 10)")
    plt.xlabel("Ingresos (USD)")
    plt.tight_layout()
    plt.savefig(OUT / "ingresos_por_pais.png", dpi=150)
    plt.close()

    print(f"\nListo: CSV y gráficos guardados en {OUT}/")


if __name__ == "__main__":
    main()

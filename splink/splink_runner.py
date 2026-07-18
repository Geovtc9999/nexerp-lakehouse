#!/usr/bin/env python3
"""
splink_runner.py — SCAFFOLD (résolution d'entités du Data Fabric).

⚠️ NON FONCTIONNEL EN L'ÉTAT — placeholder documenté.

Contexte : la base source actuelle (`nexerp`) est la base OPÉRATIONNELLE de la
plateforme Bayon MDM (agents, skills, threads, knowledge, audit…). Ses entités
« maître » (organization/siren, perimeter/siret, app_user/email) sont peu
nombreuses et déjà sous contrainte d'unicité — rien à dédoublonner à l'échelle.

La VRAIE résolution d'entités (Splink) portera sur la MASTER DATA MÉTIER
(clients, fournisseurs, produits) une fois qu'elle sera matérialisée dans le
lakehouse Iceberg depuis Odoo/CEGID via le bus CDC. À ce moment-là, définir ici :
  - le/les dataset(s) source,
  - les blocking_rules (ex. même code postal, même préfixe nom normalisé),
  - les comparisons (nom fuzzy jaro-winkler, email exact, adresse levenshtein),
  - le seuil de match et l'écriture du golden record.

Ce script se contente aujourd'hui d'un SMOKE TEST : il se connecte à la base et
rapporte les doublons EXACTS candidats sur les entités maître (attendu : 0),
ce qui valide la connexion et le pipeline sans inventer de règles floues.
"""
import os
import sys

# Le vrai run importera splink ; ici on reste léger (juste psycopg pour le smoke test).
try:
    import psycopg
except ImportError:
    print("psycopg non installé — `pip install psycopg[binary]` (smoke test) "
          "ou `pip install splink psycopg[binary]` (run réel).", file=sys.stderr)
    sys.exit(2)

DSN = (
    f"host={os.environ.get('PG_HOST','')} "
    f"port={os.environ.get('PG_PORT','5432')} "
    f"dbname={os.environ.get('PG_DB','nexerp')} "
    f"user={os.environ.get('PG_USER','fabric_app')} "
    f"password={os.environ.get('PG_PASSWORD','')}"
)

# Entités maître candidates + clé de dédoublonnage exact (smoke test uniquement).
CANDIDATES = [
    ("organization", "siren"),
    ("perimeter", "siret"),
    ("app_user", "email"),
]


def main() -> int:
    print("[splink_runner] SCAFFOLD — smoke test connexion + doublons exacts\n")
    with psycopg.connect(DSN) as conn, conn.cursor() as cur:
        for table, key in CANDIDATES:
            cur.execute(
                f"SELECT {key}, count(*) c FROM nexerp.{table} "
                f"WHERE {key} IS NOT NULL GROUP BY {key} HAVING count(*) > 1"
            )
            dups = cur.fetchall()
            status = "OK (aucun doublon)" if not dups else f"⚠️ {len(dups)} clé(s) dupliquée(s)"
            print(f"  - {table}.{key:8} -> {status}")
    print("\n[splink_runner] TODO : implémenter la résolution floue sur la master "
          "data métier (lakehouse) — voir docstring.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

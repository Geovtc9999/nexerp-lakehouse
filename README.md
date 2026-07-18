# nexerp-lakehouse

Runners cognitifs du Data Fabric Cognitif NEXERP (palier A → B) :
résolution d'entités (Splink) et qualité de données (Soda), exécutés à la demande / en cron.

> ⚠️ Corrections vs runbook : réseau réel = **`coolify`** (pas `fabric_internal`/`fabric_data`) ;
> base source réelle = **`nexerp`** sur le conteneur `ysprg0oqzl86voh0kv0u6b6q` (pas `nexerp_ia_factory`).

## Structure
```
soda/          # checks qualité de données (Soda Core) — voir soda/README
splink/        # résolution d'entités (Splink) — SCAFFOLD, règles métier à définir
dbt/           # modèles de transformation (à venir)
```

## État — palier A
- **Soda** : socle de checks réels sur la base source (row_count, nulls sur clés, unicité, fraîcheur).
- **Splink** : scaffold non fonctionnel — nécessite de définir les entités à dédoublonner
  (clients ? produits ?) et les règles de blocage/comparaison. Placeholder documenté.

## Exécution
Voir `soda/README.md` et `splink/README.md`.

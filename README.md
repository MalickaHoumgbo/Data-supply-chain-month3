# Product Inventory Management

## 🎯 Contexte & problématique métier
LogiDistrib est un distributeur B2B de matériel et fournitures industrielles pour le secteur de la construction. À travers ses 5 entrepôts régionaux, l'entreprise fait face à un double dysfonctionnement logistique : des ruptures de stock récurrentes d'une part, et des produits en surstock d'autre part. Ce déséquilibre est particulièrement coûteux, car les ruptures entraînent des ventes perdues et dégradent la satisfaction client, tandis que les surstocks immobilisent inutilement de la trésorerie et saturent l'espace de stockage.

L'objectif stratégique du projet est donc d'identifier les causes des ruptures afin d'anticiper les risques, tout en priorisant le traitement des surstocks en fonction de leur impact financier réel.

## 🗃️ Origine des données
Les analyses reposent sur le dataset public Kaggle [High-Dimensional Supply Chain Inventory Dataset](https://www.kaggle.com/datasets/ziya07/high-dimensional-supply-chain-inventory-dataset).
Le scénario de l'entreprise LogiDistrib a été élaboré a posteriori pour fournir un cadre fonctionnel et métier réaliste à l'exploitation de ces données.

## 📊 KPI suivis
**Axe 1 — Rupture de stock**
- **Indicateur de rupture de stock** (`Stockout_Flag`) : mesure le constat historique des incidents de rupture constatés sur chaque couple SKU/entrepôt.
- **Rapport du stock actuel au seuil de point de commande** (`Inventory_Level` vs `Reorder_Point`) : évalue le risque d'épuisement imminent en comparant le niveau de stock disponible au seuil d'alerte configuré.
- **Indice de calibration du point de commande** : évalue si le seuil de réapprovisionnement configuré est bien adapté au délai fournisseur et à la vitesse de vente habituelle.

**Axe 2 — Stock dormant / surstock**
- **Jours de couverture de stock** : estime la durée pendant laquelle le stock actuel permettra de répondre à la demande au rythme de vente moyen.
- **Valeur du capital immobilisé en surstock (€)** : chiffre le montant financier bloqué dans les stocks à rotation insuffisante afin d'ordonnancer les actions prioritaires.

## 🗂️ Architecture des données

Le modèle suit un **schéma en étoile**, avec une table de faits centrale et deux dimensions.

**`fact_daily_stock_movement`** (table de faits)
Granularité : 1 ligne = 1 SKU × 1 Entrepôt × 1 Jour (50 SKU × 5 entrepôts × 365 jours = 91 250 lignes)
- `sku_id`, `warehouse_id`, `date` — clés de granularité
- `units_sold`, `inventory_level`, `order_quantity` — mouvements de stock
- `unit_cost`, `unit_price` — valorisation financière
- `reorder_point`, `supplier_lead_time_days` — paramètres de réapprovisionnement

*(Choix de rattacher `unit_cost`, `unit_price`, `reorder_point` et `supplier_lead_time_days` à la table de faits plutôt qu'aux dimensions : voir [Journal des Cicatrices](docs/journal_cicatrices.md).)*

**`dim_produit`** (dimension)
- `sku_id` (clé) : 50 produits

**`dim_entrepot`** (dimension)
- `warehouse_id` (clé) : 5 entrepots regionaux

> **Note de modélisation** : `Stockout_Flag`, présent dans le dataset source, a été exclu du modèle — la colonne était constante (0) sur l'ensemble des lignes, sans valeur analytique.

```mermaid
erDiagram
    dim_produit ||--o{ fact_daily_stock_movement : "décrit"
    dim_entrepot ||--o{ fact_daily_stock_movement : "décrit"

    dim_produit {
        string sku_id PK
    }

    dim_entrepot {
        string warehouse_id PK
    }

    fact_daily_stock_movement {
        string sku_id PK/FK
        string warehouse_id PK/FK
        date date PK
        int units_sold
        int inventory_level
        int order_quantity
        float unit_cost
        float unit_price
        int reorder_point
        int supplier_lead_time_days
    }
```

## 🛠️ Stack technique
- **Ingestion / modélisation** : BigQuery / JupyterLab
- **Requêtes analytiques** : SQL avancé (CTE, window functions)
- **Restitution** : Power BI

## 📁 Structure du dépôt
```
├── notebooks/    → notebook Python (EDA, préparation des données)
├── sql/          → requêtes SQL BigQuery
├── power_bi/     → dashboard et captures d'écran
└── docs/         → documentation, journal des cicatrices, transparence IA
```

## 🚀 Comment explorer ce projet
- **Cadrage métier & logique d'analyse** : pour consulter la méthodologie complète, les détails des axes d'analyse et les règles de gestion métier, référez-vous au document de cadrage détaillé : [`docs/cadrage_final_logidistrib.md`](docs/cadrage_final_logidistrib.md).
- **Prise en main & exécution** : À compléter (instructions pour exécuter le notebook, lancer les requêtes SQL et ouvrir le tableau de bord Power BI).


## ✅ Résultats clés
> À compléter en fin de projet.

## 🤝 Transparence sur l'usage de l'IA
Voir [`docs/charte_transparence_ia.md`](docs/charte_transparence_ia.md).

## Auteur

MalickaHoumgbo/ [GitHub](https://github.com/MalickaHoumgbo)

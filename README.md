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
> À compléter : schéma des tables 

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

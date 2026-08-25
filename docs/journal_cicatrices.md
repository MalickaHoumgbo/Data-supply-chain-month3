# 📓 Journal des cicatrices

Documentation transparente des erreurs réelles rencontrées pendant ce projet et de leur résolution. L'objectif : transformer les blocages en preuves de compétence pour l'entretien.


---

## Entrées
### 17/08/26 : Stockout_Flag inutilisable, quand un KPI "précalculé" ne l'est pas vraiment

**Contexte** : mon cadrage prévoyait un Niveau 1 "constat" reposant sur Stockout_Flag, une colonne binaire fournie directement par le jeu de données.

**Découverte** : l'EDA a révélé un value_counts `à 100% de zéros` ,  confirmé aussi par une lecture brute du fichier dans Excel.

**Investigation** : aucune colonne du périmètre validé ne permet de reconstruire ce signal. `Units_Sold` est structurellement plafonné par le stock disponible. `Inventory_Level` ne descend jamais sous 168 unités. `Demand_Forecast` aurait pu jouer ce rôle mais était hors périmètre dès le cadrage, et son format restait ambigu.

**Décision** : plutôt que de réintroduire une colonne hors scope pour "sauver" une hypothèse initiale, j'ai simplifié honnêtement mon architecture en retirant le Niveau 1.

**Ce que ça m'apprend** : un KPI précalculé n'est pas une garantie de fiabilité, il se vérifie empiriquement avant d'être bâti dans une architecture d'analyse.

---

### 19/08/26 : Erreur d'interprétation de la colonne date dans Bigquery

**Contexte** : la nouvelle table nettoyée après l'EDA devait être importée vers Bigquery sous l'extension .parquet, plus propice à la reconnaissance du typage des colonnes

**Découverte** : au moment de la création de la table dans le projet, BigQuery a interprété `la colonne date comme un entier Integer`.

**Investigation** : Dans le fichier Jupyter, le type `date` avait été converti par pandas en un `timestamp` avec une précision de nanosecondes, exporté tel quel dans  Bigquery, il n'a pas su interpréter correctement ce typage, et l'a assigné à un entier.

**Décision** : il a fallu retourner dans le notebook local de l'EDA pour extraire la partie date du timestamp, avec dt.date. La vérification à l'exécution a prouvé que la colonne date était au bon format `date32[day]`.

**Ce que ça m'apprend** : le format .parquet n'est pas une garantie absolue pour la reconnaissance des colonnes dans bigquery.

---

### 23/08/26 : Modélisation des dimensions entrepôts et produits 

**Contexte** pour séparer les tables en faits et dimensions, il était important de savoir quels attributs iraient dans les tables des entrepôts et des produits

**Découverte** : deux vérifications distinctes étaient nécessaires : 
- la stabilité dans le temps (est-ce que la valeur change jour après jour pour un même couple SKU × Entrepôt ?) 
- la granularité (est-ce que la valeur dépend d'une seule dimension ou de leur combinaison ?). 
En EDA Python, seule la stabilité dans le temps de `reorder_point` et `supplier_lead_time_days` avait été vérifiée. La granularité des 4 colonnes (`unit_cost`, `unit_price`, `reorder_point`, `supplier_lead_time_days`) a été testée en SQL dans BigQuery : chaque colonne montre 5 valeurs distinctes par SKU seul, mais 1 seule valeur par couple SKU × Entrepôt , confirmant leur dépendance à la combinaison des deux dimensions.
le fichier [`sql/02_granularity_check_fact_attributes.`](sql/02_granularity_check_fact_attributes.) consigne les différentes requêtes.

**Décision**: les tables des produits et entrepôts, ne seront constitués que des identifiants `sku_id` et `warehouse_id`, les tables des faits regrouperont le reste des colonnes


### 23/08/26 : Clé composite et taille d'une table

**Découverte** : une clé composée peut se décliner sur plusieurs colonnes, au lieu d'une seule ; c'est une combinaison qui fait l'unicité de ses valeurs.
si elle correspond au nombre de lignes de la table, elle est unique pour chaque ligne.

---

### 24/08/26 : Choix de jointures sur les CTE de niveaux de rupture

**Contexte** : Comment réunir les CTES des niveaux de rupture pour croiser les ruptures critiques

**Découverte** : j'ai associé à tort les conditions des ruptures critiques et la disponibilité des lignes, j'ai pensé qu'un `full join` réunirait tout le monde et qu'un `inner join` croiserait les combinaisons `sku_id + warehouse_id`, ayant seulement des niveaux de ruptures visibles

**Investigation** : avec l'IA , j'ai reçu les explications de pourquoi cette distinction n'avait pas de sens et qu'il fallait se concentrer sur les combinaisons de `sku_id + warehouse_id` des 2 côtés, peu importe à quels niveaux de rupture elles appartiennent.

**Décision**: j'ai opté pour un inner join, aucune combinaison de clés (`sku_id + warehouse_id`) n'est absente des 2 côtés, si les CTE avaient eu des tables sources ou des filtres différents, le `choix d'un full join ou d'un inner join` aurait pu changer le résultat.

**Ce que ça m'apprend**: le choix d'une jointure dépend d'un nombre de paramètres sur la composition des tables, et non de leurs valeurs





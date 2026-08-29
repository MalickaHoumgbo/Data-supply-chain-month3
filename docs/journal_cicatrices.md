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

---

### 25/08/26: Modifications des structures SQL dans 05_Stockout_risk

**Contexte** : le choix des CTE combinés à leurs requêtes principales marchait, mais était redondant à 2 endroits dans le code des requêtes des ruptures de niveaux 2 et 3.

**Découverte** : pour un problème de portée, j'ai voulu chercher une solution plus optimale, au lieu d'avoir les mêmes blocs de code qu'on réécrit et réexécute plusieurs fois.

**Investigation** :  il fallait trouver une structure qui éliminait la redondance de code, tout en étant fiable au niveau des coûts de calcul. Si les CTE étaient gardées et qu'il fallait faire une modification de code, à chaque fois qu'elles étaient réécrites dans le code, un risque d'oubli pouvait se produire. Les vues sont définies une fois et ne se modifient qu'à un seul endroit.

**Décision** : le choix des vues s'est imposé ; on les crée une seule fois, puis on les appelle simplement dans les requêtes principales. Si je veux modifier une logique de base, je peux la modifier dans la vue définie, au lieu de la répéter à plusieurs endroits du code où elle apparaît. La table source fait 91250 lignes ; pas besoin de  se préoccuper du coût des calculs à chaque appel.


### 25/08/26: Clés étrangères entre tables de dimensions

**Contexte** : dans le fichier `03_dimensions_tables.sql` qui modélise la table des dimensions , aucune clé étrangère n'était déclarée pour aucune d'elles

**Découverte** : je me disais que j'avais dû oublier de relier les 2 dimensions entre elles, avec une clé étrangère dans `dim_produit` qui la relierait à `dim_entrepot` et inversement.

**Investigation** : je partais du principe qu’un produit peut se trouver dans un ou plusieurs entrepôts, et un entrepôt peut contenir un ou plusieurs produits,
Mais la table des faits `fact_daily_stock_movement` contenait déjà la relation qui lie les 2 dimensions, ce qui est conforme au modèle en étoile où les dimensions gravitent autour des faits, contrairement à un modèle relationnel classique.

**Décision** : Aucune clé étrangère n'a été établie entre les dimensions. Dans un modèle en étoile, les dimensions ne se relient jamais directement entre elles, même quand une relation many-to-many existe ; c'est la table de faits qui porte cette relation.

**Ce que ça m'apprend**: Si je réutilise ce modèle sur un futur projet, je ne chercherai plus de clé étrangère entre deux dimensions : je vérifierai plutôt si la table de faits contient déjà les deux clés ensemble

---
### 27/08/26: Calibration du seuil pour les stocks dormants.

**Contexte** : Sur ma requête finale de détection des stocks dormants, avec un seuil fixé à 2 × la médiane par segment de capacité de vitesse de ventes (`sales_velocity`), aucune ligne n'a été catégorisée comme stock dormant, sur l'ensemble de la table.

**Découverte** : L'intention de départ était logique : la médiane représente la valeur la plus représentative d'une distribution, donc un multiplicateur (×2) appliqué à cette médiane devait isoler les jours de couverture(`recovery_days`) nettement au-dessus du comportement habituel du segment.

**Investigation** : En me servant d'une requête `MIN/MAX/médiane par segment`, j'ai découvert que la valeur maximale de jours de couverture, tous segments confondus, restait en dessous du seuil théorique (2×médiane). Le seuil n'était donc jamais atteignable : le problème ne venait pas de la logique du multiplicateur, mais du fait qu'il était structurellement trop haut pour la distribution réelle du dataset (rapport max/médiane observé 1,7-1,8x, contre 2x attendu).

**Décision** :J'ai remplacé l'ancien par un seuil plus proche de la distribution elle-même : `PERCENTILE_CONT(recovery_days, 0.9)` par segment, qui isole automatiquement les 10 % de valeurs de jours de couverture les plus élevées.

**Ce que ça m'apprend** : Avant de figer un multiplicateur ou tout autre critère, il faut vérifier au préalable l'étendue réelle des données (min/max/percentiles) plutôt que de faire confiance à l'intuition métier seule.


### 27/08/26: Seuils p90 proches entre différents segments..

**Constat** : Une fois le seuil P90 par segment mis en place et la requête retestée, les valeurs de seuil obtenues pour chaque `sales_velocity` (rapide / moyen / lent) se sont révélées très proches les unes des autres (`29-30 jours`), alors qu'une vraie segmentation par vitesse de vente devrait normalement produire des seuils différents.

**Interprétation** : C'est la confirmation chiffrée d'une limite déjà identifiée  dans le cadrage du projet : le dataset est synthétique, et ne reproduit pas de vraie corrélation entre la vitesse de vente d'un produit et son niveau de stock. Dans un dataset réel, un produit à rotation rapide aurait un seuil de "stock dormant" beaucoup plus bas qu'un produit à rotation lente, car son rythme de vente habituel est différent.

**Ce que ça m'apprend** : la nouvelle approche pour la détection du seuil avec p90 n'est pas à remettre en cause, mais elle reste limitée sur ce dataset precis.

**Note additionnelle** : Au cours de la manipulation SQL dans BigQuery, il a été de nouveau confirmé via les valeurs anormalement proches de `average_sales` (entre 19 et 22 selon les produits)  que le dataset ne repose pas sur un historique de comportements de vente réels, mais sur une génération synthétique.


---

### 28/08/26: Lacunes sur les performances des requêtes en environnement cloud

**Constat** : Lors d'une session de crash test d'auto-évaluation, je me suis rendue compte que, je ne maîtrise pas encore l'impact des CTEs empilées, des window functions (NTILE, PERCENTILE_CONT), des VIEWs, et du volume de données sur la performance/coût en environnement Cloud (BigQuery). 

**Décision** : Face à une potentielle question de Tech Lead sur la montée en charge (×100, ×1000), j'ai choisi de ne pas deviner une réponse théorique non maîtrisée, et de planifier une session d'apprentissage dédiée à la performance Cloud plutôt que de simuler une compréhension que je n'ai pas.

















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


### 19/08/26 : Erreur d'interprétation de la colonne date dans Bigquery

**Contexte** : la nouvelle table nettoyée après l'EDA devait être importée vers Bigquery sous l'extension .parquet, plus propice à la reconnaissance du typage des colonnes

**Découverte** : au moment de la création de la table dans le projet, BigQuery a interprété `la colonne date comme un entier Integer`.

**Investigation** : Dans le fichier Jupyter, le type `date` avait été converti par pandas en un `timestamp` avec une précision de nanosecondes, exporté tel quel dans  Bigquery, il n'a pas su interpréter correctement ce typage, et l'a assigné à un entier.

**Décision** : il a fallu retourner dans le notebook local de l'EDA pour faire une extraction de la partie date elle-même dans le timestamp, avec dt.date. La vérification à l'exécution a prouvé que la colonne date était au bon format `date32[day]`.

**Ce que ça m'apprend** : le format .parquet n'est pas une garantie intégrale pour la reconnaissance de colonne dans bigquery.







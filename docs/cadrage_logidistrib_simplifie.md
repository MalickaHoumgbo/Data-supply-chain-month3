# Cadrage final — Gestion de stock (LogiDistrib)

> Projet Mois 3 — Analytics Engineering & Data Analysis

---

## 1. Contexte & scénario

**LogiDistrib** est un distributeur B2B de matériel et fournitures industrielles/chantier, qui s'appuie sur **5 entrepôts régionaux** (`WH_1` à `WH_5`) pour approvisionner un réseau de magasins clients.

La direction des opérations fait face à un double problème :
1. **Des ruptures de stock récurrentes**, qui empêchent d'honorer certaines commandes clients.
2. **Des produits qui s'entassent sans rotation suffisante**, occupant de l'espace et immobilisant de la trésorerie.

**Objectif du projet :** identifier les causes des ruptures actuelles et futures, et prioriser le traitement des surstocks selon leur impact financier réel.

---

## 2. Le dataset

Dataset Kaggle *High-Dimensional Supply Chain Inventory* — 1 an d'historique quotidien, 50 SKU, 5 entrepôts (1 ligne = 1 SKU × 1 entrepôt × 1 jour).

### Colonnes retenues

| Colonne | Type | Rôle Analytic & Traitement |
| :--- | :--- | :--- |
| `Date` | Temporal | Axe temporel principal de l'analyse. |
| `SKU_ID` | Identifiant | Clé unique du produit (50 références). |
| `Warehouse_ID` | Identifiant | Clé du site logistique (5 entrepôts stables). |
| `Units_Sold` | Quantité | Mouvement de sortie quotidien. Sert au calcul de la vitesse moyenne de vente. |
| `Inventory_Level` | Quantité | État physique du stock au jour $T$. Base du calcul de couverture et de surstock. |
| `Supplier_Lead_Time_Days` | Délai (Jours) | Temps d'approvisionnement fournisseur. Donnée d'entrée pour le point de commande. |
| `Reorder_Point` | Seuil (Unités) | Seuil de réapprovisionnement configuré par couple SKU/Entrepôt. |
| `Order_Quantity` | Quantité | Mouvement d'entrée commandé au fournisseur. |
| `Unit_Cost` | Monétaire (€) | Coût d'achat unitaire. Nécessaire pour valoriser le capital immobilisé. |
| `Unit_Price` | Monétaire (€) | Prix de vente unitaire. Utile pour chiffrer les ventes perdues lors des ruptures. |
| `Stockout_Flag` | Binaire (0/1) | Variable cible constatant le dépassement de la demande par rapport au stock. |


### Colonnes exclues
- **`Region`** — incohérente comme attribut fixe d'un entrepôt (un même `Warehouse_ID` est associé à plusieurs régions).
- **`Supplier_ID`** — relève de la performance fournisseur, hors périmètre du contrôle de stock.
- **`Promotion_Flag`** — gardée en tête comme facteur de confusion possible, pas un axe d'analyse.
- **`Demand_Forecast`** — relève de la prévision de demande, écartée au profit du contrôle de stock.

---

## 3. Vue d'ensemble des deux axes

Le projet s'articule autour de deux axes complémentaires, qui explorent les deux faces de la gestion de stock :

| | Axe 1 — La rupture | Axe 2 — Le surstock |
|---|---|---|
| **Question** | Le stock va-t-il tenir ? | Le stock est-il resté trop longtemps ? |
| **Logique** | Constat → alerte → diagnostic | Repérer → prioriser |

---

## 4. Axe 1 — Rupture de stock

### Problématique
> Identifier les produits déjà en rupture et comprendre si leur seuil de réapprovisionnement était insuffisant face à la demande ; repérer les produits à risque potentiel, soit parce que leur stock actuel est déjà sous le seuil d'alerte, soit parce que leur seuil lui-même est structurellement sous-dimensionné.

### Les trois niveaux de lecture

| Niveau | Question métier | KPI mobilisé |
|---|---|---|
| 1 — Constat | Y a-t-il déjà eu rupture ? | `Stockout_Flag` |
| 2 — Alerte présente | Le stock est-il en danger aujourd'hui ? | Comparaison stock actuel / seuil de réapprovisionnement |
| 3 — Diagnostic structurel | Le seuil est-il bien calibré ? | Comparaison vitesse de vente × délai fournisseur / seuil de réapprovisionnement |

### Segmentation
- **Bucket 1 — Ruptures constatées** : produits en `Stockout_Flag = 1`, avec diagnostic du niveau 3 pour comprendre la cause.
- **Bucket 2 — Risque potentiel** : niveau 2 **OU** niveau 3 — une seule condition suffit pour entrer dans ce bucket.

---

## 5. Axe 2 — Stock dormant

### Problématique
> Identifier les produits dont le niveau de couverture est anormalement élevé au regard de leur rythme de vente habituel, et exploiter la valeur du capital immobilisé pour prioriser le traitement des surstocks à plus fort impact financier.

### Les deux indicateurs clés

| Indicateur | Rôle |
|---|---|
| Jours de couverture | Repérer le symptôme — combien de temps le stock actuel va durer au rythme de vente habituel |
| Valeur immobilisée | Prioriser l'urgence financière — chiffrer en euros ce que le surstock coûte à LogiDistrib |

### Nuance clé : le piège du seuil fixe
Un même nombre de jours de couverture n'a pas la même signification selon la vitesse de rotation naturelle du produit (logique proche de la classification ABC). Le seuil d'alerte doit donc être **relatif à la catégorie de rotation du produit**, pas fixe pour tout le catalogue.

---

## 6. Limites du projet

1. **Données synthétiques** — le dataset simule des comportements de demande et de réassort, sans les aléas d'un historique réel.
2. **Scénario construit a posteriori** — LogiDistrib a été conçu pour encadrer un dataset existant, plutôt que l'inverse.
3. **KPI précalculés** — `Reorder_Point` et `Stockout_Flag` sont fournis directement par le dataset. En entreprise réelle, ces indicateurs doivent être construits par le Data Analyst à partir de données transactionnelles brutes.

---

## 7. Prochaines étapes

- [x] Étape 0 — Cadrage fonctionnel et validation des problématiques métier
- [ ] Étape 1 — Ingestion et modélisation dans BigQuery / JupyterLab
- [ ] Étape 2 — Écriture des requêtes SQL avancées (KPI, CTE, window functions)
- [ ] Étape 3 — Dashboard Power BI et documentation GitHub

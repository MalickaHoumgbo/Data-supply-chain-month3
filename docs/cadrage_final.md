# Cadrage final — Gestion de stock (LogiDistrib)

> Analytics Engineering & Data Analysis

---

## 1. Contexte & scénario

**LogiDistrib** est un distributeur B2B de matériel et fournitures industrielles/de chantier, qui s'appuie sur **5 entrepôts régionaux** (`WH_1` à `WH_5`) pour approvisionner un réseau de magasins clients.

**Objectif du projet** : Les équipes opérationnelles de LogiDistrib constatent deux irritants récurrents : 

- des ruptures de stock qui pourraient empêcher d'honorer certaines commandes clients
- des produits qui s'entassent sans rotation suffisante, immobilisant l'espace et trésorerie.

Le projet ne cherche pas à établir l'ampleur exacte des ruptures passées : cette vérification s'est révélée impossible avec les données disponibles (le `Stockout_Flag` est constant à 0, cf. Limites). 

Il adopte donc une posture entièrement préventive sur le volet rupture : 

- repérer en amont les produits dont le stock actuel est déjà sous son seuil de réapprovisionnement (**risque immédiat**), ou dont ce seuil est structurellement mal calibré face au délai fournisseur et à la vitesse de vente (**risque structurel**)
- 
- tout en priorisant le traitement des surstocks selon leur impact financier réel

---

## 1bis. Rôle et destinataires

### Par qui : posture de l'analyste

Ce projet est mené du point de vue d'une **collaboratrice de l'équipe data de LogiDistrib**, en interne et non d'une intervenante externe ou d'un consultant mandaté ponctuellement. 
Cette posture conditionne les choix du projet : l'analyse s'inscrit dans une logique de suivi récurrent (dashboard consultable régulièrement), pas dans une étude ponctuelle livrée une fois pour toutes.

### Pour qui : destinataires des résultats

L'analyse s'adresse à deux publics distincts, conformément à la séparation opérée dans le dashboard Power BI :

| Volet | Destinataire | Usage des résultats |
|---|---|---|
| **Ruptures de stock** (risque immédiat + structurel) | **Supply Chain Planner / Approvisionneur** | Action opérationnelle directe : ajuster les commandes et les seuils de réapprovisionnement sur les produits identifiés à risque. |
| **Stock dormant** (capital immobilisé) | **Contrôle de gestion / Direction financière** | Lecture en impact financier : prioriser les arbitrages de déstockage selon la valeur immobilisée en euros. |

Cette distinction de destinataires justifie également la séparation des deux axes d'analyse (cf. section 3) : chaque public a besoin d'un niveau de lecture et d'un vocabulaire adaptés à sa fonction, plutôt que d'un rapport unique et générique.

---

## 2. Le dataset

Dataset Kaggle *High-Dimensional Supply Chain Inventory* — 1 an d'historique quotidien, 50 SKU, 5 entrepôts (1 ligne = 1 SKU × 1 entrepôt × 1 jour).

### Colonnes retenues

| Colonne | Type | Rôle Analytic & Traitement |
| :--- | :--- | :--- |
| `Date` | Temporel | Axe temporel principal de l'analyse. |
| `SKU_ID` | Identifiant | Clé unique du produit (50 références). |
| `Warehouse_ID` | Identifiant | Clé du site logistique (5 entrepôts stables). |
| `Units_Sold` | Quantité | Mouvement de sortie quotidien. Sert au calcul de la vitesse moyenne de vente. |
| `Inventory_Level` | Quantité | État physique du stock au jour $T$. Base du calcul de couverture et de surstock. |
| `Supplier_Lead_Time_Days` | Délai (Jours) | Temps d'approvisionnement du fournisseur. Donnée d'entrée pour le point de commande. |
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
> Identifier les produits susceptibles d'être en rupture et comprendre si leur stock_actuel et/ou seuil de réapprovisionnement ferait face à la demande ; 

### Les trois niveaux de lecture

| Niveau | Question métier | KPI mobilisé |
|---|---|---|
| ~~1 — Constat~~ | ~~Y a-t-il déjà eu rupture ?~~ | ~~`Stockout_Flag`~~ *(retiré — colonne constante à 0, cf. Limites §4)* |
| 2 — Alerte présente | Le stock est-il en danger aujourd'hui ? | Comparaison stock actuel / seuil de réapprovisionnement |
| 3 — Diagnostic structurel | Le seuil est-il bien calibré ? | Comparaison vitesse de vente × délai fournisseur / seuil de réapprovisionnement |

### KPI suivis
- ~~**Indicateur de rupture de stock** (`Stockout_Flag`)~~ — *KPI initialement prévu pour le Niveau 1, abandonné après vérification empirique lors de l'EDA (colonne constante à 0, cf. Limites §6.4).*
- **Rapport du stock actuel au seuil de point de commande** (`Inventory_Level` vs `Reorder_Point`) : évalue le risque d'épuisement imminent en comparant le niveau de stock disponible au seuil d'alerte configuré.
- **Indice de calibration du point de commande** : évalue si le seuil de réapprovisionnement configuré est bien adapté au délai fournisseur et à la vitesse de vente habituelle.

### Segmentation
- **Risque immédiat** : Niveau 2 seul — le stock est sous son seuil de réapprovisionnement aujourd'hui.
- **Risque structurel** : Niveau 3 seul — le seuil lui-même est mal calibré face à la vitesse de vente et au délai fournisseur.
- **Risque critique** : Niveau 2 **ET** Niveau 3 — les deux signaux se cumulent, priorité de traitement maximale.

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

### KPI suivis
- **Jours de couverture de stock** : estime la durée pendant laquelle le stock actuel permettra de répondre à la demande au rythme de vente moyen.
- **Valeur du capital immobilisé en surstock (€)** : chiffre le montant financier bloqué dans les stocks à rotation insuffisante afin d'ordonnancer les actions prioritaires.
---

## 6. Limites du projet

1. **Données synthétiques** — le dataset simule des comportements de demande et de réassort, sans les aléas d'un historique réel.
2. **Scénario défini avant le dataset** — la problématique métier (ruptures de stock / stock dormant) a été posée en amont ; le dataset Kaggle a ensuite été sélectionné pour lui correspondre, avec les écarts que cela implique (cf. limite n°4 sur `Stockout_Flag`).
3. **KPI précalculés** — `Reorder_Point` et `Stockout_Flag` sont fournis directement par le dataset. En entreprise réelle, ces indicateurs doivent être construits par le Data Analyst à partir de données transactionnelles brutes.
4. **`Stockout_Flag` inutilisable** — vérification empirique lors de l'EDA : colonne constante à 0. Le Niveau 1 initialement prévu a été retiré de l'Axe 1 (cf. journal des cicatrices).

---

## 7. Prochaines étapes

- [x] Étape 0 — Cadrage fonctionnel et validation des problématiques métier
- [x] Étape 1 — Ingestion et modélisation dans BigQuery / JupyterLab
- [x] Étape 2 — Écriture des requêtes SQL avancées (KPI, CTE, window functions)
- [x] Étape 3 — Dashboard Power BI et documentation GitHub

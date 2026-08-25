/*
Ce fichier sert à tester la variabilité des colonnes par couple (SKU, entrepôt).
Si une donnée varie et n'a pas une seule valeur unique par SKU ou par entrepôt, 
elle ne peut pas être figée dans une table de dimension : elle doit aller dans la table de faits.
*/

-- LECTURE : La requête ne renvoie aucune ligne  pour tout couple SKU x Entrepôt, 
-- une seule valeur de coût/prix existe sur l'année. Le coût/prix est donc stable dans le temps au sein d'un groupe. 
-- Mais il change d'un couple à l'autre : il dépend de la combinaison des deux clés, pas d'une seule.
-- Il ne peut appartenir ni à dim_produit ni à dim_entrepot : il va dans la table de faits."
select sku_id,
        warehouse_id,
        count(distinct unit_cost),
from `logidistrib_dwh.stg_inventory_raw`
group by sku_id, warehouse_id
having count(distinct unit_cost) > 1;


select sku_id,
       warehouse_id,
       count(distinct unit_price),
from `logidistrib_dwh.stg_inventory_raw`
group by sku_id, warehouse_id
having count(distinct unit_price) > 1;


-- LECTURE : Pour un même couple SKU x Entrepôt, une seule valeur apparaît sur l'année (count = 1) : la colonne est stable dans le temps au sein d'un groupe. 
-- Mais la valeur change d'un groupe à l'autre (d'un couple SKU/Entrepôt à un autre) :
-- elle dépend donc de la combinaison des deux clés, pas d'une seule. 
-- Aucune dimension seule (dim_produit ou dim_entrepot) ne peut la porter :
--  elle va aussi dans la table de faits, pour une raison différente de unit_cost/unit_price — pas une instabilité temporelle, mais une dépendance à deux clés.
select sku_id,
       warehouse_id,
       count(distinct reorder_point),
       count(distinct supplier_lead_time_days)
from `logidistrib_dwh.stg_inventory_raw`
group by sku_id, warehouse_id



-- AXE 2 : les stocks dormants

/* on veux estimer le jour de couvertiure d'un produit
en faisant un rapport entre sa vietsse de vente repertorié sur un hsitorique ( un an dans le cas de nos données)
et son stcok le plus récent, pour dire en gros :
 Avec mon stock actuel, combient de jours il va tenir si ce rythme de vente se maintient ? */


-- classification des stocks actuels selon les dates décroissantes
with recent_inventory as (
     select sku_id,
            warehouse_id,
            inventory_level,
            date,
            unit_cost,
            row_number() over(partition by sku_id,warehouse_id order by date desc) as rang
      from `logidistrib_dwh.fact_daily_stock_movement`
),

-- vitesse moyenne de vente d'un produit
average_speed_stock as (
     select sku_id,
            warehouse_id,
            round(avg(units_sold), 2) as average_sales,
            -- ntile(3) permet de segmenter les lignes en 3 parties
            -- dans notre cas, on segmente les produits en fonction
            -- des vitesses moyennes décroiisantes : 1 pour rapide, 2 pour moyenne, 3 pour lente
            ntile(3) over (order by avg(units_sold) desc, sku_id asc) as sales_velocity
     from `logidistrib_dwh.fact_daily_stock_movement`
     group by sku_id, warehouse_id

),

-- calcul de la période de jours de couverture par produit et entrepot

recovery_days_query as (
       select rc.sku_id,
              rc.warehouse_id,
              -- Stock actuel : photo instantanée du jour le plus récent
              rc.inventory_level,
              -- prix d'achat coté fournisseur
              rc.unit_cost,
              -- Vitesse de vente moyenne sur 1 an, par SKU x Entrepôt
              asp.average_sales, 
              -- Distingue les produits jamais vendus (average_sales = 0)
              -- des produits avec un historique de vente réel.
              case when asp.average_sales = 0 then 'jamais vendu'
              else 'déjà vendu'
              end as sales_state,
           -- Jour de couverture = stock actuel / vitesse de vente moyenne.
           -- SAFE_DIVIDE évite que la requête plante en cas de division
           -- par zéro (produit jamais vendu) : renvoie NULL au lieu d'une erreur.
           -- FLOOR arrondit à l'entier inférieur, par prudence opérationnelle :
           -- mieux vaut sous-estimer le nombre de jours restants que le surestimer.
           floor(safe_divide(inventory_level, average_sales)) as recovery_days,
           asp.sales_velocity
       from recent_inventory as rc
       -- Jointure sur la granularité commune SKU x Entrepôt entre les 2 premières CTE
       join average_speed_stock as asp on rc.sku_id = asp.sku_id
       and rc.warehouse_id = asp.warehouse_id
       -- Ne garder que la ligne avec la date la plus récente par SKU x Entrepôt
       where rc.rang = 1
),

-- Calcul du seuil pour interpreter une période de jours de couvertures "inquiétantes"
-- chaque segment de sales_velocity contient une liste de valeurs de recovery days, 
-- les valeurs sont ordonnées, et on se positionne à 90% de cette distribution pour capturer les cas les plus élevés, 
-- et les 10 % restants sont le reste de la distribution
-- avec  des jours de couverture potentiellement élevés pour leurs segments respectifs, 
-- ce qui traduirait des jours de couverture inquiétants


threshold as (
       select sku_id,
              warehouse_id,
              inventory_level,
              average_sales,
              recovery_days,
              sales_velocity,
              unit_cost,
              round(inventory_level*unit_cost, 2) as total_stock_value,
       --  calcule du percentile à 90 de chaque groupe de sales_velocity
              percentile_cont(recovery_days, 0.9 ) over(partition by sales_velocity) as p90_segment
       from recovery_days_query

)


-- Dans la requete finale, on identifie reelement les stocks dormants

select sku_id,
       warehouse_id,
       inventory_level,
       average_sales,
       recovery_days,
       sales_velocity,
       unit_cost,
       p90_segment,
       total_stock_value,
       case when recovery_days is null then 'jamais vendu'
            when recovery_days > p90_segment then 'stock_dormant'
            else 'niveau normal'
       end as stock_status,
       
       case when recovery_days > p90_segment then total_stock_value
            else 0
       end as dormant_stock_value
from threshold
order by sales_velocity asc;











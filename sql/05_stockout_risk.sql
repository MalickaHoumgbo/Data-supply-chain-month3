-- analyse des ruptures de stocks
/* niveau 2 : phase d'alerte sur base de comparaison du stock actuel et du seuil de réapprovisionnement*/

-- identifier les produits d'entrepôt avec leur stock actuel 
--- et leur stock de réapprovisionnement côte à côte, suivant 
-- un ordre décroissant des dates auxquelles ils ont été enregistrés.
create view logidistrib_dwh.v_recent_inventory as 
          select sku_id,
                   warehouse_id,
                   date as snapshot_date,
                   inventory_level,
                   reorder_point,
                   row_number() over(partition by sku_id,warehouse_id order by date desc) as rang
          from `logidistrib_dwh.fact_daily_stock_movement`;
          
     
   
 
-- La deuxième récupère uniquement la première ligne d'un produit et de ses stocks
-- enregistré à sa date la plus recente, peu importe si une autre ligne partage cette même date
-- d'où le rang = 1

select sku_id,
       warehouse_id,
       inventory_level,
       reorder_point,
      case when inventory_level < reorder_point then 'warning'
           else 'OK'
      end as alerte
from `logidistrib_dwh.v_recent_inventory`
where rang = 1;

/* niveau 3 : anayse du diagnostic structurel du seuil de réapprovisionnement 
d'un produit par entrepot*/

-- calcul des métriques désignant l'écoulement previusionnel d'un stock de produits
--  sa vitesse moyenne de ventes journalière
-- le stock prévsionnel sucseptible d'etre ecoulé pendant le délai de reapprovisioneement

create view logidistrib_dwh.v_projected_stock_flow as 
          select sku_id,
                 warehouse_id,
                 reorder_point,
                 round(avg(units_sold), 2) as average_daily_sales,
                 round((supplier_lead_time_days * round(avg(units_sold), 2)), 2) as expected_demand
          from `logidistrib_dwh.fact_daily_stock_movement`
          group by sku_id, 
                    warehouse_id, 
                    supplier_lead_time_days, 
                    reorder_point;
        
     
     

/* comparaison entre le stock strucurel d'écoulement(expected_demand)
et le stock prévue pour déclancher une commande de réapprovisionnement(reorder_point)
un produit se retrouve avec un seuil de réapproviosnnement structurellement faible
si son reorder_point < à expected_demand
*/
select sku_id,
       warehouse_id,
       expected_demand,
       reorder_point,
       case when reorder_point < expected_demand then 'structurally low threshold'
            else 'ok'
       end as diagnostic
from  `logidistrib_dwh.v_projected_stock_flow`;


/* niveaux 2 et 3 combinés pour réperer les produits à niveau crituqe de stock.*/

-- une jointure est nécessaire entre les 2 tables intermediare
-- on veux regarder quels produits présentent à la fois une alerte de rupture probable(risque immédiat)
-- et un diagnostic structurel faible (risque structurel)
select psf.sku_id,
       psf.warehouse_id,
       rc.inventory_level,
       rc.reorder_point,
       psf.expected_demand,
       case 
          when rc.inventory_level < rc.reorder_point and rc.reorder_point < psf.expected_demand then 'risque critique'
          when rc.inventory_level < rc.reorder_point then 'risque immédiat'
          when rc.reorder_point < psf.expected_demand then 'risque structurel'
          else 'aucun risque'
       end as niveau_risque
from `logidistrib_dwh.v_projected_stock_flow` as psf
join `logidistrib_dwh.v_recent_inventory` as rc on  psf.sku_id = rc.sku_id
and psf.warehouse_id = rc.warehouse_id
where rc.rang = 1  /*on garde uniquement les produits avec leur plus récente date d'enregistrement
pour rester conforme aux conditions du risque immédiat */

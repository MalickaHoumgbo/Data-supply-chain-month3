-- Création de la tbles des mouvement des stocks


create table `logidistrib_dwh.fact_daily_stock_movement` as
select * from `logidistrib_dwh.stg_inventory_raw`;

-- clés etrangères pour relier aux tables des dimnsions

alter table `logidistrib_dwh.fact_daily_stock_movement`
add constraint fk_product foreign key (sku_id) references `logidistrib_dwh.dim_produit`(sku_id) not enforced,
add constraint fk_warehouse foreign key (warehouse_id) references `logidistrib_dwh.dim_entrepot`(warehouse_id) not enforced;


/*clé pimaire composite pour idenifier l'etat d'un stock d'un produit 
dans un entrpot un jour donné*/

alter table `logidistrib_dwh.fact_daily_stock_movement`
add primary key (date,sku_id,warehouse_id) not enforced;

-- verification de la taille de la table
select count(*) from `logidistrib_dwh.fact_daily_stock_movement`




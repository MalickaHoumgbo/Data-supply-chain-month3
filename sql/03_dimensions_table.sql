
-- création de la table des produits

create table `logidistrib_dwh.dim_produit` as
select distinct sku_id
from `logidistib-project.logidistrib_dwh.stg_inventory_raw`;

-- création de la table des entrepots

create table `logidistrib_dwh.dim_entrepot` as
select distinct warehouse_id
from `logidistib-project.logidistrib_dwh.stg_inventory_raw`;

/* déclaration des clés primaires*/

-- dimension produit

alter table `logidistrib_dwh.dim_produit`
add primary key (sku_id) not enforced;

select count(*),
       count(distinct sku_id)
from `logidistrib_dwh.dim_produit`;


-- dimension entrepot

alter table `logidistrib_dwh.dim_entrepot`
add primary key (warehouse_id) not enforced;

select count(*),
       count(distinct warehouse_id)
from `logidistrib_dwh.dim_entrepot`


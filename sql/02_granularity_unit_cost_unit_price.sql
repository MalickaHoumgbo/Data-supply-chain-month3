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
having count(distinct unit_price) > 1  

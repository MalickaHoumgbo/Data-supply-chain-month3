-- Table de staging : import brut du dataset nettoyé (post-EDA) au format Parquet
-- Schéma validé après correction du typage de la colonne date (voir journal des cicatrices)

CREATE TABLE `logidistib-project.logidistrib_dwh.stg_inventory_raw`
(
  date DATE,
  sku_id STRING,
  warehouse_id STRING,
  units_sold INT64,
  inventory_level INT64,
  supplier_lead_time_days INT64,
  reorder_point INT64,
  order_quantity INT64,
  unit_cost FLOAT64,
  unit_price FLOAT64
);
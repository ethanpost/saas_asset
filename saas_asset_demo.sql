create or replace view saas_asset_demo_v as (
select a.asset_name,
       a.asset_id,
       (select asset_type_name from saas_asset_types where asset_type_id=a.asset_type_id) asset_type_name,
       a.order_id,
       a.created,
       a.updated,
       a.asset_type_id,
       a.root_id,
       a.is_template
  from saas_asset a
 where a.is_active='y'
   and a.is_root_asset='y'
   and a.is_template='n');

create or replace view saas_asset_demo_detail_v as (
select a.*
  from saas_asset a
 where a.is_template='n'
   and a.is_active='y');

-- uninstall: drop context asset_demo;
create or replace context asset_demo using saas_asset_demo accessed globally;

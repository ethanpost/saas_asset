
-- uninstall: drop package saas_asset_pkg;
create or replace package saas_asset_pkg as 

   procedure raise_is_referenced_by_other_assets (
      p_asset_id in number);

   -- Renumber order_id for all assets for given root_id.
   procedure renum_all_assets (
      p_root_id in varchar2);

   procedure renum_asset_type (
      p_type_id in number,
      p_root_id in varchar2);

   function get_next_asset_relation_order_id (
      p_parent_id in varchar2) return number;

   function get_asset_id (
      p_name in varchar2,
      p_type in saas_asset_types%rowtype,
      p_root_id in varchar2) return number;
   
   procedure create_type (
      p_name in varchar2,
      p_root_id in varchar2,
      p_order_id in number default 0);

   function does_type_exist (
      p_name in varchar2,
      p_root_id in varchar2) return boolean;

   function get_asset_type (
      p_name in varchar2,
      p_root_id in varchar2) return saas_asset_types%rowtype;

   function get_asset_type_name_by_id (
      p_id number,
      p_root_id in varchar2) return varchar2;

   function get_asset_type_id_by_name (
      p_name in varchar2,
      p_root_id in varchar2) return varchar2;

   function get_type (
      p_name in varchar2,
      p_root_id in varchar2) return saas_asset_types%rowtype;

   function get_type_id (
      p_name in varchar2,
      p_root_id in varchar2) return number;

   procedure update_type (
      p_asset_type in saas_asset_types%rowtype);

   procedure raise_type_not_found(
      p_name in varchar2,
      p_root_id in varchar2);
  
   -- Create a new asset of the given type. 
   procedure create_asset (
      p_name in varchar2, 
      p_type_name in varchar2,
      p_root_id in varchar2);

   function create_asset (
      p_name in varchar2,
      p_type_name in varchar2,
      p_root_id in varchar2) return saas_asset%rowtype;

   -- Returns true if the asset exists. 
   function does_asset_exist (
      p_name in varchar2,
      p_type_name in varchar2,
      p_root_id in varchar2) return boolean;

   function get_asset (
      p_name in varchar2, 
      p_root_id in varchar2,
      p_type_name in varchar2) return saas_asset%rowtype;

   function get_asset_by_id (
      p_id in number) return saas_asset%rowtype;

   function save_asset (
      p_asset saas_asset%rowtype) return saas_asset%rowtype;

   procedure save_asset (
      p_asset saas_asset%rowtype);
   
   procedure validate_asset (
      p_label in varchar2,
      p_val in varchar2,
      p_id in number,
      p_id_type in varchar2,
      p_is_required in varchar2,
      p_is_optional in varchar2);

   procedure deep_copy_children_of (
      p_asset saas_asset%rowtype,
      p_to_new_parent saas_asset%rowtype,
      p_depth number default 0);

   procedure deep_copy (
      p_asset saas_asset%rowtype, 
      p_parent saas_asset%rowtype default null);

   -- Links an asset to another asset.
   procedure link_asset (
      p_child saas_asset%rowtype,
      p_parent saas_asset%rowtype);

end;
/

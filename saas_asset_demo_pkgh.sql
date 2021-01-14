create or replace package saas_asset_demo as 
   -- If you are using my saas_auth package it will find this
   -- procedure automatically and run it post auth.
   procedure post_auth;

   procedure add_asset_types;

   procedure create_asset (
   p_name in varchar2,
   p_root_id in varchar2 default null,
   p_type_id in number default null,
   p_type_name in varchar2 default null,
   p_skip_validate in varchar2 default 'n');
   
end;
/

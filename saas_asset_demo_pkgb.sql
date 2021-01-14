create or replace package body saas_asset_demo as 

procedure create_asset_type (
   p_name in varchar2, 
   p_root_id in varchar2, 
   p_order_id in number default 0) is
begin
   if not saas_asset_pkg.does_type_exist(p_name=>p_name, p_root_id=>p_root_id) then 
      saas_asset_pkg.create_type (
         p_name=>p_name, 
         p_root_id=>p_root_id, 
         p_order_id=>p_order_id);
   end if;
end;

procedure add_asset_types is 
   new_asset saas_asset%rowtype;
begin 
   if not saas_asset_pkg.does_type_exist(p_name=>'Fuel Types', p_root_id=>v('APP_USER')) then
      create_asset_type('Fuel Types', p_root_id=>v('APP_USER'), p_order_id=>20);
   end if;
   if not saas_asset_pkg.does_asset_exist(p_name=>'Fuel Type Template', p_type_name=>'Fuel Types', p_root_id=>v('APP_USER')) then 
      new_asset := saas_asset_pkg.create_asset(p_name=>'Fuel Type Template', p_type_name=>'Fuel Types', p_root_id=>v('APP_USER'));
      new_asset.is_template := 'y';
      new_asset.is_required1 := '#';
      new_asset.label1 := 'Price/Gal';
      saas_asset_pkg.save_asset(new_asset);
   end if;
   if not saas_asset_pkg.does_type_exist(p_name=>'Cars', p_root_id=>v('APP_USER')) then
      create_asset_type('Cars', p_root_id=>v('APP_USER'), p_order_id=>20);
   end if;
   if not saas_asset_pkg.does_asset_exist(p_name=>'Car Template', p_type_name=>'Cars', p_root_id=>v('APP_USER')) then 
      new_asset := saas_asset_pkg.create_asset(p_name=>'Car template', p_type_name=>'Cars', p_root_id=>v('APP_USER'));
      new_asset.is_template := 'y';
      new_asset.is_required1 := '#';
      new_asset.label1 := 'Year';
      new_asset.is_required2 := 'id';
      new_asset.id2_type := 'Fuel Types';
      new_asset.label2 := 'Fuel Type';
      saas_asset_pkg.save_asset(new_asset);
   end if;
end;

procedure post_auth is 
   n number;
   v_client_id varchar2(200);
begin 
   if v('APP_USER') = 'nobody' then 
      -- This is happening post auth so APP_USER should never be nobody at this point.
      raise_application_error(-20001, 'Application user is still set to nobody!');
   end if;
   -- https://jeffkemponoracle.com/2013/02/apex-and-application-contexts/
   v_client_id := replace(
      sys_context('userenv','client_identifier'), 'nobody', v('APP_USER'));
   -- We use this sys_context in the Sass Asset Demo list object. This is used
   -- to limit the asset types in the left sidebar to those that belong to a 
   -- particular user. You can limit by other attributes also, like a group or
   -- role. There is a lot of flexibility here.
   arcsql.set_sys_context(
      p_namespace=>'asset_demo',
      p_attribute=>'app_user',
      p_value=>v('APP_USER'),
      p_client_id=>v_client_id);
   add_asset_types;
exception 
   when others then 
      raise;
end;

function get_template_id (
   p_type_id in number,
   p_root_id in varchar2 default null) return number is 
   r number;
   v_id varchar2(120) := p_root_id;
begin 
   arcsql.debug('get_template_id: p_type_id='||p_type_id||' p_root_id='||p_root_id);
   if v_id is null then 
      v_id := sys_context('saas_asset', 'app_user');
   end if;
   select asset_id into r from saas_asset
    where root_id=v_id
      and asset_type_id=p_type_id 
      and is_template='y'
      and is_root_asset='y';
   arcsql.debug('get_template_id: r='||r);
   return r;
end;

function get_next_asset_order_id (
   p_type_id in varchar2,
   p_root_id in varchar2) return number is 
   n number;
   r number;
begin 
   select nvl(max(order_id), 0) into n 
     from saas_asset 
    where root_id=sys_context('saas_asset', 'app_user')
      and asset_type_id=p_type_id 
      and is_active='y'
      and is_template='n'
      and is_root_asset='y';
   r := mod(n, 10);
   n := n + (10-r);
   return n;
end;

function create_asset (
   p_name in varchar2,
   p_root_id in varchar2 default null,
   p_type_id in number default null,
   p_type_name in varchar2 default null,
   p_skip_validate in varchar2 default 'n') return saas_asset%rowtype is  
   -- Creates a new asset with provided name using the template for the given asset type.
   v_new_asset saas_asset%rowtype;
   v_type_id number := p_type_id;
   v_template_id number;
   v_root_id varchar2(120);
begin 
   arcsql.debug('create_asset(f): '||p_name||', root_id='||p_root_id||', type_id='||p_type_id||', type_name='||p_type_name||', skip='||p_skip_validate);
   if p_name is null then 
      raise_application_error(-20001, 'Please provide an name for the new asset.');
   end if;
   v_root_id := nvl(p_root_id, sys_context('saas_asset', 'app_user'));
   if v_type_id is null then 
      v_type_id := saas_asset_pkg.get_asset_type_id_by_name(p_name=>p_type_name, p_root_id=>v_root_id);
   end if;
   v_template_id := get_template_id(p_type_id=>v_type_id, p_root_id=>v_root_id);
   v_new_asset := saas_asset_pkg.get_asset_by_id(v_template_id);
   v_new_asset.asset_name := p_name;
   v_new_asset.is_root_asset := 'y';
   v_new_asset.allow_delete := 'y';
   v_new_asset.is_template := 'n';
   v_new_asset.order_id := get_next_asset_order_id(p_type_id=>v_new_asset.asset_type_id, p_root_id=>v_new_asset.root_id);
   v_new_asset.asset_id := null;
   -- Used when generating templates/incomplete records.
   v_new_asset.skip_validate := p_skip_validate;
   return saas_asset_pkg.save_asset(v_new_asset);
end;

procedure create_asset (
   p_name in varchar2,
   p_root_id in varchar2 default null,
   p_type_id in number default null,
   p_type_name in varchar2 default null,
   p_skip_validate in varchar2 default 'n') is 
   -- Creates a new asset with provided name using the template for the given asset type.
   v_new_asset saas_asset%rowtype;
   v_type_id number := p_type_id;
   v_template_id number;
begin 
   arcsql.debug('create_asset(p): '||p_name||', root_id='||p_root_id||', type_id='||p_type_id||', type_name='||p_type_name||', skip='||p_skip_validate);
   v_new_asset := create_asset(
      p_name=>p_name,
      p_root_id=>p_root_id,
      p_type_id=>p_type_id,
      p_type_name=>p_type_name,
      p_skip_validate=>p_skip_validate);
end;

end;
/

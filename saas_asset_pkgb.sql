create or replace package body saas_asset_pkg as 

procedure raise_is_referenced_by_other_assets (
   p_asset_id in number) is 
   n number;
begin
   select count(*) into n from saas_asset 
    where p_asset_id in (id1, id2, id3, id4, id5, id6, id7, id8, id9, id10, id11,
      id12, id13, id14, id15, id16, id17, id18, id19, id20)
      and asset_id != p_asset_id;
   if n > 0 then 
      raise_application_error(-20001, 'This asset is referenced by other assets. Please must delete those assets first.');
   end if;
end;

procedure renum_all_assets (
   p_root_id in varchar2) is
   cursor asset_types is 
   -- Renumber order_id for all assets within the given root_id.
   select asset_type_id 
     from saas_asset_types 
    where root_id=p_root_id;
begin
   -- Order should be within the type, so loop through each type and do the order operation.
   for x in asset_types loop 
      renum_asset_type (
         p_type_id=>x.asset_type_id,
         p_root_id=>p_root_id);
   end loop;
end;

procedure renum_asset_type (
   p_type_id in number,
   p_root_id in varchar2) is 
   -- Renumbers the assets within given type and root_id.
   cursor assets is 
   select * from saas_asset 
    where root_id=p_root_id
      and asset_type_id=p_type_id
      and is_active='y'
      and is_template='n'
      and is_root_asset='y'
    order by order_id, created;
   o number := 0;
begin 
   for x in assets loop 
      o := o + 10;
      update saas_asset set order_id=o, skip_validate='y' where asset_id=x.asset_id;
   end loop;
end;

procedure renum_asset_relation (
   p_parent_id in number,
   p_root_id in varchar2) is 
   cursor asset_relation is 
   -- Renumber the order_id for assets belonging to same parent in saas_asset_relation.
   select * from saas_asset_relation 
    where parent_asset_id=p_parent_id;
   o number := 0;
begin 
   for x in asset_relation loop 
      o := o + 10;
      update saas_asset_relation 
         set order_id=o 
       where parent_asset_id=x.parent_asset_id 
         and child_asset_id=x.child_asset_id;
   end loop;
end;

function get_next_asset_relation_order_id (
   p_parent_id in varchar2) return number is 
   -- Returns next order_id for a new asset before saas_asset_relation table insert.
   n number;
   r number;
begin 
   select nvl(max(order_id), 0) into n 
     from saas_asset_relation
    where parent_asset_id=p_parent_id
      and is_active='y';
   r := mod(n, 10);
   n := n + (10-r);
   return n;
end;

function get_asset_id (
   p_name in varchar2,
   p_type in saas_asset_types%rowtype,
   p_root_id in varchar2) return number is 
   n number;
begin 
   select count(*) into n 
     from saas_asset 
    where asset_name=p_name 
      and root_id=p_root_id;
   if n = 1 then 
      select asset_id into n 
        from saas_asset 
       where asset_name=p_name 
         and asset_type_id=p_type.asset_type_id
         and root_id=p_root_id;
   else 
      select asset_id into n 
        from saas_asset 
       where asset_name=p_name 
         and asset_type_id=p_type.asset_type_id
         and root_id=p_root_id 
         and is_root_asset='y';
   end if;
   return n;
end;

procedure raise_type_not_found (
   p_name in varchar2,
   p_root_id in varchar2) is 
begin 
   if not does_type_exist(p_name=>p_name, p_root_id=>p_root_id) then 
      raise_application_error(-20001, 'Asset type not found: '||p_name||', '||p_root_id);
   end if;
end;

procedure create_type (
   p_name in varchar2,
   p_root_id in varchar2,
   p_order_id in number default 0) is 
begin 
   insert into saas_asset_types (
      asset_type_name,
      root_id,
      order_id) values (
      p_name,
      p_root_id,
      p_order_id);
end;

procedure update_type (
   p_asset_type in saas_asset_types%rowtype) is
   v_asset_type saas_asset_types%rowtype := p_asset_type;
begin 
   if does_type_exist(p_name=>v_asset_type.asset_type_name, p_root_id=>v_asset_type.root_id) then 
      v_asset_type.updated := sysdate;
      update saas_asset_types set row=v_asset_type where asset_type_id=v_asset_type.asset_type_id;
   end if;
end;

function get_type (
   p_name in varchar2,
   p_root_id in varchar2) return saas_asset_types%rowtype is 
   t saas_asset_types%rowtype;
begin 
   raise_type_not_found(p_name=>p_name, p_root_id=>p_root_id);
   select * into t from saas_asset_types 
    where asset_type_name=p_name 
      and root_id=p_root_id;
   return t;
end;

function get_type_by_id (p_id in number) return saas_asset_types%rowtype is 
   t saas_asset_types%rowtype;
begin 
   select * into t 
     from saas_asset_types
    where asset_type_id=p_id;
    return t;
end;

function get_type_id (
   p_name in varchar2,
   p_root_id in varchar2) return number is 
   n number;
begin 
   raise_type_not_found(p_name=>p_name, p_root_id=>p_root_id);
   select asset_type_id into n 
     from saas_asset_types 
    where asset_type_name=p_name 
      and root_id=p_root_id;
   arcsql.debug('get_type_id: n='||n);
   return n;
end;

function does_type_exist (
   p_name in varchar2,
   p_root_id in varchar2) return boolean is 
   n number;
begin 
   select count(*) into n 
     from saas_asset_types 
    where asset_type_name=p_name 
      and root_id=p_root_id;
   if n > 0 then 
      return true;
   else 
      return false;
   end if;
end;

function get_asset_type (
   p_name in varchar2,
   p_root_id in varchar2) return saas_asset_types%rowtype is 
   v_asset_type saas_asset_types%rowtype;
begin 
   select * into v_asset_type 
     from saas_asset_types 
    where asset_type_name=p_name 
      and root_id=p_root_id;
   return v_asset_type;
end;

function get_asset_type_name_by_id (
   p_id number,
   p_root_id in varchar2) return varchar2 is 
   v varchar2(120);
begin 
   arcsql.debug('get_asset_type_name_by_id: '||p_id||'~'||p_root_id);
   select asset_type_name into v 
     from saas_asset_types  
    where root_id=p_root_id 
      and asset_type_id=p_id;
   return v;
end;

function get_asset_type_id_by_name (
   p_name in varchar2,
   p_root_id in varchar2) return varchar2 is 
   n number;
begin 
   arcsql.debug('get_asset_type_id_by_name: '||p_name||', '||p_root_id);
   select asset_type_id into n 
     from saas_asset_types
    where root_id=p_root_id 
      and asset_type_name=p_name;
   return n;
end;

function get_asset (
   p_name in varchar2, 
   p_root_id in varchar2,
   p_type_name in varchar2) return saas_asset%rowtype is 
   r saas_asset%rowtype;
   v_asset_type saas_asset_types%rowtype;
begin 
   v_asset_type := get_asset_type(p_name=>p_type_name, p_root_id=>p_root_id);
   select * into r 
     from saas_asset 
    where asset_name=p_name 
      and root_id=p_root_id
      and asset_type_id=v_asset_type.asset_type_id;
   return r;
exception 
   when others then 
      raise_application_error(-20001, 'get_asset: '||p_name||': '||dbms_utility.format_error_stack);
end;

function get_asset_by_id (
   p_id in number) return saas_asset%rowtype is  
   r saas_asset%rowtype;
   v_root_id varchar2(120) := p_id;
begin 
   arcsql.debug('get_asset_id: '||p_id);
   select * into r 
     from saas_asset 
    where asset_id=p_id;
   return r;
exception 
   when others then 
      raise_application_error(-20001, 'get_asset_by_id: '||p_id||': '||dbms_utility.format_error_stack);
end;

procedure create_asset (
   p_name in varchar2, 
   p_type_name in varchar2,
   p_root_id in varchar2) is 
   v_asset saas_asset%rowtype;
begin 
   arcsql.debug('create_asset(p): '||p_name||'~'||p_type_name||'~'||p_root_id);
   v_asset := create_asset(p_name=>p_name, p_type_name=>p_type_name, p_root_id=>p_root_id);
exception 
  when others then 
     arcsql.debug('create_asset(p): '||dbms_utility.format_error_stack);
     raise;
end;

function create_asset (
   p_name in varchar2,
   p_type_name in varchar2,
   p_root_id in varchar2) return saas_asset%rowtype is 
   v_asset_type saas_asset_types%rowtype;
   v_new_asset_id number;
begin 
   arcsql.debug('create_asset(f): '||p_name||'~'||p_type_name||'~'||p_root_id);
   v_asset_type := get_asset_type(p_name=>p_type_name, p_root_id=>p_root_id);
   insert into saas_asset (
      asset_id,
      asset_name,
      asset_type_id,
      root_id) values (
      seq_saas_asset_id.nextval,
      p_name,
      v_asset_type.asset_type_id,
      p_root_id) returning asset_id into v_new_asset_id;
   return get_asset_by_id(p_id=>v_new_asset_id);
exception 
  when others then 
     arcsql.debug('create_asset(f): '||dbms_utility.format_error_stack);
     raise;
end;

function copy_asset (
   p_asset in saas_asset%rowtype) return saas_asset%rowtype is 
   v_asset saas_asset%rowtype := p_asset;
   new_asset saas_asset%rowtype;
begin 
   v_asset.asset_id := null;
   v_asset.is_root_asset := 'n';
   v_asset.is_template := 'n';
   v_asset.allow_delete := 'y';
   new_asset := save_asset(v_asset);
   return new_asset;
end;

procedure deep_copy_children_of (
   p_asset saas_asset%rowtype,
   p_to_new_parent saas_asset%rowtype,
   p_depth number default 0) is
   cursor children is 
   select child_asset_id
     from saas_asset_relation
    where parent_asset_id=p_asset.asset_id;
   current_child varchar2(120);
   current_asset saas_asset%rowtype;
   new_asset saas_asset%rowtype;
begin 
   -- arcsql.debug('deep_copy_children: '||p_asset_id||', '||p_new_parent_id||', '||p_depth);
   if p_depth > 5 then 
      raise_application_error(-20001, 'deep_copy_children: Depth too deep to copy.');
   end if;
   for c in children loop 
      arcsql.debug('p_new_parent_id is = '||p_to_new_parent.asset_id);
      -- Load the child of p_children_of.
      current_asset := get_asset_by_id(c.child_asset_id);
      new_asset := copy_asset(current_asset);
      -- Now link the new child to the new parent in the saas_relations table.
      -- arcsql.debug('p_new_parent_id is now = '||p_new_parent_id);
      -- link_asset(p_parent_id=>p_new_parent_id, p_child_id=>g.asset_id);
      link_asset(p_child=>new_asset, p_parent=>p_to_new_parent);
      -- If the original child has children we need to recurse here to get them.
      deep_copy_children_of (
         p_asset=>current_asset,
         p_to_new_parent=>new_asset,
         p_depth=>p_depth+1);
   end loop;
end;

procedure copy_asset_references (
   p_asset in saas_asset%rowtype) is 
begin 
   null;
end;

procedure deep_copy (
   p_asset saas_asset%rowtype, 
   p_parent saas_asset%rowtype default null) is
   new_asset saas_asset%rowtype;
begin 
   -- arcsql.debug('deep_copy: '||p_asset_id);
   new_asset := copy_asset(p_asset);
   deep_copy_children_of (
      p_asset=>p_asset, 
      p_to_new_parent=>new_asset);
   if not p_parent.asset_id is null then 
      link_asset(p_child=>new_asset, p_parent=>p_parent);
   end if;
end;

function save_asset (
   p_asset saas_asset%rowtype) return saas_asset%rowtype is 
   r saas_asset%rowtype;
   v_asset saas_asset%rowtype := p_asset;
begin 
   arcsql.debug('save_asset(f): '||p_asset.asset_id);
   if not v_asset.asset_id is null then
      update saas_asset set row=v_asset where asset_id=v_asset.asset_id;
   else 
      v_asset.asset_id := seq_saas_asset_id.nextval;
      insert into saas_asset values v_asset;
      arcsql.debug('save_asset(f): asset_id='||v_asset.asset_id);
   end if;
   r := get_asset_by_id(v_asset.asset_id);
   return r;
end;

procedure save_asset (
   p_asset saas_asset%rowtype) is 
   new_asset saas_asset%rowtype;
begin 
   arcsql.debug('save_asset(p): '||p_asset.asset_id);
   new_asset := save_asset(p_asset=>p_asset);
end;

function is_value_required (
   p_is_required varchar2) return boolean is 
begin
   if trim(p_is_required) is null then
      return false;
   end if;
   if lower(p_is_required) in ('n', 'id') then 
      return false;
   end if;
   return true;
end;

function is_id_required (
   p_is_required varchar2) return boolean is 
begin
   if lower(p_is_required) in ('id') then 
      return true;
   end if;
   return false;
end;

procedure validate_asset (
   p_label in varchar2,
   p_val in varchar2,
   p_id in number,
   p_id_type in varchar2,
   p_is_required in varchar2,
   p_is_optional in varchar2) is 
   -- Called from a trigger. Validate is disabled if 'y' in skip_validate or is_template.
   v_is_required varchar2(120) := nvl(lower(p_is_required), 'n');
   v_is_optional varchar2(120) := nvl(lower(p_is_optional), 'n');
   n number;
   d date;
begin 
   arcsql.debug('validate_asset: p_label='||p_label||', v_is_required='||v_is_required);
   if is_id_required(v_is_required) then 
      if trim(p_id) is null then 
         raise_application_error(-20001, 'Select a value for '''||p_label||'''.');
      end if;
   end if;
   if is_value_required(v_is_required) then 
      if trim(p_val) is null then 
         raise_application_error(-20001, 'A value is required for '''||p_label||'''.');
      end if;
      if v_is_required in ('yn') and lower(p_val) not in ('y', 'n') then 
         raise_application_error(-20001, '''y'' or ''n'' is expected for '''||p_label||'''.');
      end if;
      if v_is_required in ('#') then 
         begin
            n := to_number(trim(p_val));
         exception 
            when others then 
               raise_application_error(-20001, 'A number is expected for '''||p_label||'''.');
         end;
      end if;
      if instr(v_is_required, 'yy') > 0 or instr(v_is_required, 'dd') > 0 or instr(v_is_required, 'mm') > 0 then
         begin
            arcsql.debug('validate_asset: p_val='||p_val||', v_is_required='||v_is_required);
            d := to_date(p_val, v_is_required);
         exception 
            when others then 
               raise_application_error(-20001, 'Invalid date format '''||p_label||'''.');
         end;
      end if; 
   end if;
   if v_is_optional in ('yn') and nvl(trim(lower(p_val)), 'y') not in ('y', 'n') then  
      raise_application_error(-20001, '''y'' or ''n'' is expected for '''||p_label||'''.');
   end if;
   if v_is_optional in ('#') and not trim(p_val) is null then 
      begin
         n := to_number(trim(p_val));
      exception 
         when others then 
            raise_application_error(-20001, 'A number is expected for '''||p_label||'''.');
      end;
   end if;
   if instr(v_is_optional, 'yy') > 0 or instr(v_is_optional, 'dd') > 0 or instr(v_is_optional, 'mm') > 0 then
      begin
         d := to_date(p_val, v_is_optional);
      exception 
         when others then 
            raise_application_error(-20001, 'Invalid date format '''||p_label||'''.');
      end;
   end if; 
end;

function does_asset_exist (
   p_name in varchar2,
   p_type_name in varchar2,
   p_root_id in varchar2) return boolean is 
   asset_id number;
   v_asset_type saas_asset_types%rowtype;
begin 
   begin 
      v_asset_type := get_asset_type(p_name=>p_type_name, p_root_id=>p_root_id);
      asset_id := get_asset_id(p_name=>p_name, p_type=>v_asset_type, p_root_id=>p_root_id);
   exception
      when no_data_found then 
         return false;
      when others then 
         raise;
   end;
   return true;
end;

procedure link_asset (
   p_child saas_asset%rowtype,
   p_parent saas_asset%rowtype) is 
   o number;
begin
   arcsql.debug('link_asset: '||p_parent.asset_id||', '||p_child.asset_id);
   o := get_next_asset_relation_order_id(p_parent_id=>p_parent.asset_id);
   insert into saas_asset_relation (
      parent_asset_id,
      child_asset_id,
      order_id) values (
      p_parent.asset_id,
      p_child.asset_id,
      o);
end;

end;
/

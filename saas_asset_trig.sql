
create or replace trigger saas_asset_delete 
   before delete on saas_asset for each row 
declare 
   pragma autonomous_transaction;
begin
   saas_asset_pkg.raise_is_referenced_by_other_assets(:old.asset_id);
end;
/

create or replace trigger saas_asset_insert_update
   before insert or update
   on saas_asset
   for each row
begin 
   if updating or inserting then 
      if 'y' in (:new.skip_validate, :new.is_template) then 
         :new.skip_validate := 'n';
      else 
         -- arcsql.debug(:new.label1||'~'||:new.val1||'~'||:new.id1||'~'||:new.id1_type||'~'||:new.is_required1||'~'||:new.is_optional1);
         saas_asset_pkg.validate_asset(p_label=>:new.label1, p_val=>:new.val1, p_id=>:new.id1, p_id_type=>:new.id1_type, 
         p_is_required=>:new.is_required1, p_is_optional=>:new.is_optional1);
         saas_asset_pkg.validate_asset(p_label=>:new.label2, p_val=>:new.val2, p_id=>:new.id2, p_id_type=>:new.id2_type, 
         p_is_required=>:new.is_required2, p_is_optional=>:new.is_optional2);
         saas_asset_pkg.validate_asset(p_label=>:new.label3, p_val=>:new.val3, p_id=>:new.id3, p_id_type=>:new.id3_type, 
         p_is_required=>:new.is_required3, p_is_optional=>:new.is_optional3);
         saas_asset_pkg.validate_asset(p_label=>:new.label4, p_val=>:new.val4, p_id=>:new.id4, p_id_type=>:new.id4_type, 
         p_is_required=>:new.is_required4, p_is_optional=>:new.is_optional4);
         saas_asset_pkg.validate_asset(p_label=>:new.label5, p_val=>:new.val5, p_id=>:new.id5, p_id_type=>:new.id5_type, 
         p_is_required=>:new.is_required5, p_is_optional=>:new.is_optional5);
         saas_asset_pkg.validate_asset(p_label=>:new.label6, p_val=>:new.val6, p_id=>:new.id6, p_id_type=>:new.id6_type, 
         p_is_required=>:new.is_required6, p_is_optional=>:new.is_optional6);
         saas_asset_pkg.validate_asset(p_label=>:new.label7, p_val=>:new.val7, p_id=>:new.id7, p_id_type=>:new.id7_type, 
         p_is_required=>:new.is_required7, p_is_optional=>:new.is_optional7);
         saas_asset_pkg.validate_asset(p_label=>:new.label8, p_val=>:new.val8, p_id=>:new.id8, p_id_type=>:new.id8_type, 
         p_is_required=>:new.is_required8, p_is_optional=>:new.is_optional8);
         saas_asset_pkg.validate_asset(p_label=>:new.label9, p_val=>:new.val9, p_id=>:new.id9, p_id_type=>:new.id9_type, 
         p_is_required=>:new.is_required9, p_is_optional=>:new.is_optional9);
      end if;
   end if;
   if inserting then
      if :new.asset_id is null then 
         :new.asset_id := seq_saas_asset_id.nextval;
      end if;
      :new.created := sysdate;
      :new.created_by := nvl(sys_context('apex$session','app_user'), user);
   end if;
   :new.updated := sysdate;
   :new.updated_by := nvl(sys_context('apex$session','app_user'), user);
end;
/


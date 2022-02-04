-----DDL Statements to Create the source tables-----
---Table Prod_family
create sequence sqc_prod_dim
start with 1
increment by 1;

Create table prod_family
(
prod_fam_id integer,
prod_fam_short_desc varchar(30),
prod_fam_long_desc varchar(50),
crt_date date,
upd_date date);

insert into prod_family values(1,'Electronics','Electronics and Gadgets',sysdate-20,null);
select * from prod_cat;
---Table Prod_cate
Create table prod_cat
(
prod_cat_id integer not null,
prod_fam_id integer,
prod_cat_short_desc varchar(30),
prod_cat_long_desc varchar(50),
crt_date date,
upd_date date
);

Insert into prod_cat values(10,1,'Computers','Conputers and Supporting Devices',sysdate-10,null);

---Table Product
Create table product
(
prod_id integer not null,
prod_name varchar(30),
prod_price integer,
prod_cat_id integer,
crt_date date,
upd_date date
);
insert into product values(102,'Monitor',8000,10,sysdate,null);
insert into product values(100,'Monitor',8000,10,sysdate,null);
insert into product values(101,'Keyboard',800,10,sysdate,null);

-----DDL Statements to Create the source tables-----
---Table Prod_dim



Create table prod_dim_SCD1
(
prod_id number(8),
prod_nm varchar(30),
prod_cat varchar(30),
prod_family varchar(30),
prod_price number(7,2),
start_date date,
end_date date
);
------------------SCD1--------------------
create or replace procedure proc_SCD1
as    
    cursor cur_scd1 is
        select  p.prod_id as prod_id,
                p.prod_name as prod_name,
                pc.prod_cat_short_desc as prod_cat,
                pf.prod_fam_short_desc as prod_fam,
                p.prod_price as prod_price,
                pf.crt_date as create_date
        from    product p join prod_cat pc on p.prod_cat_id = pc.prod_cat_id join prod_family pf on pc.prod_fam_id = pf.prod_fam_id;
    v_count number;
Begin
     for i in cur_scd1 loop
        select count(*) into v_count from prod_dim_scd1 where prod_id = i.prod_id;
        if v_count = 0 then
            insert into prod_dim_scd1 values (i.prod_id,i.prod_name,i.prod_cat,i.prod_fam,i.prod_price,i.create_date,sysdate);
        else
            update prod_dim_scd1 set prod_price=i.prod_price, start_date = i.create_date, end_date = sysdate where prod_id=i.prod_id ;
        end if;
    commit;
    end loop;
End proc_SCD1;

execute proc_SCD1;
select * from prod_dim_scd1;
update product set prod_price = 8000 where prod_id = 100;



Create table prod_dim_SCD2
(
prod_sur_id number(8) primary key,
prod_id number(8),
prod_nm varchar(30),
prod_cat varchar(30),
prod_family varchar(30),
prod_price number(7,2),
start_date date,
end_date date
);
------------------SCD2--------------------
create or replace procedure proc_SCD2
as    
    cursor cur_source is
        select  p.prod_id as prod_id,
                p.prod_name as prod_name,
                pc.prod_cat_short_desc as prod_cat,
                pf.prod_fam_short_desc as prod_fam,
                p.prod_price as prod_price,
                pf.crt_date as create_date
        from    product p join prod_cat pc on p.prod_cat_id = pc.prod_cat_id join prod_family pf on pc.prod_fam_id = pf.prod_fam_id;
    cursor cur_target is (select PROD_SUR_ID, PROD_ID, PROD_NM, PROD_CAT, PROD_FAMILY, PROD_PRICE, START_DATE, END_DATE from prod_dim_scd2);
    v_count number;
    v_count1 number;
Begin
     for i in cur_source loop
        select count(*) into v_count from prod_dim_scd2 where prod_id = i.prod_id;
        if v_count = 0 then
            insert into prod_dim_scd2 values (sqc_prod_dim.nextval,i.prod_id,i.prod_name,i.prod_cat,i.prod_fam,i.prod_price,i.create_date,sysdate);
        else
            select count(*) into v_count1 from prod_dim_scd2 
            where prod_id = i.prod_id and prod_price <> i.prod_price and end_date = (select max(end_date) from prod_dim_scd2 where prod_id=i.prod_id);
            if v_count1 >=1 then
                insert into prod_dim_scd2 values (sqc_prod_dim.nextval,i.prod_id,i.prod_name,i.prod_cat,i.prod_fam,i.prod_price,i.create_date,sysdate);
            end if;
        end if;
    commit;
    end loop;
End proc_SCD2;

execute proc_SCD2;
select * from prod_dim_scd2;
update product set prod_price = 8000 where prod_id = 100;


Create table prod_dim_SCD3
(
prod_id number(8),
prod_nm varchar(30),
prod_cat varchar(30),
prod_family varchar(30),
prod_price number(7,2),
start_date date,
end_date date
);
------------------SCD3--------------------
create or replace procedure proc_SCD3
as    
    cursor cur_scd3 is
        select  p.prod_id as prod_id,
                p.prod_name as prod_name,
                pc.prod_cat_short_desc as prod_cat,
                pf.prod_fam_short_desc as prod_fam,
                p.prod_price as prod_price,
                pf.crt_date as create_date
        from    product p join prod_cat pc on p.prod_cat_id = pc.prod_cat_id join prod_family pf on pc.prod_fam_id = pf.prod_fam_id;
    v_count number;
    v_ddl varchar(1000);
Begin
    SELECT COUNT(*) into v_count FROM USER_TAB_COLUMNS WHERE upper(TABLE_NAME) = upper('PROD_DIM_SCD3') AND upper(COLUMN_NAME) IN (upper('old_prod_price') ,upper('old_start_date'),upper('old_end_date') );
--    if v_count = 0 then
--        v_ddl := 'alter table prod_dim_scd3 add  (old_prod_price number(7,2), old_start_date date, old_end_date date)';
--        execute immediate v_ddl;
--    end if;
     for i in cur_scd3 loop
        select count(*) into v_count from prod_dim_scd3 where prod_id = i.prod_id;
        if v_count = 0 then
            insert into prod_dim_scd3 values (i.prod_id,i.prod_name,i.prod_cat,i.prod_fam,i.prod_price,i.create_date,sysdate,null,null,null);
        else
            update prod_dim_scd3 set prod_price = i.prod_price, old_prod_price=prod_price, start_date =  i.create_date,old_start_date =start_date,end_date = i.create_date, old_end_date =end_date where prod_id = i.prod_id ;
        end if;
    commit;
    end loop;
End proc_SCD3;


execute proc_SCD3;
select * from prod_dim_scd3;
update product set prod_price = 800 where prod_id = 100;


set serveroutput on;
--select distinct table_name from user_tab_columns;
--
--alter table prod_dim_scd3 drop (prod_sur_id);
rollback;


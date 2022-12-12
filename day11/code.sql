--not going to bother to parse this input...
--store the rules for each monkey
create table rules (monkey int, op text, div int, t int, f int);
insert into rules values (0, '* 11', 7, 6,7), 
                         (1, '* 17', 13,5,2), 
                         (2, '+ 8',  5, 4,5), 
                         (3, '+ 3',  19,6,0),
                         (4, '+ 4',  2, 0,3),
                         (5, '+ 7',  11,3,4),
                         (6, '* old',17,1,7),
                         (7, '+ 6',  3, 2,1);

--store what the monkeys are holding
create table holding (rnd int, monkey int, items bigint[]);
--setup the initial holding values
insert into holding values (1,0,array[66,79]),
                           (1,1,array[84,94,94,81,98,75]),
                           (1,2,array[85,79,59,64,79,95,67]),
                           (1,3,array[70]),
                           (1,4,array[57,69,78,78]),
                           (1,5,array[65,92,60,74,72]),
                           (1,6,array[77,91,91]),
                           (1,7,array[76,58,57,55,67,77,54,99]);

--store what each monkey inspects
create table inspected (rnd int, monkey int, item numeric);

--part 1
create or replace function throw(r int) returns int
    language plpgsql
as
$$
declare
    m record;
    t bigint[];
    operation text;
    division int;
    t_monkey int;
    f_monkey int;
    w bigint;
    modw int;
begin
    for m in 0..7 loop
        select items into t from holding where monkey = m;
     
        select r.op, r.div, r.t, r.f into operation, division, t_monkey, f_monkey from rules r where monkey = m;
                
        -- if t is empty continue
        if array_ndims(t) is null then
            continue ;
        end if;
        for i in 1..array_upper(t, 1) loop
            --monkey inspecting
            insert into inspected values (r, m, t[i]);

            --run op
            execute 'select ' || t[i]::bigint || '::bigint ' || replace(operation,'old'::text, t[i]::text) into w;
            w := w / 3;
            modw = mod(w, division);
            
            if modw = 0 then
                update holding set items = array_append(items, w) where monkey = t_monkey;
            else
                update holding set items = array_append(items, w) where monkey = f_monkey;
            end if;

            --remove item from monkey
            update holding set items = items[2:] where monkey = m;
        end loop;
    end loop;
    return 0;
end;
$$;

--run 20 rounds
select throw(g) from generate_series(1, 20) as g;
--answer
select s from (
    select c * lag(c) over () as s
    from (
        select count(*) as c from inspected group by monkey order by 1 desc limit 2
    ) a) a 
where s is not null;

--part 2
--need to find least common multiple of the monkeys division values
--since it is constant no need to calculate it for each round, just
--find it and hard code it
--the builtin lcm() func only takes 2 parameters and there is no aggregate
--version, but we can build it up with a recursive CTE
with recursive c as (
    select monkey, div from rules
    union all
    select rules.monkey, lcm(c.div,rules.div)
    from rules join c on rules.monkey = c.monkey + 1
)
select max(div) from c;

--reset state
truncate table inspected;
truncate table holding;
insert into holding values (1,0,array[66,79]),
                           (1,1,array[84,94,94,81,98,75]),
                           (1,2,array[85,79,59,64,79,95,67]),
                           (1,3,array[70]),
                           (1,4,array[57,69,78,78]),
                           (1,5,array[65,92,60,74,72]),
                           (1,6,array[77,91,91]),
                           (1,7,array[76,58,57,55,67,77,54,99]);

--hard code the value into the function and remove the division by 3
--otherwise the same
create or replace function throw(r int) returns int
    language plpgsql
as
$$
declare
    m record;
    t bigint[];
    operation text;
    division int;
    t_monkey int;
    f_monkey int;
    w bigint;
    modw int;
begin
    for m in 0..7 loop
        select items into t from holding where monkey = m;
     
        select r.op, r.div, r.t, r.f into operation, division, t_monkey, f_monkey from rules r where monkey = m;
                
        -- if t is empty continue
        if array_ndims(t) is null then
            continue ;
        end if;
        for i in 1..array_upper(t, 1) loop
            --monkey inspecting
            insert into inspected values (r, m, t[i]);

            --run op
            execute 'select ' || t[i]::bigint || '::bigint ' || replace(operation,'old'::text, t[i]::text) into w;
            --hard coded LCM
            w := mod(w, 9699690);
            modw = mod(w, division);
            
            if modw = 0 then
                update holding set items = array_append(items, w) where monkey = t_monkey;
            else
                update holding set items = array_append(items, w) where monkey = f_monkey;
            end if;

            --remove item from monkey
            update holding set items = items[2:] where monkey = m;
        end loop;
    end loop;
    return 0;
end;
$$;

--can't run this as above for 10000 in one transaction, gets slow,
--run each round in its own transaction by generating each round as 
--statement then running file
\copy (select 'select throw(' || g || ');commit;' from generate_series(1,10000)as g) to run.sql
\i run.sql
--same query as above for answer
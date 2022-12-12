create table input (id serial, cmd text);
\copy input (cmd) from input.txt

--part 1
--turn add* command rows into array and unnest so we can get a blank row
--to act like a two cycle process.  then just rolling sum and totals for the 
--right cycle
with
 s as (select *, case when cmd like 'a%' then array[null,cmd] else array[cmd] end cmd2 from input order by id),
 i as (
    select id, row_number() over (order by id) as cycle,cmd,
        split_part(cmd,' ', 1) as cmd1, case when cmd = 'noop' then null else split_part(cmd,' ', 2) end as cmd2
    from (
        select id, unnest(cmd2) as cmd from s) x
     )
select sum((cycle + 1) * sig) from (
    select *, sum(v) over (order by cycle) as sig from (
        select cycle, cmd, cmd1, cmd2, case when cycle = 1 then 1 else cmd2::int end as v from i) a) x 
where cycle in (19,59,99,139,179,219);

--part 2
--build on above and just print correct character if the signal falls within range of cycle
--put pack together as array and stack the 6 rows. don't have a 0 cycle so just add a # to start
with
 s as (select *, case when cmd like 'a%' then array[null, cmd] else array[cmd] end cmd2 from input order by id),
 i as (
    select id, row_number() over (order by id) as cycle, cmd,
        split_part(cmd,' ', 1) as cmd1, case when cmd = 'noop' then null else split_part(cmd,' ', 2) end as cmd2
    from (select id, unnest(cmd2) as cmd from s) x),
x as (
    select *, sum(v) over (order by cycle) as sig from (
     select id, cycle, cmd, cmd1, cmd2, case when cycle = 1 then 1 else cmd2::int end as v from i) a),
d as (
    select *, mod(cycle, 40) - 1 as pix,
        case when mod(cycle, 40) between sig - 1 and sig + 1 then '#' else '.' end as sprite
    from x)
select 0, '#' || string_agg(sprite::text,'') filter ( where cycle between 1 and 39) from d union
select 1, string_agg(sprite::text,'') filter ( where cycle between 40 and 79) from d union
select 2, string_agg(sprite::text,'') filter ( where cycle between 80 and 119) from d union
select 3, string_agg(sprite::text,'') filter ( where cycle between 120 and 159) from d union
select 4, string_agg(sprite::text,'') filter ( where cycle between 160 and 199) from d union
select 5, string_agg(sprite::text,'') filter ( where cycle between 200 and 239)
from d order by 1;

create table input (id serial, cmd text);
\copy input (cmd) from input.txt

--*maybe* you could use recursive cte but thinking about 'cd ..' hurts my head
--but ltree extension seems useful
create extension ltree;

--need to keep track of current working dir to handle cd ..
create table dir(cwd text);

create or replace function cwd(cmd text) returns text AS
$$
declare
    d text;
begin
    if cmd = '$ cd /' then
        --handle start up case
        delete from dir;
        insert into dir values ('/');
        return '/';
    end if;
    if cmd = '$ cd ..' then
        --find end of path
        select split_part(cwd, '.', -1) into d from dir;

	--remove it
        update dir set cwd = rtrim(rtrim(cwd, d), '.');
        select cwd into d from dir;
        return d;
    end if;
    
    --add new dir to path
    update dir set cwd = cwd || '.' || replace(cmd, '$ cd ', '');
    select cwd into d from dir;
    return d;
end;
$$ language plpgsql;

--traverse commands and store current working dir with size
create table dirs as
with a as (
  select i.*, case when cmd ~ '^[0-9]' then split_part(cmd, ' ', 1)::int else null end as size,
    max(id) filter (where cmd like '$ cd%') over (order by id rows between unbounded  preceding and current row) AS last_dir
  from input i),
s as (
  select last_dir, sum(size) 
  from a group by last_dir)
select id, s.last_dir, sum, cmd, cwd(cmd)
from s join a on (a.id = s.last_dir);

--part 1
--now just a matter of turning the cwd into a ltree path (does not like the /) and group by ancestor
with p as (
  select replace(cwd,'/','root')::ltree as cwd,
    sum(sum) from dirs group by cwd),
d as (
  select p.cwd, sum(c.sum) from p left join p as c on c.cwd <@ p.cwd
  group by p.cwd)
select sum(sum) from d where sum <= 100000;

--part 2
--calculate needed space and find
with p as (
select replace(cwd,'/','root')::ltree as cwd,
       sum(sum) from dirs group by cwd),
d as (
  select p.cwd, sum(c.sum) from p left join p as c on c.cwd <@ p.cwd
  group by p.cwd),
find as (
  select abs(70000000-sum-30000000) as need from d where cwd = 'root')
select sum from d where sum > (select need from find) order by sum limit 1;


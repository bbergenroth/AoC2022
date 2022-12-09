create table input (r serial, c text);
\copy input (c) from input.txt

--part 1
--convert rows and columns to arrays then rows
--so basically a table based raster (r,c,v)
--mark all blocked trees ('x') and visible ('o') by seeing if a tree in 
--either direction is taller or not (max v > current v)

with i as (
    select r, regexp_split_to_array(c, '') as col from input),
g as (
    select r, ordinality as c, c as v, i.col
    from i, unnest(i.col) with ordinality as c)
select count(*) from (
    select r, c, v, col,
        case when v <= max(v) over (
            partition by r order by c rows between unbounded preceding and 1 preceding)
        then 'x' else 'o' end as l_r,
        case when v <= max(v) over (
            partition by r order by c desc rows between unbounded preceding and 1 preceding)
        then 'x' else 'o' end as r_l,
        case when v <= max(v) over (
            partition by c order by r rows between unbounded preceding and 1 preceding)
        then 'x' else 'o' end as u_d,
        case when v <= max(v) over (
            partition by c order by r desc rows between unbounded preceding and 1 preceding)
        then 'x' else 'o' end as d_u
    from g order by c, r) x
where l_r = 'o' or r_l = 'o' or u_d = 'o' or d_u = 'o';

--part 2
--trickier as we have to iterate in all directions
--a real raster with a recursive function would work too

--function to iterate a direction array and produce a score
create function visible(v integer, a anyarray) returns int
language plpgsql as
$$
declare
    t int;
    x int := 0;
begin
    foreach t in array a loop
        if v > t::int then
            x := x + 1;
        elsif v <= t::int then
            x := x + 1;
            return x;
        else
            return x;
        end if;
    end loop;
    return x;
end;
$$;

--need to reverse an array so it is in right order from inside to out
--no built in function for this...
create function array_reverse(anyarray) returns anyarray 
language 'sql' strict immutable as
$$
select array(
    select $1[i]
    from generate_subscripts($1, 1) AS s(i)
    order by 1 desc
);
$$;

--mostly just hoops to jump through to get the arrays in the 4 directions to be right order,
--then just get score and multiply
with i as (
  select r, regexp_split_to_array(c, '') as col from input),
g as (
  select r, ordinality as c, c::int as v , i.col
  from i, unnest(i.col) with ordinality as c),
s as (
  select *, col[:c - 1] as l_r, col[(c + 1):] as r_l,
    (array_agg(v) over (partition by c order by r))[:r - 1] as u_d,
    (array_agg(v) over (
        partition by c order by r desc))[:array_length((array_agg(v) over (
            partition by c order by r desc)), 1) - 1] as d_u
  from g order by c,r),
o as (
  select r,c,col,v::int,
    array_reverse(l_r) as l_r,
    r_l,
    array_reverse(u_d) as u_d,
    array_reverse(d_u) as d_u
  from s)
select max(s)
from (
  select visible(v, l_r) * visible(v, r_l) * visible(v, u_d) * visible(v, d_u) as s
  from o
) s;

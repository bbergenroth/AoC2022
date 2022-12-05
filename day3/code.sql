create table input (id serial, rucksack text);
\copy input (rucksack) from input with csv

--part 1
with i as ( --spit input into 2 parts
    select rucksack,
           substr(rucksack,1,length(rucksack)/2) as leftside,
           substr(rucksack,length(rucksack)/2+1, length(rucksack)) as rightside
    from input),
a as (select rucksack,unnest(regexp_split_to_array(leftside,'')) from i), --turn string into array then rows
b as (select rucksack,unnest(regexp_split_to_array(rightside,'')) from i),
-- get only single column value (the same character might be on the one side several times)
c as (select distinct a.rucksack, a.unnest as common from a join b on (a.rucksack=b.rucksack and a.unnest=b.unnest)),
d as (
        select rucksack, common,
             -- convert char to correct int
             case when ascii(common) <=90 then ascii(common)-65+27 else ascii(common)-96 end as score
        from c order by common)
select sum(score) from d;


--part 2
with a as (
    -- group into threes and turn string to array then rows
    select id, rucksack, ceil(id::numeric/3) as grp, unnest(regexp_split_to_array(rucksack,'')) from input order by id),
b as (
    --get common character among the three 
    select distinct a.grp,a.unnest from a join a as b on (a.grp=b.grp and a.unnest=b.unnest) join a as c on (a.grp=c.grp and a.unnest = c.unnest)
    where a.rucksack != b.rucksack and a.rucksack != c.rucksack and b.rucksack != c.rucksack)
select sum(case when ascii(unnest) <=90 then ascii(unnest)-65+27 else ascii(unnest)-96 end) as score from b;

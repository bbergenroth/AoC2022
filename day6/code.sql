--part 1
--turn string into table and aggregate previous 4 characters, then turn those into table
--grouped and get count and distinct count
with i as (
select row_number() over (partition by null) as id, message from (
    select regexp_split_to_table(message,'') as message from input) a),
p as (select id, message, string_agg(message, '') over (order by id rows between 4 preceding and 1 preceding) as p from i)
select id - 1 from (
    select id, message, count(*), count(distinct t) as d from (
        select id, message, regexp_split_to_table(p, '') t from p) a
    group by id, message) x
where count=4 and d=4 order by id limit 1;

--part 2
--same as above except for 14
with i as (
select row_number() over (partition by null) as id, message from (
    select regexp_split_to_table(message,'') as message from input) a),
p as (select id, message, string_agg(message, '') over (order by id rows between 14 preceding and 1 preceding) as p from i)
select id - 1 from (
    select id, message, count(*), count(distinct t) as d from (
        select id, message, regexp_split_to_table(p, '') t from p) a
    group by id, message) x
where count=14 and d=14 order by id limit 1;

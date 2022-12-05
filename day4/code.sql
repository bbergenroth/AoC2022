create table input (a text, b text);
\copy input from input.txt

--probably could have used range types instead
--part 1
with r as (
    select split_part(a, '-'::text, 1)::int as a1,
           split_part(a, '-'::text, 2)::int as a2,
           split_part(b, '-'::text, 1)::int as b1,
           split_part(b, '-'::text, 2)::int as b2  from input)
select count(*) from r where (a1 >= b1 and a2 <= b2) or (b1 >= a1 and b2 <= a2);

--part 2
with r as (
    select split_part(a, '-'::text, 1)::int as a1,
           split_part(a, '-'::text, 2)::int as a2,
           split_part(b, '-'::text, 1)::int as b1,
           split_part(b, '-'::text, 2)::int as b2  from input)
select count(*) from r
where a1 between b1 and b2 or a2 between b1 and b2 or b1 between a1 and a2 or b2 between a1 and a2;


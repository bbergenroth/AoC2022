--part 1
create table input (move text);

--skip first lines with the stack info
\copy input from program 'tail -n +11 /input.txt'

create table stacks (id serial, stack text[]);
insert into stacks (stack) values (ARRAY['B','G','S','C']);
insert into stacks (stack) values (ARRAY['T','M','W','H','J','N','V','G']);
insert into stacks (stack) values (ARRAY['M','Q','S']);
insert into stacks (stack) values (ARRAY['B','S','L','T','W','N','M']);
insert into stacks (stack) values (ARRAY['J','Z','F','T','V','G','W','P']);
insert into stacks (stack) values (ARRAY['C','T','B','G','Q','H','S']);
insert into stacks (stack) values (ARRAY['T','J','P','B','W']);
insert into stacks (stack) values (ARRAY['G','D','C','Z','F','T','Q','M']);
insert into stacks (stack) values (ARRAY['N','S','H','B','P','F']);

--generate moves
--use sql to make sql udpate statements based on the 3 numbers in the move text
--take the array and turn into rows and pull off the last n elements in reverse order and concat to new stack
--trim old stack
create view move_stacks as
with d as (
    select *, split_part(move,' ', 4) as f, split_part(move,' ', 6) as t, split_part(move,' ', 2) as n from input)
select 'update stacks set stack = ' ||
         'array_cat(stack, (' ||
           'with s as (' ||
             'select stack from stacks where id = ' || f || ') select array_agg(a) from (' ||
               'select a from (select a.* from s, unnest(s.stack) with ordinality a) b order by ordinality desc limit ' || n || ') c)) where id = ' || t || ';' ||
       'update stacks set stack = trim_array(stack, ' || n || ') where id = ' || f || ';' as remove from d;

--write generated update statements to file and execute file
\copy (select * from move_stacks) to move_stack.sql
\i move_stack.sql

--answer
select array_agg(stack) from (
    select stack[array_upper(stack, 1)] from stacks order by id) a

--part 2
drop view move_stacks;
--similar to above except an extra step to put back n elements in original order
create view move_stacks as
with d as (
    select *, split_part(move,' ', 4) as f, split_part(move,' ', 6) as t, split_part(move,' ', 2) as n from input)
select 'update stacks set stack = ' ||
         'array_cat(stack, (' ||
           'with s as (' ||
             'select stack from stacks where id = ' || f || ') select array_agg(a) from (select a from (' ||
               'select * from (select a.* from s, unnest(s.stack) with ordinality a) b order by ordinality desc limit ' || n || ') c order by ordinality) v)) where id = ' || t || ';' ||
       'update stacks set stack = trim_array(stack, ' || n || ') where id = ' || f || ';' as remove from d;

--repeat remaining steps from above

# PostgREST

- [Tutorial 0 - Get it Running](https://postgrest.org/en/stable/tutorials/tut0.html#)
  - we skip the recommended authenticator role in our configuration for brevity
  - run `nix-shell --run 'develop schema0.sql'`
  - run `curl -sS http://localhost:3000/todos | jq .`
- [Tutorial 1 - The Golden Key](https://postgrest.org/en/stable/tutorials/tut1.html#tutorial-1-the-golden-key)
  - jwt
    - ie. auth0 provider
    - idea: 'http auth proxy' provider
  - *skipped for brevity*
- [Tables and Views](https://postgrest.org/en/stable/api.html#tables-and-views)
  - tables and views are exposed as resources, ie. /people
  - most examples are worth looking at
  - supports openapi+json response format (default on /)
- [Resource Embedding](https://postgrest.org/en/stable/api.html#resource-embedding)
  - resouces can be embedded via foreign keys, across tables
  - early examples are worth looking at
  - *later examples were skipped for brevity*
- [Insertions / Updates](https://postgrest.org/en/stable/api.html#insertions-updates)
  - insert: `jq -n --arg task 'test insert' '{ task: $task }' | curl -sS -d @- -H 'Content-Type: application/json' http://localhost:3000/todos | jq .`
  - update: `jq -n --arg id 3 --arg task 'test update' '{ id: $id, task: $task, done: false, due: null }' | curl -sS -d @- -H 'Content-Type: application/json' -X PUT http://localhost:3000/todos?id=eq.3 | jq .`
  - delete: `curl -sS -H 'Content-Type: application/json' -X DELETE http://localhost:3000/todos?id=eq.3 | jq .`
  - bulk inserts via csv
- [Stored Procedures](https://postgrest.org/en/stable/api.html#stored-procedures)
  - `jq -n --argjson x 4 --argjson y 2 '{ x: $x, y: $y }' | curl http://localhost:3000/rpc/mult_them -X POST -H "Content-Type: application/json" -H "Prefer: params=single-object" -d @-`
  - noteworthy 3rd-party:
    - [Unix shell (PL/sh)](https://github.com/petere/plsh)
    - [JavaScript (PL/v8)](https://github.com/plv8/plv8)

## Resources

- [PostgREST Documentation](https://postgrest.org/en/stable/)

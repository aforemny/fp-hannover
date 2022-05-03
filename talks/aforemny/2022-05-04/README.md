# PostgREST

- [Tutorial 0 - Get it Running](https://postgrest.org/en/stable/tutorials/tut0.html#)
  - we skip the recommended authenticator role in our configuration for brevity
  - run `nix-shell --run 'develop schema0.sql'`
  - run `curl -sS http://localhost:3000/todos | jq .`
- [Tutorial 1 - The Golden Key](https://postgrest.org/en/stable/tutorials/tut1.html#tutorial-1-the-golden-key)
  - *skipped for brevity*
- [Tables and Views](https://postgrest.org/en/stable/api.html#tables-and-views)
  - tables and views are exposed as resources, ie. /people
  - most examples are worth looking at
  - supports openapi+json response format (default on /)
- [Resource Embedding](https://postgrest.org/en/stable/api.html#resource-embedding)
  - resouces can be embedded via foreign keys, across tables
  - early examples are worth looking at
  - *later examples were skipped for brevity*

## Resources

- [PostgREST Documentation](https://postgrest.org/en/stable/)

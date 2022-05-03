{ pkgs ? import
    (builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/9e49886b3d83d18ca59f66ec7b388315fa3d2e60.tar.gz")
    { }
}:
let inherit (pkgs) lib; in
pkgs.mkShell {
  buildInputs = [
    pkgs.haskellPackages.postgrest
    pkgs.postgresql
    (pkgs.writers.writeDashBin "develop" ''
      set -efu

      conf=$(${pkgs.coreutils}/bin/mktemp)
      cleanup() {
        rm -f "$conf"
        kill 0
      }
      trap cleanup EXIT INT TERM

      die() {
        echo "$@" >&2
        exit 1
      }

      schema=
      for arg; do
        case $arg in
          -)
          die "error: unknown option '$arg'" >&2
          ;;
          *)
          if test -z "$schema"; then
            schema="$arg"
          else
            die "error: usage: unknown '$arg'"
          fi
          ;;
        esac
        shift
      done
      if test -n "$schema"; then
        rm -fr "$PGDATA"
      fi
      if test ! -d "$PGDATA"; then
        if test -z "$schema"; then
          die "error: schema: no schema (init)" >&1
        elif test ! -f "$schema"; then
          die "error: schema: no such file '$schema'" >&1
        else
          ${pkgs.postgresql}/bin/initdb
        fi
      fi
      ${pkgs.coreutils}/bin/mkdir -p "$PGRUN"
      ${pkgs.postgresql}/bin/postgres -k "$PGRUN" &
      db_uri=postgres://$(whoami)@localhost:5432/postgres
      if test -n "$schema"; then
        cat "$schema" |
        while true; do
          {
            ${pkgs.postgresql}/bin/psql -v ON_ERROR_STOP=1 $db_uri
            rc=$?
          } || :
          if test $rc -eq 0; then
            break
          fi
          if test $rc -eq 2; then
            continue
          fi
          exit 1
        done
      fi
      cat >"$conf" <<EOF
      db-uri = "$db_uri"
      db-schema = "api"
      db-anon-role = "web_anon"
      EOF
      ${pkgs.haskellPackages.postgrest}/bin/postgrest "$conf" &
      wait
    '')
  ];
  shellHook = ''
    export HISTFILE=${lib.escapeShellArg (toString ./.)}/.history
    export PGDATA=${lib.escapeShellArg (toString ./.)}/data
    export PGRUN=${lib.escapeShellArg (toString ./.)}/run
  '';
}

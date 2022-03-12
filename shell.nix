{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    (pkgs.writers.writeDashBin "build-website" ''
      set -eu

      about=$(mktemp)
      eventTemplate=$(mktemp)
      nextEventTemplate=$(mktemp)
      clean() {
        rm -f "$about"
        rm -f "$eventTemplate"
        rm -f "$nextEventTemplate"
      }
      trap clean EXIT INT TERM

      out="${toString ./.}"/public
      rm -rf "$out"
      mkdir -p "$out"

      events=$(
        find "${toString ./.}"/events -name '*.md' -exec basename '{}' .md \; \
          | sort
      )
      nextEvent=""
      pastEvents=
      futureEvents=
      now=$(date -d $(date +%Y-%m-%d) +%s)
      for event in $events; do
        if test $(date -d $event +%s) -ge $now; then
          if test -z $nextEvent; then
            nextEvent="$event"
          else
            futureEvents="$futureEvents $event"
          fi
        else
          pastEvents="$pastEvents $event"
        fi
      done

      viewAbout() {
        cat README.md | ${pkgs.pandoc}/bin/pandoc -f markdown -t html
      }

      cat >"$nextEventTemplate" <<'EOF'
        <h2>
          <span>
            Next Session:
          </span>
          <small>
            $date$ @ $time$ CET/CEST
          </small>
        </h2>
      EOF

      viewNextSession() {
        ${pkgs.pandoc}/bin/pandoc -f markdown -t html \
          --template "$nextEventTemplate" \
          -V date=$1 \
          "${toString ./.}"/events/$1.md
      }

      cat >"$eventTemplate" <<'EOF'
      <article>
        <h3>
          <small>
            $date$, $time$ CET/CEST
          </small>
          <span>
            $title$
          </span>
        </h3>
        $body$
      </article>
      EOF

      viewEvent() {
        ${pkgs.pandoc}/bin/pandoc -f markdown -t html \
          --template "$eventTemplate" \
          -V date="$(date -d $1 '+%a, %b %-d')" \
          "${toString ./.}"/events/$1.md
      }

      viewEvents() {
        for event in "$@"; do
          viewEvent $event
        done
      }

      cat > public/index.html <<EOF
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <link rel="preconnect" href="https://fonts.googleapis.com">
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
          <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100;0,300;0,400;0,500;0,700;0,900;1,100;1,300;1,400;1,500;1,700;1,900&display=swap" rel="stylesheet">
          <style type="text/css">
            html {
              font-family: "Roboto", sans-serif;
              color: rgba(0,0,0,0.87);
              background-color: #efefef; }
            * {
              box-sizing: border-box; }
            body {
              max-width: 600px;
              background-color: #fff;
              padding: 10px; }
            h2 span,
            h2 small {
              display: block; }
            article {
              border-radius: 6px;
              border: 1px solid #ccc;
              padding: 10px;
              margin: 10px 0; }
            article h3 small,
            article h3 span {
              display: block;
            }
            article h3 small {
              font-size: 0.875rem; }
            article :first-child {
              margin-top: 0; }
            article :last-child {
              margin-bottom: 0; }
          </style>
        </head>
        <body>
          <main>
            <section>
              $(viewAbout)
            </section>
            <section>
              $(viewNextSession $nextEvent)
              $(viewEvents $nextEvent)
            </section>
            <section>
              <h2>Future Events</h2>
              $(viewEvents $(echo $futureEvents | tr ' ' '\n' | head -n 2 | xargs))
              <details>
                <summary>
                  and $(($(echo $futureEvents | wc -w) - 2)) more in 2022
                </summary>
                $(viewEvents $(echo $futureEvents | tr ' ' '\n' | tail -n +3 | xargs))
              </details>
            </section>
            <section>
              <h2>Past Events</h2>
              $(viewEvents $(echo $pastEvents | tr ' ' '\n' | tac | head -n 1 | xargs))
              <details>
                <summary>
                  and $(($(echo $pastEvents | wc -w) - 1)) more in 2022
                </summary>
                $(viewEvents $(echo $pastEvents | tr ' ' '\n' | tac | head -n +1 | xargs))
              </details>
            </section>
          </main>
        </body>
      </html>
      EOF
    '')
  ];
}

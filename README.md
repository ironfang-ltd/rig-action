# Ironfang Rig for GitHub Actions

Give the application under test a disposable external world for the length
of a CI job: a fresh inbox address, a public callback URL, a mock HTTP
endpoint and a route to a local port, allocated per run from an
`ironfang.rig.yaml` committed beside the code, with a sequenced record of
everything that reached them. Expectations in the file are judged when the
run finishes and decide the step.

```yaml
- id: ironfang
  uses: ironfang-ltd/rig-action/start@v1
  env:
    IRONFANG_API_KEY: ${{ secrets.IRONFANG_API_KEY }}
- run: npm run test:e2e
- if: always()
  uses: ironfang-ltd/rig-action/finish@v1
  with:
    run-id: ${{ steps.ironfang.outputs.run_id }}
```

Get a key with Rig scopes from the [Ironfang portal](https://portal.ironfang.uk)
and store it as a repository secret. The product is documented at
[ironfang.uk/rig/docs](https://ironfang.uk/rig/docs); the API is described
at [api.ironfang.uk/rig/openapi.yaml](https://api.ironfang.uk/rig/openapi.yaml).

## What a job sees

`start` syncs the suite file, starts a run and exports every resource to the
job: `IRONFANG_RIG_RUN_ID`, plus one `IRONFANG_RIG_<NAME>` variable per
resource in the file, upper-cased. The `resources` output carries the same
addresses as a JSON object for steps that prefer data to environment.

```yaml
resources:
  customer_email:
    type: email
  stripe_callback:
    type: callback
    connector:
      route: stripe
  shipping_api:
    type: mock_http
```

```yaml
- run: npm run test:e2e
  env:
    TEST_EMAIL: ${{ env.IRONFANG_RIG_CUSTOMER_EMAIL }}
    STRIPE_WEBHOOK_URL: ${{ fromJSON(steps.ironfang.outputs.resources).stripe_callback }}
    SHIPPING_API_URL: ${{ env.IRONFANG_RIG_SHIPPING_API }}
```

`finish` ends the run, prints one line per expectation, and fails the step
when the run's outcome is `fail`. Run it with `if: always()` so a failing
test still closes the run and records the verdicts.

## Inputs

### start

| Input | Default | Notes |
|---|---|---|
| `suite-file` | `ironfang.rig.yaml` | Path to the suite file. |
| `ttl` | from the suite | Run lifetime, `1m` to `24h`. |
| `external-id` | the workflow run id | Your reference for the run. |
| `version` | the release this action was cut with | The `ironfang-rig` release to download; it is verified against the release's SHA-256 sums before it runs. |
| `binary` | | A prebuilt `ironfang-rig` to use instead of downloading. |

Outputs: `run_id` and `resources`.

### finish

| Input | Default | Notes |
|---|---|---|
| `run-id` | required | The `run_id` output of the start step. |
| `outcome` | derived | `pass`, `fail` or `none` to override the verdicts. |
| `fail-on` | `fail` | `never` keeps the step green whatever the outcome. |
| `version`, `binary` | | As for start. |

The actions run on Linux and macOS runners. On Windows, pass `binary`.

## The command-line clients

The actions wrap `ironfang-rig`, which also works on its own: sync a suite,
start a run, wait for events, replay a callback, export the evidence bundle.
`ironfang-connect` is the connector that forwards a run's callbacks to a
port on your machine or runner without opening anything inbound. Both are
single static binaries for Linux, macOS (Intel and Apple Silicon) and
Windows, published on this repository's
[Releases](https://github.com/ironfang-ltd/rig-action/releases) with a
SHA-256 checksums file per release.

```
tar -xzf ironfang-rig_0.1.0_linux_amd64.tar.gz
sudo mv ironfang-rig_0.1.0_linux_amd64/ironfang-rig /usr/local/bin/
ironfang-rig version

export IRONFANG_API_KEY=if_live_...
ironfang-rig run -- npm test
```

```
# Minted per run by the API or the rig.connector.prepare MCP tool:
IRONFANG_CONNECT_TOKEN=ift_boot_... ironfang-connect \
  --route stripe=http://127.0.0.1:8080/webhooks/stripe
```

Verify a download with `sha256sum -c ironfang-rig_0.1.0_checksums.txt --ignore-missing`.

## Licence

MIT. Ironfang Rig itself is a hosted service governed by the
[Ironfang terms](https://ironfang.uk/legal/terms).

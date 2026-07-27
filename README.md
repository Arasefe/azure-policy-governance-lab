# Policy Governance Lab — Terraform

[![Terraform Test](https://github.com/Arasefe/azure-policy-governance-lab/actions/workflows/terraform-test.yml/badge.svg)](https://github.com/Arasefe/azure-policy-governance-lab/actions/workflows/terraform-test.yml)

Terraform implementation of the six Azure Policy assignments from
`4. Enforcing-Cloud-Governance-and-Security-Posture-via-Azure-Policy.html`
(E1–E6), against the `cavalry-prod` subscription. Every definition ID, effect,
and required role in this project was verified against the live Microsoft
Learn Azure Policy reference and the actual built-in policy JSON on GitHub —
not written from memory — during the review that also fixed several wrong
policy names/effects in the HTML lab itself.

## Project layout

```
.
├── main.tf                    # wires both modules via for_each over locals
├── locals.tf                  # the 5 deny-effect + 2 deploy-effect policy definitions
├── variables.tf               # subscription/region/SKU inputs, with validation
├── outputs.tf                 # assignment IDs, AMA principal IDs, remediation IDs
├── providers.tf               # azurerm + time provider config, subscription data source
├── versions.tf                # provider version pins; commented remote-backend example
├── terraform.tfvars.example   # copy to terraform.tfvars and adjust
├── .gitignore
├── modules/
│   ├── policy-assignment-deny/      # generic Deny/fixed-effect assignment (E1,E2,E3,E4,E6)
│   └── policy-assignment-deploy/    # DeployIfNotExists + identity + role + remediation (E5)
└── tests/
    ├── deny_module.tftest.hcl       # unit tests, policy-assignment-deny in isolation
    ├── deploy_module.tftest.hcl     # unit tests, policy-assignment-deploy in isolation
    └── root_plan.tftest.hcl         # integration test of the full for_each wiring
```

## Why two modules instead of six copy-pasted resource blocks

Five of the six policies (E1, E2, E3, E4, E6) are the same shape: assign a
built-in definition, optionally set `effect`, optionally add a
definition-specific parameter. `modules/policy-assignment-deny` captures that
shape once; `locals.tf` lists the five instances as data, and `main.tf` fans
them out with a single `for_each`. The one exception, E3 (Allowed VM SKUs),
passes `effect = null` — that definition genuinely has no Effect parameter
(confirmed from its actual JSON), and the module treats `null` as "omit this
key" rather than sending an invalid value.

E5 (the two AMA policies) is a different shape — it needs a managed identity,
a role grant, and a remediation task, all three tied together — so it gets
its own module, `modules/policy-assignment-deploy`, instantiated twice (once
per OS) via the same `for_each` pattern.

## Prerequisites

- Terraform >= 1.5 (tested with 1.15.5)
- Authenticated Azure CLI session (`az login`) with **Resource Policy
  Contributor** or **Owner** on the `cavalry-prod` subscription — the same
  requirement the HTML lab's P1 exercise calls out
- No remote backend is configured (see the commented block in `versions.tf`)
  — state is local by default, which is fine for a personal training
  subscription but not for a shared/team environment

## Running it

```bash
cp terraform.tfvars.example terraform.tfvars   # adjust if your values differ
terraform init
terraform validate
terraform plan             # review before applying — this is a live subscription
terraform apply
```

`terraform plan` is read-only. `terraform apply` will create real policy
assignments (and, for E5, a real system-assigned identity, role assignment,
and remediation task) against `cavalry-prod` — treat it with the same care
as the portal-based steps in the HTML lab.

## Testing (no Azure credentials required)

```bash
terraform test
```

`.github/workflows/terraform-test.yml` runs `fmt -check`, `validate`, and
`test` on every push and pull request against `main` — no Azure credentials
are configured or needed for that workflow, since every run below is fully
mocked.

All three test files use `mock_provider` (Terraform >= 1.7's native test
mocking) for both `azurerm` and `time` — nothing here calls out to Azure, so
`terraform test` runs fully offline and is safe in CI. It covers exactly the
mistakes found and fixed in the HTML lab review:

- `deny_module.tftest.hcl` asserts that `effect = null` (the E3 case) omits
  the `effect` key entirely, and that an invalid effect value fails the
  module's own `validation` block before ever reaching a plan against Azure.
- `deploy_module.tftest.hcl` asserts the identity is `SystemAssigned`, exactly
  one role assignment is created per role, and (via a full mock `apply`) that
  `principal_id` and `role_assignment_ids` are populated as the root outputs
  and the lab's Ask-Claude verification step expect.
- `root_plan.tftest.hcl` asserts the whole project plans exactly 5 deny-effect
  + 2 deploy-effect assignments, that E3 specifically has no `effect` key,
  and that E1/E2/E4/E6 all resolve to `Deny`.

Two mock-provider quirks worth knowing if you extend these tests: computed
attributes default to a random 8-character string unless overridden via
`mock_resource { defaults = {...} }` / `mock_data { defaults = {...} }`, and
anything parsed by the provider as a strongly-typed ARM resource ID (like
`policy_assignment_id` or the subscription `id`) will fail that parsing
against the random default — both test files override those specific IDs
with realistically-shaped values.

## Policy-as-code validation (optional)

The Azure Terraform MCP tooling can generate a `conftest` command to lint a
plan against Azure's `policy-library-avm` rule set before you ever run
`apply`. `conftest` isn't installed in this environment; to use it:

```bash
brew install conftest                                          # macOS
git clone https://github.com/Azure/policy-library-avm.git policy

terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
conftest test --policy policy tfplan.json
```

This is a shift-left guardrail, not a replacement for `terraform plan` review
— it catches known-bad patterns (e.g. missing encryption, overly permissive
network rules) in the plan itself, before anything reaches Azure.

## Mapping back to the HTML lab

| Terraform | HTML lab exercise | Definition ID |
|---|---|---|
| `module.deny_effect["allowed_locations"]` | E1 | `e56962a6-4747-49cd-b67b-bf8b01975c4c` |
| `module.deny_effect["storage_no_public_access"]` | E2 | `b2982f36-99f2-4db5-8eff-283140c09693` |
| `module.deny_effect["allowed_vm_skus"]` | E3 | `cccc23c7-8427-4f53-ad12-b6a63eb452b3` |
| `module.deny_effect["disks_no_public_access"]` | E4 | `8405fdab-1faf-48aa-b702-999c9c172094` |
| `module.deploy_effect["ama_windows"]` | E5 (Windows) | `ca817e41-e85a-4783-bc7f-dc532d36235e` |
| `module.deploy_effect["ama_linux"]` | E5 (Linux) | `a4034bc6-ae50-406d-bf76-50f4ee5a7811` |
| `module.deny_effect["appservice_https_only"]` | E6 | `a4af4a39-4135-47fb-b175-47fbdf85311d` |

The Validate-phase exercises (V1–V3) in the HTML lab still apply unchanged —
they test the *effect* of the assignment (does a bad deployment actually get
blocked), which is identical whether the assignment was created via the
portal or via this Terraform project.

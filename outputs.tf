output "deny_effect_assignment_ids" {
  description = "Resource IDs of the five Deny/fixed-effect assignments (E1, E2, E3, E4, E6), keyed by local name."
  value       = { for k, m in module.deny_effect : k => m.id }
}

output "deploy_effect_assignment_ids" {
  description = "Resource IDs of the two AMA DeployIfNotExists assignments (E5), keyed by local name."
  value       = { for k, m in module.deploy_effect : k => m.assignment_id }
}

output "ama_principal_ids" {
  description = "Object IDs of the AMA assignments' system-assigned identities — the same values E5's Ask-Claude verification step checks role assignments against."
  value       = { for k, m in module.deploy_effect : k => m.principal_id }
}

output "ama_remediation_ids" {
  description = "Resource IDs of the two AMA remediation tasks."
  value       = { for k, m in module.deploy_effect : k => m.remediation_id }
}

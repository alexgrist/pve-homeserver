# curated to what ships cheaply without a provider plugin, the defaults cover the rest
plugin "terraform" {
  enabled = true
}

# the environments are root modules, not library modules; the lxc-container
# module inherits its version constraint from the environments
rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_required_version" {
  enabled = false
}

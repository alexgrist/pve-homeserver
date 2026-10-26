# lxc-container

Reusable LXC container module, shared between the environments.

- a container tagged for role selection recreates on tag changes instead of updating in place, tags drive ansible and stale tags are worth recreating over
- a data tier container is a stopped, protected container owning the block volumes stateful containers mount; serving containers route a mount with an owner to the tier, where size, storage and backup configure the volume itself and the remaining attributes stay attach options
- protection enables pve protection, exempting the container from tag churn replacement; releasing it is a deliberate change
- mount point idmap is not modelled by the provider yet, the module reconciles it through the api after creation, which needs pve 9.2
- wait_for_ip expects an ipv4 address through dhcp, surfaced on the container_ip output

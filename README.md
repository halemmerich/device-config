# Experimental ansible roles for setting up Debian or Arch servers and clients

## Role naming scheme:

- `server-*`
  Install and configure software which is directly or indirectly used by services ultimately served via network
- `util-*`
  Utilities which can be called to update configuration or restart services when handlers are not useful. Handlers should be preferred if possible.
- Everything else

## Tags:

- `config`
  Only configuration of already installed software. This explicitly means, that all config-tagged tasks can be run offline against the staging environment
- `install`
  Install software from repositories or other sources. Either via package management or manually.
- `upgrade`
  Upgrade installed software, but do not change any configuration. Restoration of config is allowed, if the software rewrites its config on install.

## External ansible roles/collections

Install with ansible-galaxy collection install

- `kewlfft.aur`

## Staging environment:

The playbook can be run against the staging environment by executing `./run_staging` and `./run_staging_upgrade`.

### Configure virtual machines:

Virtual machines with the `staging-*-*` names from the `host_vars` dir

Network configuration as defined in the staging inventory examples. Alternatively `staging_hosts` and `staging_netconf.yml` can be created with custom network config.

### Docker:

WARNING!!! Docker containers startet with compose currently are using `CAP_SYS_ADMIN` and could harm your host. They do also need cgroupns mode set to "host".

#### Config:

- cgroupns mode needs to be set to "host"
- IPv6 needs to be activated: https://medium.com/@skleeschulte/how-to-enable-ipv6-for-docker-containers-on-ubuntu-18-04-c68394a219a2

Example daemon.json:

```
{
  "ipv6": true,
  "fixed-cidr-v6": "fd00::/80",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "default-cgroupns-mode": "host",
  "cgroup-parent": "docker.slice"
}
```

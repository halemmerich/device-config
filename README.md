# Experimental ansible roles for setting up Debian or Arch servers and clients

## Setup

- Create the `production` inventory file, similar to the `staging` environment
- Optionally create the `production_hosts` file, similar to `staging_hosts.example`
  - `ansible_host`, `ansible_user`, `ansible_become_pass`, `ansible_python_interpreter` can useful variables to set depending on OS
- Optionally create a secret.yml file with `ansible-vault create secrets.yml` containing entries of the form `become_pass_<hostname>: P4ssW0rD` where `<hostname>` is to be replaced with hostnames as used in the production inventory. Set the `ansible_become_pass` variable to `{{ become_pass_hostname }}` to use the password from the vault

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

## Staging environment:

The playbook can be run against the staging environment by executing `./run_staging` and `./run_staging_upgrade`.

### Docker:

WARNING!!! Docker containers startet with compose currently are using `CAP_SYS_ADMIN` and could harm your host. They do also need cgroupns mode set to "host".

Commands for an initial run of the containers:
as root: `cd staging_env; up.sh username` # Creates the containers and authorizes the ssh public key of username in the containers
as username: `staging_env/makeHostsKnown.sh` # Deletes all existing keys for the IPs of the containers from the authorized keys and puts the host keys of the containers there
as username: `./run_staging_upgrade`

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

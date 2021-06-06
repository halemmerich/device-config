#Experimental ansible roles for setting up Debian or Arch servers and clients

##Role naming scheme:

- server-*
  Install and configure software which is directly or indirectly used by services ultimately served via network
- util-*
  Utilities which can be called to update configuration or restart services when handlers are not useful. Handlers should be preferred if possible.
- Everything else

##Tags:

- config:
  Only configuration of already installed software. This explicitly means, that all config-tagged tasks can be run offline against the staging environment
- install:
  Install software from repositories or other sources. Either via package management or manually.
- upgrade:
  Upgrade installed software, but do not change any configuration. Restoration of config is allowed, if the software rewrites its config on install.

##Staging environment:

The following virtual machines can be configured:

- staging-server-arch and staging-desktop-arch
  These machines are installed using the arch bootstrapper
  - LUKS password is luks
  - admin user password is admin
- staging-server-debian and staging-desktop-debian
  These machines are installed as a debian chicken install.
  - They additionally need a user *admin* created with password *admin* which ist able to use sudo with password
- hostnames need to be set accordingly
  
Network configuration as defined in the staging inventory.
  
  

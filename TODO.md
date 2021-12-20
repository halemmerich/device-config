* Move all subdomains/components of prosody to under xmpp.{{ domain }}
* Manage netcup dns using locally executed tasks
* Remove all nginx upstreams that are handled by default web_backend
* Tag all tasks with install/config/cleanup
 * Differentiate between upgrade and install tasks, only install if not yet installed
* Add tasks to remove everything a role did
* Check TLS settings for all domains
* External HTTP upload for prosody or other way for bigger transfered files
* More sanitation for input parameters in server_* scripts
* Nextcloud/Sharing
 * Allow users to share external files
 * Configure quota for webdav shares or for web server user accounts (nextcloud, http, www-data)
 * Split webdav role into generic web share and webdav server config (web share also used for nextcloud big file share)
 * Configure nextcloud files retention and auto tagging for external folder
  * https://docs.nextcloud.com/server/20/admin_manual/file_workflows/automated_tagging.html
  * https://docs.nextcloud.com/server/20/admin_manual/file_workflows/retention.html
* server-kernel for efi boot

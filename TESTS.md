Jitsi
* Three way call with all outgoing TCP Ports but {{ server_nginx_port_http }}/{{ server_nginx_port_tls }} blocked

Jabber
* All extensions available in Conversations
* HTTP available
  * https://xmpp.{{ domain }}/http-bind
  * https://xmpp.{{ domain }}/xmpp-websocket
* Compliancetest at 100%: https://compliance.conversations.im/server/{{ domain }}/
* Check push notifications to iOS-Apps works: Monal, ChatSecure and Siskin
* Check group chat with iOS-Apps
* Conversations Audio and Video Call from different networks (Internet behind NAT and 4G)

Sogo
* Webinterface login works
* Sync with Evolution and DavX5 works

Mail
* Sending and Receiving Mail to outside Address from sogo webmailer
* Sending and Receiving Mail to outside Address from external Client
* Managesieve works
  * Script for testing
  
require [ "fileinto", "regex", "variables", "mailbox" ];

if address :localpart :regex "to" ".*[+_-]([^+_-]*)" {
  fileinto :create "INBOX.${1}";
}
    
* Sending Mail to tester+tag1@{{ domain }}, tester-tag2@{{ domain }}, tester_tag3@{{ domain }}
  * mails sorted into folders tag1, tag2, tag3
* MXToolBox all green:  https://mxtoolbox.com/SuperTool.aspx?action=smtp%3amail.{{ domain }}&run=toolpage

Nextcloud
* Upload to bigfileshare in tester account
* https://scan.nextcloud.com/ is A+

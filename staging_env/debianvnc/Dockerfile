FROM debianbase:latest
ARG PASSWORD=ansible

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tigervnc-standalone-server xfce4 dbus-x11
RUN mkdir /home/ansible/.vnc
RUN echo session=xfce > /home/ansible/.vnc/config
RUN echo $PASSWORD | vncpasswd -f > /home/ansible/.vnc/passwd
RUN echo :1=ansible > /etc/tigervnc/vncserver.users
RUN chown -R ansible:ansible /home/ansible/.vnc
RUN chmod 600 /home/ansible/.vnc/passwd
RUN echo "[Unit]\n\
Description=Remote desktop service (VNC)\n\
After=syslog.target network.target\n\
\n\
[Service]\n\
Type=forking\n\
ExecStart=/usr/bin/vncserver -localhost no\n\
ExecStop=/usr/bin/vncserver -kill :1 Xvnc\n\
User=ansible\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n\
" > /etc/systemd/system/vncserver.service
RUN ln -s /usr/lib/systemd/system/vncserver.service /etc/systemd/system/multi-user.target.wants/vncserver.service
RUN echo "unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
startxfce4\n\
" > /home/ansible/.vnc/xstartup
RUN chmod +x /home/ansible/.vnc/xstartup

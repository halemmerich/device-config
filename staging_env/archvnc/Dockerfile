FROM archbase:latest
ARG PASSWORD=ansible

RUN pacman -Syu --noconfirm tigervnc xfce4
RUN mkdir /home/ansible/.vnc
RUN echo session=xfce > /home/ansible/.vnc/config
RUN echo $PASSWORD | vncpasswd -f > /home/ansible/.vnc/passwd
RUN echo :1=ansible > /etc/tigervnc/vncserver.users
RUN chown -R ansible:ansible /home/ansible/.vnc
RUN chmod 600 /home/ansible/.vnc/passwd
RUN systemctl enable vncserver@:1

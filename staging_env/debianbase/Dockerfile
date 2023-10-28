FROM debian:bookworm
ARG PASSWORD="ansible"
ARG SSH_PUBKEY=""
ARG TIMEZONE=Europe/Berlin

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y ssh python3 sudo ca-certificates nano python3-apt locales
RUN ln -s /usr/lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done);
RUN rm -f /lib/systemd/system/local-fs.target.wants/*;
RUN rm -f /lib/systemd/system/sockets.target.wants/*udev*;
RUN ln -s /lib/systemd/system/console-getty.service /etc/systemd/system/getty.target.wants/console-getty.service

RUN useradd -m ansible
RUN groupadd wheel
RUN usermod -aG wheel ansible
RUN mkdir /home/ansible/.ssh
RUN /bin/bash -c 'echo -e "${PASSWORD}\n${PASSWORD}\n"' | passwd ansible
RUN echo "$SSH_PUBKEY" > /home/ansible/.ssh/authorized_keys
RUN echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

CMD ["/sbin/init"]

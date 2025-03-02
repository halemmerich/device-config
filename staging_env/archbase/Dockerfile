#FROM archlinux:base-20220109.0.43549
FROM archlinux
ARG PASSWORD="ansible"
ARG SSH_PUBKEY=""
ARG TIMEZONE=Europe/Berlin

#RUN sed -i -e "s|^SigLevel.*|SigLevel=Never|" /etc/pacman.conf
#RUN echo 'Server=https://archive.archlinux.org/repos/2022/01/10/$repo/os/$arch' > /etc/pacman.d/mirrorlist

RUN pacman -Syy --noconfirm 
RUN pacman -S --noconfirm archlinux-keyring
RUN pacman-key --init
RUN pacman-key --populate
RUN pacman -Su --noconfirm linux-lts openssh python sudo
RUN mkdir /etc/systemd/system/multi-user.target.wants
RUN ln -s /usr/lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service
RUN ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done);
RUN rm -f /lib/systemd/system/local-fs.target.wants/*;
RUN rm -f /lib/systemd/system/sockets.target.wants/*udev*;

RUN useradd -m ansible
RUN usermod -aG wheel ansible
RUN mkdir /home/ansible/.ssh
RUN echo -e "$PASSWORD\n$PASSWORD\n" | passwd ansible
RUN echo "$SSH_PUBKEY" > /home/ansible/.ssh/authorized_keys
RUN echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

#restore missing locale files
RUN sed -i "/locale/d" /etc/pacman.conf
RUN pacman -Su --noconfirm glibc

CMD ["/sbin/init"]

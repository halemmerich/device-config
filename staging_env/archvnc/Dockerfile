FROM archbase:latest
ARG PASSWORD=ansible

RUN pacman -Syu --noconfirm sway wayvnc
COPY swayvnc.service /etc/systemd/system/swayvnc.service
COPY wayvnc /etc/sway/config.d/wayvnc

COPY linger.service /etc/systemd/system/linger.service

RUN systemctl enable swayvnc
RUN systemctl enable linger

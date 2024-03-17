FROM debianbase:latest
ARG PASSWORD=ansible

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y sway wayvnc

COPY swayvnc.service /etc/systemd/system/swayvnc.service
COPY wayvnc /etc/sway/config.d/wayvnc

RUN systemctl enable swayvnc
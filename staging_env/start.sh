#!/bin/bash
command -v docker-compose >/dev/null 2>&1 || { echo docker-compose is missing && exit 1; }

docker-compose start




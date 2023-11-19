#!/bin/bash

pacman -D --asdeps $(pacman -Qqe)
pacman -D --asexplicit base linux-lts linux-firmware python ssh sudo
pacman -Qtdq | pacman -Rns -

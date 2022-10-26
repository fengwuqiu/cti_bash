#!/bin/bash

sudo apt-get install libasound2-dev -y --allow-unauthenticated
sudo apt-get install libcpprest-dev -y --allow-unauthenticated
sudo apt-get install protobuf-compiler -y --allow-unauthenticated
sudo apt-get install libgps-dev -y --allow-unauthenticated
sudo apt-get install libarmadillo-dev -y --allow-unauthenticated
sudo apt-get install libserial-dev -y --allow-unauthenticated
sudo apt-get install openssh-server -y --allow-unauthenticated
sudo apt-get install sox libsox-fmt-all -y --allow-unauthenticated
sudo apt-get install libpugixml-dev -y --allow-unauthenticated
sudo apt-get install libcgal-dev -y --allow-unauthenticated
sudo apt-get install cutecom -y --allow-unauthenticated
sudo apt-get -f install -y --allow-unauthenticated
sudo apt-get install net-tools
exit 0
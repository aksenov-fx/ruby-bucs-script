#!/bin/bash

sudo apt update
sudo apt install -y libtool libffi-dev ruby-dev

gem install iruby
iruby register --force

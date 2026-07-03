#!/bin/bash

# C - provides clangd
sudo dnf install clang-tools-extra

# Java - jdtls comes via eglot auto-install
sudo dnf install java-25-openjdk-devel

# Python
pip install pyright

# JS/TS
npm install -g typescript typescript-language-server

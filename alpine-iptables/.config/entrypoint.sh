#!/bin/sh
# Import all rules from /etc/iptables/*
iptables-restore < /etc/iptables/rules.v4

# Run the original command
#exec "$@" || (echo "service is not running" && exit 1)
#!/bin/sh

echo "Restoring iptables rules"
iptables-restore < /etc/iptables/rules.v4
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:DOCKER - [0:0]
:DOCKER-ISOLATION-STAGE-1 - [0:0]
:DOCKER-ISOLATION-STAGE-2 - [0:0]
:DOCKER-USER - [0:0]

# allow localhost network
-A INPUT -i lo -j ACCEPT

-A INPUT -p udp -m udp --dport 67:68 -j ACCEPT
# allow ping protocol
-A INPUT -p ICMP -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
# Allow SSH Network All Network
-A INPUT -p tcp -m tcp --dport 22 -m state --state NEW,RELATED,ESTABLISHED -m limit --limit 13/sec --limit-burst 15 -j ACCEPT
# allow Untuk DNS Services
-A INPUT -p udp -m udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT
# allow HTTP Input Before Stabilize


##################################### SCOPE PORT 80 #####################################################################
-A INPUT -p tcp --sport 2233 -m state --state NEW -m recent --set
-A INPUT -p tcp --sport 2233 -m state --state NEW -m recent --update --seconds 20 --hitcount 20 -j DROP
-A INPUT -p tcp -m tcp --sport 2233 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 15 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
-A INPUT -p tcp -m tcp --sport 2233 -m state --state INVALID -j DROP
-A INPUT -p tcp -m tcp --sport 2233 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
##################################### SCOPE PORT 80 #####################################################################

##################################### SCOPE PORT 80 #####################################################################
-A INPUT -p tcp --sport 80 -m state --state NEW -m recent --set
-A INPUT -p tcp --sport 80 -m state --state NEW -m recent --update --seconds 20 --hitcount 20 -j DROP
-A INPUT -p tcp -m tcp --sport 80 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 15 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
-A INPUT -p tcp -m tcp --sport 80 -m state --state INVALID -j DROP
-A INPUT -p tcp -m tcp --sport 80 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
##################################### SCOPE PORT 80 #####################################################################
##################################### SCOPE PORT 80 #####################################################################
-A INPUT -p tcp --sport 443 -m state --state NEW -m recent --set
-A INPUT -p tcp --sport 443 -m state --state NEW -m recent --update --seconds 20 --hitcount 20 -j DROP
-A INPUT -p tcp -m tcp --sport 443 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 15 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
-A INPUT -p tcp -m tcp --sport 443 -m state --state INVALID -j DROP
-A INPUT -p tcp -m tcp --sport 443 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
##################################### SCOPE PORT 80 #####################################################################

# allow Input Protocol Open VPN Network
-A INPUT -i enp2s0 -p udp --dport 1194 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
##################################### SCOPE PORT 80 #####################################################################
-A INPUT -p tcp --dport 80 -m state --state NEW -m recent --set
-A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 20 --hitcount 20 -j DROP
-A INPUT -p tcp -m tcp --dport 80 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 15 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
-A INPUT -p tcp -m tcp --dport 80 -m state --state INVALID -j DROP
-A INPUT -p tcp -m tcp --dport 80 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
##################################### SCOPE PORT 80 #####################################################################

##################################### SCOPE PORT 443 #####################################################################
-A INPUT -p tcp --dport 443 -m state --state NEW -m recent --set
-A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 20 --hitcount 20 -j DROP
-A INPUT -p tcp -m tcp --dport 443 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 15 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
-A INPUT -p tcp -m tcp --dport 443 -m state --state INVALID -j DROP
-A INPUT -p tcp -m tcp --dport 443 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
##################################### SCOPE PORT 443 #####################################################################

##################################### SCOPE PORT 3306 #####################################################################
-A INPUT -p tcp --dport 3306 -m state --state NEW -m recent --set
-A INPUT -p tcp --dport 3306 -m state --state NEW -m recent --update --seconds 20 --hitcount 20 -j DROP
-A INPUT -p tcp -m tcp --dport 3306 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 15 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
-A INPUT -p tcp -m tcp --dport 3306 -m state --state INVALID -j DROP
-A INPUT -p tcp -m tcp --dport 3306 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
##################################### SCOPE PORT 3306 #####################################################################

#************************************** FORWARD ****************************************************************************
-A FORWARD -j DOCKER-USER
-A FORWARD -j DOCKER-ISOLATION-STAGE-1
-A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -o docker0 -j DOCKER
-A FORWARD -i docker0 ! -o docker0 -j ACCEPT
-A FORWARD -i docker0 -o docker0 -j ACCEPT
#************************************** FORWARD ****************************************************************************
#******************************* COSTUM DOCKER *****************************************************************************
-A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
-A DOCKER-ISOLATION-STAGE-1 -j RETURN
-A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
-A DOCKER-ISOLATION-STAGE-2 -j RETURN
-A DOCKER-USER -j RETURN
#****************************** COSTUM DOCKER ******************************************************************************
-A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -p udp -m udp --sport 67:68 -j ACCEPT
# allow Untuk DNS Services
-A OUTPUT -p udp -m udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT
-A OUTPUT -p tcp -m tcp --sport 22 -m state --state NEW,RELATED,ESTABLISHED -m limit --limit 13/sec --limit-burst 15 -j ACCEPT
-A OUTPUT -p tcp -m tcp --dport 22 -m state --state NEW,RELATED,ESTABLISHED -m limit --limit 13/sec --limit-burst 15 -j ACCEPT


COMMIT

################################# NAT NETWORK ###############################################################################
*nat
:PREROUTING ACCEPT [16:960]
:INPUT ACCEPT [16:960]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [6:1593]
:DOCKER - [0:0]

-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
-A DOCKER -i docker0 -j RETURN

-A POSTROUTING -j MASQUERADE

COMMIT


*mangle
:PREROUTING ACCEPT [151:36564]
:INPUT ACCEPT [151:36564]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [145:32272]
:POSTROUTING ACCEPT [145:32272]

#-A PREROUTING -m conntrack --ctstate INVALID -j DROP
#-A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

COMMIT

*raw
:PREROUTING ACCEPT [151:36564]
:OUTPUT ACCEPT [145:32272]

COMMIT
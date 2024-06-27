*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:DOCKER - [0:0]
:DOCKER-ISOLATION-STAGE-1 - [0:0]
:DOCKER-ISOLATION-STAGE-2 - [0:0]
:DOCKER-USER - [0:0]

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

-A PREROUTING -m conntrack --ctstate INVALID -j DROP

-A PREROUTING -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name DDOS
-A PREROUTING -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 --name DDOS -j DROP

-A PREROUTING -p tcp --dport 80 -m conntrack --ctstate NEW -m recent --set --name DDOS
-A PREROUTING -p tcp --dport 80 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 --name DDOS -j DROP

-A PREROUTING -p tcp --dport 443 -m conntrack --ctstate NEW -m recent --set --name DDOS
-A PREROUTING -p tcp --dport 443 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 --name DDOS -j DROP


COMMIT

*raw
:PREROUTING ACCEPT [151:36564]
:OUTPUT ACCEPT [145:32272]

COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

COMMIT

################################# NAT NETWORK ###############################################################################
*nat
:PREROUTING ACCEPT [16:960]
:INPUT ACCEPT [16:960]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [6:1593]

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
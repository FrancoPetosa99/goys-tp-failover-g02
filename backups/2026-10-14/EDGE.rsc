# EDGE - /export terse hide-sensitive - RouterOS 7.14.3 - capturado 2026-10-14 03:46:11 (fase 3, reloj del router en UTC)
# Transcrito de las capturas f3-07i1 y f3-07i2 (capturas/f3). Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR).
# CLAVES: el export mostraba la clave OSPF en texto plano (auth-key); aqui se reemplazo por <OSPF-KEY>.
#         El export NO incluye tcp-md5-key de BGP: se agregaron <BGP-KEY-ISP1> y <BGP-KEY-ISP2> a las dos lineas de '/routing bgp connection'.
#         Claves reales: canal privado del grupo. Tampoco incluye usuarios ni el password VRRP (que no aplica a EDGE).
# Las 2 lineas '/routing bgp connection add' se ven recortadas a la derecha en la captura; se completaron con los comandos aplicados
#   en las sesiones 1, 2 y 3 y con el tramo visible al final de la primera linea ('.3.3.3' = router-id=3.3.3.3).
# El export de F2 de EDGE traia dos lineas de rename de interfaz (ether2->ether1 y ether1->ether2); este export de F3 no las muestra.
#   Antes de reaplicar en un nodo nuevo: revisar '/interface ethernet print' (docs/f1/mapa-interfaces-e-incidente.md).
/interface list add name=WAN
/interface list add name=LAN
/port set 0 name=serial0
/routing ospf instance add disabled=no name=ospf-lab originate-default=always router-id=3.3.3.3
/routing ospf area add disabled=no instance=ospf-lab name=backbone
/ip neighbor discovery-settings set discover-interface-list=none
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=4096
/interface list member add interface=ether1 list=WAN
/interface list member add interface=ether2 list=WAN
/interface list member add interface=ether3 list=LAN
/interface list member add interface=ether4 list=LAN
/ip address add address=10.255.0.1 interface=lo network=10.255.0.1
/ip address add address=192.0.2.2/30 interface=ether1 network=192.0.2.0
/ip address add address=192.0.2.6/30 interface=ether2 network=192.0.2.4
/ip address add address=10.0.0.1/30 interface=ether3 network=10.0.0.0
/ip address add address=10.0.0.5/30 interface=ether4 network=10.0.0.4
/ip dhcp-client add interface=ether1
/ip firewall filter add action=accept chain=input comment=in-estab connection-state=established,related,untracked
/ip firewall filter add action=drop chain=input comment=in-invalid connection-state=invalid
/ip firewall filter add action=accept chain=input comment=in-icmp protocol=icmp
/ip firewall filter add action=accept chain=input comment=in-bgp-isp1 dst-port=179 in-interface=ether1 protocol=tcp src-address=192.0.2.1
/ip firewall filter add action=accept chain=input comment=in-bgp-isp2 dst-port=179 in-interface=ether2 protocol=tcp src-address=192.0.2.5
/ip firewall filter add action=accept chain=input comment=in-ospf in-interface-list=LAN protocol=ospf
/ip firewall filter add action=accept chain=input comment=in-ssh-lan dst-port=22 in-interface-list=LAN protocol=tcp
/ip firewall filter add action=drop chain=input comment=in-drop-resto
/ip firewall filter add action=accept chain=forward comment=fw-estab connection-state=established,related,untracked
/ip firewall filter add action=drop chain=forward comment=fw-invalid connection-state=invalid
/ip firewall filter add action=accept chain=forward comment=fw-lan-a-wan in-interface-list=LAN out-interface-list=WAN
/ip firewall filter add action=accept chain=forward comment=fw-lan-a-lan in-interface-list=LAN out-interface-list=LAN
/ip firewall filter add action=drop chain=forward comment=fw-drop-resto
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,192.168.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/ip ssh set strong-crypto=yes
/routing bgp connection add as=65000 disabled=no input.filter=in-isp1 local.address=192.0.2.2 .role=ebgp name=to-ISP1 output.filter-chain=out-isp1 .redistribute=ospf remote.address=192.0.2.1 .as=65001 router-id=3.3.3.3 tcp-md5-key=<BGP-KEY-ISP1>
/routing bgp connection add as=65000 input.filter=in-isp2 local.address=192.0.2.6 .role=ebgp name=to-ISP2 output.filter-chain=out-isp2 .redistribute=ospf remote.address=192.0.2.5 .as=65002 router-id=3.3.3.3 tcp-md5-key=<BGP-KEY-ISP2>
/routing filter rule add chain=in-isp1 rule="set bgp-local-pref 200; accept"
/routing filter rule add chain=in-isp2 rule="set bgp-local-pref 100; accept"
/routing filter rule add chain=out-isp1 rule="if (dst == 192.168.10.0/24 || dst == 192.168.20.0/24) { accept }"
/routing filter rule add chain=out-isp1 rule=reject
/routing filter rule add chain=out-isp2 rule="if (dst == 192.168.10.0/24 || dst == 192.168.20.0/24) { set bgp-path-prepend 2; accept }"
/routing filter rule add chain=out-isp2 rule=reject
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether3 type=ptp
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether4 type=ptp
/routing ospf interface-template add area=backbone disabled=no interfaces=lo passive
/system identity set name=EDGE
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

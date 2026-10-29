# EDGE - /export terse hide-sensitive - RouterOS 7.14.3 - capturado 2026-10-17 23:47:20 (fase 4, reloj del router)
# Transcrito de las capturas f4-05i, f4-05j y f4-05j-c (capturas/f4). Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR).
# Los routers no tienen NTP: su reloj (UTC) no esta sincronizado y en EDGE se midio ~25 min adelantado (ver docs/f4/ejecucion.md).
# CLAVES: el export mostraba la clave OSPF en texto plano (auth-key); aqui se reemplazo por <OSPF-KEY>. Claves reales: canal privado del grupo.
#   El export no incluye los passwords de la comunidad SNMP 'monitor' (se agregaron <SNMP-AUTH-KEY> y <SNMP-PRIV-KEY> en esa linea),
#   ni usuarios, ni el password VRRP, ni el tcp-md5-key de BGP (ver el aviso en cada router que corresponda).
# La comunidad SNMP 'public' (por defecto, no se puede borrar en RouterOS 7) quedo con addresses=127.0.0.1/32 y read-access=no.
# Estado final de F4: SIN '/ip dhcp-client' (correccion de la devolucion de F1, ver docs/f1/correccion-dhcp-client.md).
# El export NO incluye tcp-md5-key de BGP: se agregaron <BGP-KEY-ISP1> y <BGP-KEY-ISP2> a las dos lineas de '/routing bgp connection'.
# La captura traia la linea '/system logging add action=srvsyslog topics=script' DUPLICADA; se dejo una sola (la fila repetida se borro en consola, ver f4-05h2).
# 'connect=yes' en to-ISP1 quedo explicito por el drill de 'ISP inicia la conexion' (es el valor por defecto).
/interface list add name=WAN
/interface list add name=LAN
/port set 0 name=serial0
/routing ospf instance add disabled=no name=ospf-lab originate-default=always router-id=3.3.3.3
/routing ospf area add disabled=no instance=ospf-lab name=backbone
/snmp community set [ find default=yes ] addresses=127.0.0.1/32 read-access=no
/snmp community add addresses=10.0.0.0/8,192.168.0.0/16 authentication-password=<SNMP-AUTH-KEY> authentication-protocol=SHA1 encryption-password=<SNMP-PRIV-KEY> encryption-protocol=AES name=monitor security=private
/system logging action add name=srvsyslog remote=192.168.20.100 src-address=10.255.0.1 target=remote
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
/ip firewall filter add action=accept chain=input comment=in-estab connection-state=established,related,untracked
/ip firewall filter add action=drop chain=input comment=in-invalid connection-state=invalid
/ip firewall filter add action=accept chain=input comment=in-icmp protocol=icmp
/ip firewall filter add action=accept chain=input comment=in-bgp-isp1 dst-port=179 in-interface=ether1 protocol=tcp src-address=192.0.2.1
/ip firewall filter add action=accept chain=input comment=in-bgp-isp2 dst-port=179 in-interface=ether2 protocol=tcp src-address=192.0.2.5
/ip firewall filter add action=accept chain=input comment=in-ospf in-interface-list=LAN protocol=ospf
/ip firewall filter add action=accept chain=input comment=in-ssh-lan dst-port=22 in-interface-list=LAN protocol=tcp
/ip firewall filter add action=accept chain=input comment=in-snmp-lan dst-port=161 in-interface-list=LAN protocol=udp
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
/routing bgp connection add as=65000 connect=yes disabled=no input.filter=in-isp1 local.address=192.0.2.2 .role=ebgp name=to-ISP1 output.filter-chain=out-isp1 .redistribute=ospf remote.address=192.0.2.1 .as=65001 router-id=3.3.3.3 tcp-md5-key=<BGP-KEY-ISP1>
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
/snmp set contact="Grupo 2 GOYS" enabled=yes engine-id-suffix=e0 location="Lab GNS3"
/system identity set name=EDGE
/system logging add action=srvsyslog topics=script
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool netwatch add comment=ISP-1 disabled=no down-script=":log warning \"ALERTA netwatch: ISP-1 (192.0.2.1) caido\"" host=192.0.2.1 interval=10s name=isp1 timeout=1s type=simple up-script=":log info \"netwatch: ISP-1 (192.0.2.1) recuperado\""

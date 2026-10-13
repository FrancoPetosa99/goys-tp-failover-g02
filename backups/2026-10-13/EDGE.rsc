# EDGE - /export terse hide-sensitive - RouterOS 7.14.3 - capturado 2026-10-13 21:05:19 (fase 2)
# Transcrito de la captura de pantalla (capturas/f2). Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR).
# CLAVES: el export mostraba la clave OSPF en texto plano; aqui se reemplazo por <OSPF-KEY>. Clave real: canal privado del grupo.
# El export tampoco incluye usuarios ni el password VRRP.
# Antes de reaplicar en un nodo nuevo: revisar '/interface ethernet print' (docs/f1/mapa-interfaces-e-incidente.md).
/interface ethernet set [ find default-name=ether2 ] name=ether1
/interface ethernet set [ find default-name=ether1 ] name=ether2
/port set 0 name=serial0
/routing ospf instance add disabled=no name=ospf-lab router-id=3.3.3.3
/routing ospf area add disabled=no instance=ospf-lab name=backbone
/ip neighbor discovery-settings set discover-interface-list=none
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=4096
/ip address add address=10.255.0.1 interface=lo network=10.255.0.1
/ip address add address=192.0.2.2/30 interface=ether1 network=192.0.2.0
/ip address add address=192.0.2.6/30 interface=ether2 network=192.0.2.4
/ip address add address=10.0.0.1/30 interface=ether3 network=10.0.0.0
/ip address add address=10.0.0.5/30 interface=ether4 network=10.0.0.4
/ip dhcp-client add interface=ether1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,192.168.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether3 type=ptp
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether4 type=ptp
/routing ospf interface-template add area=backbone disabled=no interfaces=lo passive
/system identity set name=EDGE
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

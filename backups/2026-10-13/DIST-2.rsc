# DIST-2 - /export terse hide-sensitive - RouterOS 7.14.3 - capturado 2026-10-13 21:51:07 (fase 2)
# Transcrito de la captura de pantalla (capturas/f2). Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR).
# CLAVES: el export mostraba la clave OSPF en texto plano; aqui se reemplazo por <OSPF-KEY>. Clave real: canal privado del grupo.
# El export tampoco incluye usuarios ni el password VRRP.
# Al restaurar, agregar el password VRRP: /interface vrrp set [find] password=<VRRP-KEY>
# Antes de reaplicar en un nodo nuevo: revisar '/interface ethernet print' (docs/f1/mapa-interfaces-e-incidente.md).
/interface ethernet set [ find default-name=ether4 ] name=ether1
/interface ethernet set [ find default-name=ether1 ] name=ether2
/interface ethernet set [ find default-name=ether2 ] name=ether3
/interface ethernet set [ find default-name=ether3 ] name=ether4
/interface vrrp add authentication=simple interface=ether4 name=vrrp10 version=2 vrid=10
/interface vrrp add authentication=simple interface=ether1 name=vrrp20 priority=150 version=2 vrid=20
/port set 0 name=serial0
/routing ospf instance add disabled=no name=ospf-lab router-id=7.7.7.7
/routing ospf area add disabled=no instance=ospf-lab name=backbone
/ip neighbor discovery-settings set discover-interface-list=none
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=4096
/ip address add address=10.255.0.22 interface=lo network=10.255.0.22
/ip address add address=10.0.0.18/30 interface=ether2 network=10.0.0.16
/ip address add address=10.0.0.26/30 interface=ether3 network=10.0.0.24
/ip address add address=192.168.10.3/24 interface=ether4 network=192.168.10.0
/ip address add address=192.168.20.3/24 interface=ether1 network=192.168.20.0
/ip address add address=192.168.10.1 interface=vrrp10 network=192.168.10.1
/ip address add address=192.168.20.1 interface=vrrp20 network=192.168.20.1
/ip dhcp-client add interface=ether1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,192.168.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether2 type=ptp
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether3 type=ptp
/routing ospf interface-template add area=backbone disabled=no interfaces=ether4 passive
/routing ospf interface-template add area=backbone disabled=no interfaces=ether1 passive
/routing ospf interface-template add area=backbone disabled=no interfaces=lo passive
/system identity set name=DIST-2
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

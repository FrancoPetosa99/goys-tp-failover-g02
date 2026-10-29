# DIST-1 - /export terse hide-sensitive - RouterOS 7.14.3 - capturado 2026-10-17 19:29:08 (fase 4, reloj del router)
# Transcrito de las capturas f4-02u1a y f4-02u1b (capturas/f4). Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR).
# Los routers no tienen NTP: su reloj (UTC) no esta sincronizado y en EDGE se midio ~25 min adelantado (ver docs/f4/ejecucion.md).
# CLAVES: el export mostraba la clave OSPF en texto plano (auth-key); aqui se reemplazo por <OSPF-KEY>. Claves reales: canal privado del grupo.
#   El export no incluye los passwords de la comunidad SNMP 'monitor' (se agregaron <SNMP-AUTH-KEY> y <SNMP-PRIV-KEY> en esa linea),
#   ni usuarios, ni el password VRRP, ni el tcp-md5-key de BGP (ver el aviso en cada router que corresponda).
# La comunidad SNMP 'public' (por defecto, no se puede borrar en RouterOS 7) quedo con addresses=127.0.0.1/32 y read-access=no.
# Estado final de F4: SIN '/ip dhcp-client' (correccion de la devolucion de F1, ver docs/f1/correccion-dhcp-client.md).
# Al restaurar, agregar el password VRRP: /interface vrrp set [find] password=<VRRP-KEY>
/interface vrrp add authentication=simple interface=ether3 name=vrrp10 priority=150 version=2 vrid=10
/interface vrrp add authentication=simple interface=ether4 name=vrrp20 version=2 vrid=20
/port set 0 name=serial0
/routing ospf instance add disabled=no name=ospf-lab router-id=6.6.6.6
/routing ospf area add disabled=no instance=ospf-lab name=backbone
/snmp community set [ find default=yes ] addresses=127.0.0.1/32 read-access=no
/snmp community add addresses=10.0.0.0/8,192.168.0.0/16 authentication-password=<SNMP-AUTH-KEY> authentication-protocol=SHA1 encryption-password=<SNMP-PRIV-KEY> encryption-protocol=AES name=monitor security=private
/ip neighbor discovery-settings set discover-interface-list=none
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=4096
/ip address add address=10.255.0.21 interface=lo network=10.255.0.21
/ip address add address=10.0.0.14/30 interface=ether1 network=10.0.0.12
/ip address add address=10.0.0.22/30 interface=ether2 network=10.0.0.20
/ip address add address=192.168.10.2/24 interface=ether3 network=192.168.10.0
/ip address add address=192.168.20.2/24 interface=ether4 network=192.168.20.0
/ip address add address=192.168.10.1 interface=vrrp10 network=192.168.10.1
/ip address add address=192.168.20.1 interface=vrrp20 network=192.168.20.1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,192.168.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether1 type=ptp
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 auth-key=<OSPF-KEY> disabled=no interfaces=ether2 type=ptp
/routing ospf interface-template add area=backbone disabled=no interfaces=ether3 passive
/routing ospf interface-template add area=backbone disabled=no interfaces=ether4 passive
/routing ospf interface-template add area=backbone disabled=no interfaces=lo passive
/snmp set contact="Grupo 2 GOYS" enabled=yes engine-id-suffix=d1 location="Lab GNS3"
/system identity set name=DIST-1
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

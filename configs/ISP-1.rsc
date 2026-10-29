# ISP-1 - /export terse hide-sensitive - RouterOS 7.14.3 - capturado 2026-10-17 20:29:42 (fase 4, reloj del router)
# Transcrito de las capturas f4-03q (capturas/f4). Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR).
# Los routers no tienen NTP: su reloj (UTC) no esta sincronizado y en EDGE se midio ~25 min adelantado (ver docs/f4/ejecucion.md).
# CLAVES: el export mostraba la clave OSPF en texto plano (auth-key); aqui se reemplazo por <OSPF-KEY>. Claves reales: canal privado del grupo.
#   El export no incluye los passwords de la comunidad SNMP 'monitor' (se agregaron <SNMP-AUTH-KEY> y <SNMP-PRIV-KEY> en esa linea),
#   ni usuarios, ni el password VRRP, ni el tcp-md5-key de BGP (ver el aviso en cada router que corresponda).
# La comunidad SNMP 'public' (por defecto, no se puede borrar en RouterOS 7) quedo con addresses=127.0.0.1/32 y read-access=no.
# Estado final de F4: SIN '/ip dhcp-client' (correccion de la devolucion de F1, ver docs/f1/correccion-dhcp-client.md).
# El export NO incluye tcp-md5-key de BGP; se agrego <BGP-KEY-ISP1> a la linea de '/routing bgp connection'. Clave real: canal privado del grupo.
/interface ethernet set [ find default-name=ether2 ] name=ether1
/interface ethernet set [ find default-name=ether1 ] name=ether2
/port set 0 name=serial0
/snmp community set [ find default=yes ] addresses=127.0.0.1/32 read-access=no
/snmp community add addresses=10.0.0.0/8,192.168.0.0/16 authentication-password=<SNMP-AUTH-KEY> authentication-protocol=SHA1 encryption-password=<SNMP-PRIV-KEY> encryption-protocol=AES name=monitor security=private
/ip neighbor discovery-settings set discover-interface-list=none
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=4096
/ip address add address=198.51.100.1 interface=lo network=198.51.100.1
/ip address add address=192.0.2.1/30 interface=ether1 network=192.0.2.0
/ip address add address=203.0.113.1 comment="Internet simulada" interface=lo network=203.0.113.1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,192.168.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/routing bgp connection add as=65001 local.address=192.0.2.1 .role=ebgp name=to-EDGE output.default-originate=always remote.address=192.0.2.2 .as=65000 router-id=198.51.100.1 tcp-md5-key=<BGP-KEY-ISP1>
/snmp set contact="Grupo 2 GOYS" enabled=yes engine-id-suffix=a1 location="Lab GNS3"
/system identity set name=ISP-1
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

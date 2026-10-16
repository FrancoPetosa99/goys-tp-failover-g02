# ISP-1 - /export terse hide-sensitive - RouterOS 7.14.3 - capturado 2026-10-14 03:37:34 (fase 3, reloj del router en UTC)
# Transcrito de la captura f3-07j (capturas/f3). Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR).
# CLAVES: el export NO incluye tcp-md5-key de BGP; se agrego <BGP-KEY-ISP1> a la linea de '/routing bgp connection'. Clave real: canal privado del grupo.
# La linea '/routing bgp connection add' se ve recortada en la captura ('router-' al borde); se completo con el comando aplicado en la sesion 1.
# Antes de reaplicar en un nodo nuevo: revisar '/interface ethernet print' (docs/f1/mapa-interfaces-e-incidente.md).
/interface ethernet set [ find default-name=ether2 ] name=ether1
/interface ethernet set [ find default-name=ether1 ] name=ether2
/port set 0 name=serial0
/ip neighbor discovery-settings set discover-interface-list=none
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=4096
/ip address add address=198.51.100.1 interface=lo network=198.51.100.1
/ip address add address=192.0.2.1/30 interface=ether1 network=192.0.2.0
/ip dhcp-client add interface=ether1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,192.168.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/routing bgp connection add as=65001 local.address=192.0.2.1 .role=ebgp name=to-EDGE output.default-originate=always remote.address=192.0.2.2 .as=65000 router-id=198.51.100.1 tcp-md5-key=<BGP-KEY-ISP1>
/system identity set name=ISP-1
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

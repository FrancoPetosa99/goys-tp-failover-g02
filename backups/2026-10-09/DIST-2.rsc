# DIST-2 - /export terse - RouterOS 7.14.3 - capturado 2026-10-09 19:21:41
# Transcrito de la captura de pantalla de la consola (docs/f1, capturas/f1).
# Se omiten las lineas '/disk set slotN slot=slotN' (ruido del CHR, cambian en cada export).
# NO incluye usuarios ni contrasenas (el export no los guarda). Usuario 'monitor' (read): ver /user print en capturas/f1.
# Antes de reaplicar en un nodo nuevo: revisar '/interface ethernet print' (ver docs/f1/mapa-interfaces-e-incidente.md).
/interface ethernet set [ find default-name=ether4 ] name=ether1
/interface ethernet set [ find default-name=ether1 ] name=ether2
/interface ethernet set [ find default-name=ether2 ] name=ether3
/interface ethernet set [ find default-name=ether3 ] name=ether4
/port set 0 name=serial0
/ip neighbor discovery-settings set discover-interface-list=none
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=4096
/ip address add address=10.255.0.22 interface=lo network=10.255.0.22
/ip address add address=10.0.0.18/30 interface=ether2 network=10.0.0.16
/ip address add address=10.0.0.26/30 interface=ether3 network=10.0.0.24
/ip address add address=192.168.10.3/24 interface=ether4 network=192.168.10.0
/ip address add address=192.168.20.3/24 interface=ether1 network=192.168.20.0
/ip dhcp-client add interface=ether1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,192.168.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/system identity set name=DIST-2
/system note set show-at-login=no
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

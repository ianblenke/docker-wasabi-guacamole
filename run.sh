#!/bin/bash
# Fail fast, including pipelines
set -eo pipefail

cat <<EOF > /etc/xrdp/xrdp.ini
[Globals]
; xrdp.ini file version number
ini_version=1

; fork a new process for each incoming connection
fork=true
; tcp port to listen
port=3389
; 'port' above should be connected to with vsock instead of tcp
use_vsock=false
; regulate if the listening socket use socket option tcp_nodelay
; no buffering will be performed in the TCP stack
tcp_nodelay=true
; regulate if the listening socket use socket option keepalive
; if the network connection disappear without close messages the connection will be closed
tcp_keepalive=true
#tcp_send_buffer_bytes=32768
#tcp_recv_buffer_bytes=32768

; security layer can be 'tls', 'rdp' or 'negotiate'
; for client compatible layer
security_layer=negotiate
; minimum security level allowed for client
; can be 'none', 'low', 'medium', 'high', 'fips'
crypt_level=high
; X.509 certificate and private key
; openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 365
certificate=
key_file=
; set SSL protocols
; can be comma separated list of 'SSLv3', 'TLSv1', 'TLSv1.1', 'TLSv1.2'
ssl_protocols=TLSv1, TLSv1.1, TLSv1.2
; set TLS cipher suites
#tls_ciphers=HIGH

; Section name to use for automatic login if the client sends username
; and password. If empty, the domain name sent by the client is used.
; If empty and no domain name is given, the first suitable section in
; this file will be used.
autorun=

allow_channels=true
allow_multimon=true
bitmap_cache=true
bitmap_compression=true
bulk_compression=true
#hidelogwindow=true
max_bpp=32
new_cursors=true
; fastpath - can be 'input', 'output', 'both', 'none'
use_fastpath=both
; when true, userid/password *must* be passed on cmd line
#require_credentials=true
; You can set the PAM error text in a gateway setup (MAX 256 chars)
#pamerrortxt=change your password according to policy at http://url

;
; colors used by windows in RGB format
;
blue=009cb5
grey=dedede
#black=000000
#dark_grey=808080
#blue=08246b
#dark_blue=08246b
#white=ffffff
#red=ff0000
#green=00ff00
#background=626c72

;
; configure login screen
;

; Login Screen Window Title
#ls_title=My Login Title

; top level window background color in RGB format
ls_top_window_bg_color=009cb5

; width and height of login screen
ls_width=350
ls_height=430

; login screen background color in RGB format
ls_bg_color=ffffff 

; optional background image filename (bmp format).
; ls_background_image=/logo.bmp

; logo
; full path to bmp-file or file in shared folder
;ls_logo_filename=/usr/local/share/xrdp/logo.bmp
;ls_logo_x_pos=75
;ls_logo_y_pos=20

; for positioning labels such as username, password etc
ls_label_x_pos=30
ls_label_width=60

; for positioning text and combo boxes next to above labels
ls_input_x_pos=110
ls_input_width=210

; y pos for first label and combo box
ls_input_y_pos=220

; OK button
ls_btn_ok_x_pos=142
ls_btn_ok_y_pos=370
ls_btn_ok_width=85
ls_btn_ok_height=30

; Cancel button
ls_btn_cancel_x_pos=237
ls_btn_cancel_y_pos=370
ls_btn_cancel_width=85
ls_btn_cancel_height=30

[Logging]
LogFile=/dev/fd/1
LogLevel=DEBUG
EnableSyslog=false
SyslogLevel=DEBUG
; LogLevel and SysLogLevel could by any of: core, error, warning, info or debug

[Channels]
; Channel names not listed here will be blocked by XRDP.
; You can block any channel by setting its value to false.
; IMPORTANT! All channels are not supported in all use
; cases even if you set all values to true.
; You can override these settings on each session type
; These settings are only used if allow_channels=true
rdpdr=true
rdpsnd=true
drdynvc=true
cliprdr=true
rail=true
xrdpvr=true
tcutils=true

; for debugging xrdp, in section xrdp1, change port=-1 to this:
#port=/tmp/.xrdp/xrdp_display_10

; for debugging xrdp, add following line to section xrdp1
#chansrvport=/tmp/.xrdp/xrdp_chansrv_socket_7210


;
; Session types
;

; Some session types such as Xorg, X11rdp and Xvnc start a display server.
; Startup command-line parameters for the display server are configured
; in sesman.ini. See and configure also sesman.ini.
[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20

[X11rdp]
name=X11rdp
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
xserverbpp=24
code=10

[Xvnc]
name=Xvnc
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=-1
#xserverbpp=24
#delay_ms=2000

[console]
name=console
lib=libvnc.so
ip=127.0.0.1
port=5900
username=na
password=ask
#delay_ms=2000

[vnc-any]
name=vnc-any
lib=libvnc.so
ip=ask
port=ask5900
username=na
password=ask
#pamusername=asksame
#pampassword=asksame
#pamsessionmng=127.0.0.1
#delay_ms=2000

[sesman-any]
name=sesman-any
lib=libvnc.so
ip=ask
port=-1
username=ask
password=ask
#delay_ms=2000

[neutrinordp-any]
name=neutrinordp-any
lib=libxrdpneutrinordp.so
ip=ask
port=ask3389
username=ask
password=ask

; You can override the common channel settings for each session type
#channel.rdpdr=true
#channel.rdpsnd=true
#channel.drdynvc=true
#channel.cliprdr=true
#channel.rail=true
#channel.xrdpvr=true
EOF

cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon = true
user = root
logfile=/dev/null
logfile_maxbytes=0

[unix_http_server]
file=/tmp/supervisor.sock   ; (the path to the socket file)

EOF

# Ensure defaults
export PORT=${PORT:-3000}

env | grep -v 'HOME\|PWD\|PATH' | while read line; do
   key="$(echo $line | cut -d= -f1)"
   value="$(echo $line | cut -d= -f2-)"
   echo "export $key=\"$value\"" >> /root/.bashrc
done

cat <<EOF > /usr/local/bin/xrdp.sh
#!/bin/bash
exec xrdp --nodaemon
EOF

chmod 755 /usr/local/bin/xrdp.sh

cat > /etc/supervisor/conf.d/xrdp.conf <<EOF
[program:xrdp]
command=/usr/local/bin/xrdp.sh
priority=10
directory=/etc/xrdp
process_name=%(program_name)s
autostart=true
autorestart=true
stopsignal=TERM
stopwaitsecs=1
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF

cat <<EOF > /usr/local/bin/xrdp-sesman.sh
#!/bin/bash
exec xrdp-sesman --nodaemon
EOF

chmod 755 /usr/local/bin/xrdp-sesman.sh

cat > /etc/supervisor/conf.d/xrdp-sesman.conf <<EOF
[program:xrdp-sesman]
command=/usr/local/bin/xrdp-sesman.sh
priority=10
directory=/etc/xrdp
process_name=%(program_name)s
autostart=true
autorestart=true
stopsignal=TERM
stopwaitsecs=1
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF

chown daemon:daemon /etc/supervisor/conf.d/ /var/run/ /var/log/supervisor/

# Add users here
groupadd -g 1000 ${RDP_USERNAME}
useradd -u 1000 -g 1000 -s /bin/bash -c "${RDP_USERNAME}" -d /home/${RDP_USERNAME} -m ${RDP_USERNAME}
usermod -p "$(openssl passwd -1 ${RDP_PASSWORD})" ${RDP_USERNAME}
usermod -g sudo "${RDP_USERNAME}"
chown -R ${RDP_USERNAME}:${RDP_USERNAME} /home/${RDP_USERNAME}

cat <<EOF > /usr/local/bin/wasabi
#!/bin/bash
cd /publish/WalletWasabi.Gui
exec dotnet run
EOF

chmod 755 /usr/local/bin/wasabi

# start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

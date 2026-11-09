#!/usr/bin/env bash
# Varredura somente leitura para Android 7 (sem root). Uso:
#   bash scripts/varredura-android7.sh SERIAL [pasta-de-saida]
# Gera varredura.txt e antes.txt. Nao altera nada no aparelho.
export MSYS_NO_PATHCONV=1
SERIAL="${1:?informe o serial (adb devices)}"
OUT="${2:-resultados}"
ADB="${ADB:-./platform-tools/adb.exe}"
A() { "$ADB" -s "$SERIAL" shell "$@" 2>&1 | tr -d '\r'; }
F="$OUT/varredura.txt"
mkdir -p "$OUT"
: > "$F"
h() { printf '\n===== %s =====\n' "$1" >> "$F"; }
r() { h "$1"; shift; A "$@" >> "$F"; }

h "DATA"; date >> "$F"
r "IDENTIDADE" 'for p in ro.product.model ro.product.manufacturer ro.build.version.release ro.build.version.sdk ro.build.display.id ro.build.version.security_patch ro.board.platform ro.boot.verifiedbootstate ro.boot.flash.locked ro.build.tags ro.build.type; do echo "$p=$(getprop $p)"; done'
r "UPTIME" uptime
r "DEVICE POLICY" dumpsys device_policy
r "USUARIOS" pm list users

r "PACOTES ATIVOS (-e)" pm list packages -e --user 0
r "PACOTES DESATIVADOS (-d)" pm list packages -d --user 0
r "PACOTES SISTEMA (-s)" pm list packages -s --user 0
r "PACOTES TERCEIROS (-3)" pm list packages -3 --user 0
r "INSTALADOR TERCEIROS (-i -3)" pm list packages -i -3 --user 0
r "PACOTES COM CAMINHO (-f)" pm list packages -f --user 0
r "DESINSTALADOS PARA O USUARIO 0 (-u menos instalados)" 'pm list packages -u --user 0 > /data/local/tmp/u.txt; pm list packages --user 0 > /data/local/tmp/i.txt; grep -vxFf /data/local/tmp/i.txt /data/local/tmp/u.txt; rm /data/local/tmp/u.txt /data/local/tmp/i.txt'

h "DETALHE DOS TERCEIROS"
for p in $(A pm list packages -3 --user 0 | sed 's/package://'); do
  echo "--- $p" >> "$F"
  A dumpsys package "$p" | grep -E 'versionName|firstInstallTime|lastUpdateTime|installerPackageName|initiatingPackageName|granted=true' >> "$F"
done

r "ACESSIBILIDADE" settings get secure enabled_accessibility_services
r "LEITURA DE NOTIFICACOES" settings get secure enabled_notification_listeners
r "ADMINS (dumpsys device_policy resumo)" 'dumpsys device_policy | grep -iE "admin|owner"'
r "SOBREPOSICAO (SYSTEM_ALERT_WINDOW, por pacote terceiro)" 'for p in $(pm list packages -3 --user 0 | cut -d: -f2); do echo "$p: $(appops get $p SYSTEM_ALERT_WINDOW)"; done'
r "INSTALAR APPS (REQUEST_INSTALL_PACKAGES)" 'echo "Android 7: permissao REQUEST_INSTALL_PACKAGES nao existe (chegou no 8). Fontes desconhecidas e global:"; settings get secure install_non_market_apps; settings get global package_verifier_enable; settings get global verifier_verify_adb_installs'
r "APPS PADRAO (Android 7 nao tem cmd role)" 'echo "dialer=$(settings get secure dialer_default_application)"; echo "sms=$(settings get secure sms_default_application)"; echo "assistant=$(settings get secure assistant)"; echo "voice_interaction=$(settings get secure voice_interaction_service)"; cmd package resolve-activity --brief -a android.intent.action.VIEW -d http://exemplo.com 2>&1 | tail -1; cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>&1 | tail -1'
r "TECLADO" 'settings get secure default_input_method; ime list -s'

r "REDE: PROXY/VPN/SCANS" 'for k in http_proxy global_http_proxy_host global_http_proxy_port global_http_proxy_exclusion_list private_dns_mode private_dns_specifier wifi_scan_always_enabled ble_scan_always_enabled mobile_data airplane_mode_on; do echo "global $k=$(settings get global $k)"; done; echo "secure always_on_vpn_app=$(settings get secure always_on_vpn_app)"'
r "REDE: dumpsys connectivity (filtrado)" 'dumpsys connectivity | grep -iE "vpn|dns|Active default network|NetworkAgentInfo" | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/<ip>/g; s/\"[^\"]*\"/<ssid>/g; s/([0-9a-f]{2}:){5}[0-9a-f]{2}/<mac>/gi"'
r "CERTIFICADOS DE USUARIO (contagem)" 'ls /data/misc/user/0/cacerts-added 2>&1 | wc -l; ls /data/misc/user/0/cacerts-added 2>&1 | head -3'
r "CONTAS (so tipos)" 'dumpsys account | grep -E "Account \{" | sed -E "s/name=[^,]*/name=<oculto>/"'

r "BATERIA" dumpsys battery
r "BATTERYSTATS --charged (resumo)" 'dumpsys batterystats --charged | grep -A60 "Estimated power use"'
r "UIDS" pm list packages -U --user 0
r "TERMICO (/sys/class/thermal)" 'for z in /sys/class/thermal/thermal_zone*; do echo "$(cat $z/type 2>&1) $(cat $z/temp 2>&1)"; done'
r "TERMICO dumpsys thermalservice" dumpsys thermalservice

r "MEMORIA /proc/meminfo" 'grep -E "MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree" /proc/meminfo'
r "MEMORIA dumpsys meminfo (Total PSS by process)" 'dumpsys meminfo | sed -n "/Total PSS by process/,/Total PSS by OOM/p"'
r "MEMORIA ZRAM/LMK" 'cat /sys/block/zram0/disksize 2>&1; cat /sys/module/lowmemorykiller/parameters/minfree 2>&1; getprop ro.config.low_ram'
r "CPU (cores, freq)" 'cat /proc/cpuinfo | grep -E "processor|Hardware" ; for c in /sys/devices/system/cpu/cpu[0-9]*; do echo "$c max=$(cat $c/cpufreq/cpuinfo_max_freq 2>&1) online=$(cat $c/online 2>&1)"; done'

r "ARMAZENAMENTO df" 'df /data; df /storage/emulated 2>&1; df /system'
r "ARMAZENAMENTO diskstats" dumpsys diskstats
r "ARMAZENAMENTO du /storage/emulated/0" 'du -s -m /storage/emulated/0/* 2>/dev/null'
r "ARMAZENAMENTO du /data/app (soma)" 'du -s -m /data/app 2>&1 | tail -1'

r "CAMERA/GALERIA pacotes" 'for p in $(pm list packages --user 0 | cut -d: -f2 | grep -iE "camera|photo|gallery|retouch"); do echo "$p $(dumpsys package $p | grep -m1 versionName) $(dumpsys package $p | grep -m1 lastUpdateTime)"; done'

r "ANIMACOES E DISPLAY" 'for k in window_animation_scale transition_animation_scale animator_duration_scale; do echo "$k=$(settings get global $k)"; done; wm size; wm density'
r "ATUALIZACAO DE SISTEMA / OTA (pacotes)" 'pm list packages --user 0 | grep -iE "ota|update|fota|adups|systemupdate"'
r "PROCESSOS EM EXECUCAO (top 1 amostra)" 'top -n 1 -m 25 2>&1'

# Oculta IPs (v4 e v6), coordenadas e forca do sinal antes de guardar
sed -i -E 's/-?[0-9]{1,3}[,.][0-9]{5,}/<coord>/g; s/([0-9a-f]{0,4}:){3,7}[0-9a-f]{0,4}(\/[0-9]+)?/<ipv6>/gi; s/([0-9]{1,3}\.){3}[0-9]{1,3}/<ip>/g; s/SignalStrength: -?[0-9]+/SignalStrength: <oculto>/' "$F"

A pm list packages -e --user 0 | sort > "$OUT/antes.txt"
echo "ok: $F"

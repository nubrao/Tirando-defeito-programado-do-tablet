#!/usr/bin/env bash
# Remove pacotes de sistema apenas para o usuario 0 (os arquivos continuam em /system).
# Uso: bash scripts/aplicar-grupo.sh SERIAL "NOME DO GRUPO" pacote1 pacote2 ...
# Registra em resultados/alteracoes.txt, removidos.txt e restaurar.bat; so grava o que realmente saiu.
# Se o aparelho nao tiver install-existing (Android 7.0, por exemplo), o pacote so volta com
# restauracao de fabrica: o script para e pede confirmacao com CONFIRMO_SEM_VOLTA=1.
export MSYS_NO_PATHCONV=1
SERIAL="$1"; GRUPO="$2"; shift 2
OUT="${OUT:-resultados}"; ADB="${ADB:-./platform-tools/adb.exe}"
A() { "$ADB" -s "$SERIAL" shell "$@" 2>&1 | tr -d '\r'; }
mkdir -p "$OUT"; [ -f "$OUT/restaurar.bat" ] || printf '@echo off\r\nrem Reinstala para o usuario 0 os pacotes removidos. Rode com o tablet conectado.\r\nset ADB=%%~dp0..\\platform-tools\\adb.exe\r\n' > "$OUT/restaurar.bat"
INSTEX=""
for c in "pm install-existing" "cmd package install-existing"; do
  A $c android | grep -qiE "unknown|usage|error" || { INSTEX="$c"; break; }
done
if [ -z "$INSTEX" ] && [ "$CONFIRMO_SEM_VOLTA" != 1 ]; then
  echo "Este Android nao tem install-existing: pacotes removidos so voltam com reset de fabrica."
  echo "Rode de novo com CONFIRMO_SEM_VOLTA=1 se o dono aprovou isso."; exit 1
fi
echo "== $GRUPO ($(date '+%Y-%m-%d %H:%M'))" | tee -a "$OUT/alteracoes.txt"
for p in "$@"; do
  if ! A pm list packages --user 0 | grep -qx "package:$p"; then echo "  $p: ausente, ignorado" | tee -a "$OUT/alteracoes.txt"; continue; fi
  r=$(A pm uninstall -k --user 0 "$p")
  echo "  $p: $r" | tee -a "$OUT/alteracoes.txt"
  if [ "$r" = "Success" ]; then
    echo "$p" >> "$OUT/removidos.txt"
    if [ -n "$INSTEX" ]; then printf '"%%ADB%%" shell %s %s\r\n' "$INSTEX" "$p" >> "$OUT/restaurar.bat"
    else printf 'rem %s: sem install-existing neste Android, so volta com reset de fabrica\r\n' "$p" >> "$OUT/restaurar.bat"; fi
  fi
done
A input keyevent KEYCODE_HOME; ping -n 4 127.0.0.1 >/dev/null 2>&1
echo "  foco: $(A dumpsys window | grep mCurrentFocus | sed 's/^ *//')" | tee -a "$OUT/alteracoes.txt"

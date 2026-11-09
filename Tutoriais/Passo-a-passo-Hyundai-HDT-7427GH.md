# Hyundai Maestro Tab HDT-7427GH: diagnóstico e limpeza por ADB

Registro do que foi feito em 09/11/2026, na ordem, com o que cada etapa mostrou. Identificadores do aparelho (rede Wi-Fi, IPs, localização) foram retirados.

## Visão geral

| Item | Valor |
| --- | --- |
| Modelo | Hyundai Maestro Tab HDT-7427GH, tablet de 7" (600x1024, 160 dpi) |
| Chip | MediaTek MT8321 (plataforma MT6580), 4 núcleos Cortex-A7 de 1,3 GHz, 32 bits |
| Memória | 980 MB de RAM e 480 MB de swap (zram) |
| Armazenamento | 4,6 GB em /data; /system com 98% de uso, o que é normal |
| Sistema | Android 7.0 (API 24), firmware `HDT_7427GH.20180123` |
| Patch de segurança | **2017-11-05** |
| Integridade | Bootloader travado, verified boot green, release-keys |
| Uso | Só Wi-Fi 2,4 GHz, sem chip, conta Google pessoal, Play Store. Vai para uma criança |
| Sintomas | Lento desde que foi comprado; o dono já tinha removido os apps que conseguiu |

## Conexão ADB

O ADB oficial foi baixado em `platform-tools` (versão 37.0.1). Primeiro `adb devices -l` veio vazio, e o Windows mostrava o tablet só como **"Dispositivo USB MTP"** com `VID_0E8D` (MediaTek):

```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' }
```

Caminho para ligar a depuração neste tablet, que usa um Android 7 quase sem personalização:

1. Configurações > **Sobre o tablet** > tocar 7 vezes em **Número da versão**.
2. Configurações > **Opções do desenvolvedor** > **Depuração USB**.
3. Aceitar "Permitir depuração USB?" marcando "Sempre permitir neste computador".

Mesmo depois de aceitar, o aparelho continuou `unauthorized` até rodar `adb kill-server`. O serial é o genérico da MediaTek, `0123456789ABCDEF`.

No Git Bash, exporte `MSYS_NO_PATHCONV=1` antes dos comandos.

## Varredura (só leitura)

Script completo: [`scripts/varredura-android7.sh`](../scripts/varredura-android7.sh).

```bash
bash scripts/varredura-android7.sh 0123456789ABCDEF resultados
```

### Comandos que não existem no Android 7

| Comando | Resultado | O que usar no lugar |
| --- | --- | --- |
| `cmd role get-role-holders` | não existe | `settings get secure sms_default_application`, `cmd package resolve-activity --brief` |
| `appops query-op` | não existe | `appops get PACOTE SYSTEM_ALERT_WINDOW` |
| `pm list packages -U` | `Unknown option: -U` | `dumpsys package PACOTE \| grep userId` |
| `dumpsys thermalservice` | `Can't find service` | `/sys/class/thermal` também dá Permission denied |
| `pm trim-caches 999G` | SecurityException (CLEAR_APP_CACHE) | Nenhum sem root |
| `pm install-existing`, `cmd package install-existing` | `Unknown command` | **Nenhum**: veja [Reversão](#reversão) |
| DNS privado | não existe (chegou no Android 9) | DNS no roteador |

### Integridade e segurança

| Verificação | Resultado |
| --- | --- |
| `ro.boot.verifiedbootstate` / `flash.locked` / `build.tags` | green / 1 / release-keys: sistema original |
| Patch de segurança | 2017-11-05: **8 anos sem correção** |
| Device Owner | Nenhum |
| Admins | `com.google.android.gms/.mdm...` (Encontre Meu Dispositivo) e `/.auth.managed.admin...`, os dois do próprio Google; conta pessoal |
| Acessibilidade, leitura de notificações, sobreposição | Nenhum |
| Proxy, VPN | Nenhum |
| Fontes desconhecidas | Desligado; verificação de apps ligada |
| Apps de terceiro | Só YouTube Kids, instalado pela Play Store |
| Busca de Wi-Fi e Bluetooth sempre ligada | Ligada |

### Pacotes de fabricante investigados

```bash
adb shell dumpsys package PACOTE | grep -E 'versionName|codePath|sharedUser|granted=true'
```

| Pacote | O que é | Decisão |
| --- | --- | --- |
| `com.adups.fota` | ADUPS FOTA 5.12, atualizador com receivers `com.library.analytics.*`, `amc.plus`, `ht.act`. Internet, sem SMS ou contatos | Removido |
| `com.adups.fota.sysoper` | Parte de sistema do ADUPS que reinicia em recovery | Removido |
| `com.baidu.map.location` | Localização por rede da Baidu, com `WRITE_SECURE_SETTINGS`. O provedor ativo era o do Google | Removido |
| `com.example` | **AutoDialer** de fábrica, com `CALL_PRIVILEGED` | Removido |
| `com.mid.autogen` | Gera endereço de Wi-Fi e Bluetooth no boot (`AutoGenAddr`, `AutoGenIMEI`) | **Mantido**: removê-lo pode quebrar o Wi-Fi |
| `com.mid.gsensorcali` | Calibração do acelerômetro | Mantido |
| `com.mid.gesture` | Gestos com a tela apagada | Mantido |

Pacotes com 60 permissões, como `com.mid.*` e `schpwronoff`, usam o `sharedUserId` do sistema. Isso é normal nesses firmwares.

### Memória, CPU e tempo de abertura

```bash
adb shell grep -E 'MemAvailable|SwapFree' /proc/meminfo
adb shell dumpsys meminfo        # Total PSS by process
adb shell dumpsys cpuinfo        # tablet parado 2 minutos
adb shell am start -W -n com.android.settings/.Settings
```

- O Google Play Services ocupa cerca de 320 MB dos 980 MB (`gms.persistent` com 176 MB e `gms` com 148 MB).
- A carga média ficou entre 9 e 24 num processador de 4 núcleos. Parte vinha do `dex2oat` compilando apps atualizados pela Play Store.
- O processo de contatos (`android.process.acore`) usou 24% da CPU com o tablet parado.
- O Chrome abriu a frio em **47,6 s** na primeira vez e em 6,4 s na segunda.
- O Play Services teve vários ANRs ("não está respondendo") antes de qualquer mudança: `IntegrityApiPersistentService`, `UnstableInternalBoundBrokerService`.

As medidas travam o tablet enquanto rodam, porque cada abertura força o fechamento e a reabertura do app.

### Navegador

O Chrome é a versão **119.0.6045.193**, a última para Android 7.0. O WebView do Google está desativado, então o Chrome faz o papel de WebView e não pode sair.

## Remoção

Script: [`scripts/aplicar-grupo.sh`](../scripts/aplicar-grupo.sh). Ele usa `pm uninstall -k --user 0`, grava só o que saiu com `Success` e confere a tela em foco depois de cada grupo.

| Grupo | Pacotes | Resultado |
| --- | --- | --- |
| A. ADUPS | 2 | Success |
| B. Baidu | 1 | Success |
| C. Serviços de chip | `stk`, `omacp`, `simprocessor` e 4 `org.simalliance.openmobileapi.*` | Success |
| D. Ferramentas de fábrica | `com.example`, `engineermode`, `factorymode`, `mtklogger`, `ygps`, `lbs.em2.ui`, `bluetooth.dtt`, `sensorhub.ui` | Success |

Depois dos grupos A e B apareceu "Google Play Services não está respondendo". O logcat mostrou que os ANRs eram das 18:00 às 18:02, antes da primeira remoção (18:12), e nenhum erro citava os pacotes removidos. O diálogo foi fechado com **Aguarde**.

Lista completa em [`removidos-HDT-7427GH.txt`](../removidos-HDT-7427GH.txt).

### Reversão

**Os pacotes removidos só voltam com restauração de fábrica.** Isso só foi descoberto depois de remover:

```text
$ adb shell pm install-existing com.android.egg
Error: unknown command 'install-existing'
$ adb shell pm install -r --user 0 /system/vendor/app/YGPS/YGPS.apk
Failure [INSTALL_FAILED_INVALID_APK: ... base.apk code is missing]
```

16 dos 18 APKs não têm `classes.dex`: o código fica em `oat/`, ao lado do APK. Os SHA-256 foram guardados na pasta de resultados.

Por isso, o `scripts/aplicar-grupo.sh` agora testa `install-existing` antes de remover qualquer coisa e para se ele não existir.

## Ajustes

```bash
adb shell settings put global wifi_scan_always_enabled 0
adb shell settings put global ble_scan_always_enabled 0
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
adb shell settings put secure location_providers_allowed -gps   # localizacao em Economia de bateria
adb shell cmd package compile -m speed-profile com.android.chrome   # e launcher3, youtube.kids, settings
```

Depois das medidas, a pedido do dono, as três escalas de animação foram para **0** (sem transições de tela). O papel de parede já era estático (`ImageWallpaper`). O Android 7 não tem a opção de acessibilidade "Remover animações", que só chegou no Android 9.

A compilação respondeu `Success` em 0 a 1 s, sem mudar o espaço livre: os apps já estavam compilados. Esse passo não teve efeito. Os ajustes continuaram valendo depois de reiniciar.

[`restaurar-HDT-7427GH.bat`](../restaurar-HDT-7427GH.bat) desfaz os ajustes.

## Antes e depois

Veja a tabela no [README](../README.md#resultados-medidos).

## Problemas encontrados

| Problema | O que foi feito |
| --- | --- |
| `unauthorized` mesmo depois de aceitar no tablet | `adb kill-server` e conectar de novo |
| `install-existing` não existe | Reversão só com reset de fábrica; o script agora testa antes |
| `pm install -r` do APK de `/system` falha | APK odex, sem código |
| "Google Play Services não está respondendo" o tempo todo | O Play Services de 2026 é pesado demais para 1 GB de RAM. Tocar em **Aguarde**. O ADB não resolve |
| `dumpsys location` e `connectivity` trazem coordenadas e IPv6 | Ocultados com `sed` antes de guardar |

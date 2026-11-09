# Tablet Android antigo mais limpo e seguro para criança

Guia, prompt e scripts para diagnosticar e limpar por ADB, sem root, um tablet Android barato e antigo. A varredura procura sinais de vírus e de rastreamento, separa o que é software do que é limite do hardware, remove o software de fábrica que não serve para nada e mede o resultado antes e depois.

Foi feito e testado em um **Hyundai Maestro Tab HDT-7427GH** (Android 7.0, MediaTek MT8321, 1 GB de RAM), só com Wi-Fi, em novembro de 2026, para ser usado por uma criança. Em outro modelo, use o [prompt com varredura](#usar-com-um-agente-de-ia) e confira cada pacote.

Inspirado em [cavaleiro-ai/Tirando-defeito-programado-dos-tablets](https://github.com/cavaleiro-ai/Tirando-defeito-programado-dos-tablets).

## Conteúdo

- [Resposta curta](#resposta-curta)
- [Resultados medidos](#resultados-medidos)
- [O que a varredura encontrou](#o-que-a-varredura-encontrou)
- [O que foi removido e o que ficou](#o-que-foi-removido-e-o-que-ficou)
- [Antes de remover: o caminho de volta](#antes-de-remover-o-caminho-de-volta)
- [O que há no repositório](#o-que-há-no-repositório)
- [Passo a passo resumido](#passo-a-passo-resumido)
- [Para entregar o tablet a uma criança](#para-entregar-o-tablet-a-uma-criança)
- [Usar com um agente de IA](#usar-com-um-agente-de-ia)
- [Problemas comuns](#problemas-comuns)
- [Limites](#limites)
- [Fontes](#fontes)
- [Licença](#licença)

## Resposta curta

O tablet **não tinha vírus encontrado pelo ADB**. Isso não prova que ele está limpo, mas ele vinha com software de fábrica questionável: um atualizador chinês com módulo de analytics (ADUPS), a localização da Baidu e ferramentas de teste da fábrica. Esses foram removidos.

A lentidão vem principalmente do **hardware**. O tablet tem 1 GB de RAM e processador de 2015, e roda um Google Play Services de 2026 que sozinho ocupa cerca de um terço da memória. Depois da limpeza e de um reinício, com o mesmo tempo de tablet ligado, Configurações passou a abrir em cerca de 0,9 s (antes, 1,6 a 1,9 s) e o Chrome em 3 a 5 s (antes, 6 a 48 s), mas o tablet continua limitado. Ele serve para YouTube Kids, vídeos e jogos simples. Navegar na web com ele é lento e inseguro.

## Resultados medidos

Medidas pelo ADB com o tablet parado, **ambas com 27 minutos de tablet ligado**. O "depois" inclui um reinício, então parte do ganho pode ser do próprio reinício: não dá para separar o efeito das remoções do efeito de reiniciar.

| Medida | Antes | Depois |
| --- | --- | --- |
| Apps ativos | 116 | 98 |
| RAM disponível | 345 MB | **464 MB** |
| Swap livre | 177 MB | 248 MB |
| Espaço livre (/data) | 2,22 GB | 2,09 GB |
| Carga média (1 min) | 9,4 | 7,4 |
| Abrir Configurações (3 vezes) | 1937 / 1632 / 1720 ms | **878 / 907 / 882 ms** |
| Abrir Chrome a frio (2 vezes) | 47,6 s / 6,4 s | **5,0 s / 2,8 s** |
| Busca de Wi-Fi e Bluetooth em segundo plano | ligada | desligada |
| Localização | Alta precisão (GPS + rede) | Economia de bateria (só rede) |
| ANRs do Play Services | pelo menos 2 (18:01 e 18:02) | 4, todos nos primeiros 7 min após reiniciar; nenhum entre 7 e 27 min |

Logo depois de reiniciar (3 minutos), o tablet fica bem pior: RAM disponível de 285 MB, carga de 17 a 22 e Configurações abrindo em mais de 5 s, porque o Play Services, a Play Store, o Fotos e o YouTube Kids carregam todos ao mesmo tempo. **Depois de ligar, espere uns 10 minutos antes de entregar à criança.**

O espaço livre caiu cerca de 130 MB por causa das atualizações e da compilação da Play Store, não da limpeza. Medidas feitas uma vez cada, sem benchmark: servem como indício, não como prova de um percentual de ganho.

Situação de cada parte:

| Parte | Situação | Evidência |
| --- | --- | --- |
| Varredura de segurança | Funciona | Rodou de ponta a ponta |
| Remoção de 18 pacotes | Funciona | `Success` em todos; tela inicial respondeu depois de cada grupo; reiniciou normal |
| Wi-Fi depois das remoções | Funciona | Conectado e validado, ping de 26 ms |
| Ajustes (busca de Wi-Fi/BLE, animações, localização) | Funciona | Continuaram valendo depois de reiniciar |
| Compilação dos apps principais | Sem efeito | Já estavam compilados |
| Limpeza de cache (`pm trim-caches`) | Indisponível | Android 7 nega a permissão |
| Reverter as remoções por ADB | **Indisponível** | Só com restauração de fábrica ([detalhes](#antes-de-remover-o-caminho-de-volta)) |
| "Google Play Services não está respondendo" | **Continua após reiniciar** | Já acontecia antes; 4 ANRs nos primeiros 7 min após o boot, nenhum entre 7 e 27 min |
| Câmera, som, Bluetooth, YouTube Kids depois das remoções | Não testado pelo ADB | Testar no uso |

## O que a varredura encontrou

O sistema estava **original**: bootloader travado, verified boot "green", release-keys. Não havia app de terceiro com acessibilidade, leitura de notificações ou sobreposição, nem proxy, VPN ou Device Owner.

| Achado | Gravidade | O que foi feito |
| --- | --- | --- |
| Patch de segurança de **novembro de 2017** e Android 7.0, sem atualização possível | Grave | Nada resolve por software. Não usar para banco, senhas ou compras |
| Chrome 119, a última versão para Android 7, sem correções desde o fim de 2023. É também o WebView do sistema | Grave | Mantido, porque o sistema precisa dele. Limitar o uso da web |
| **ADUPS FOTA**: atualizador de fábrica com módulo de analytics e tráfego. O mesmo fornecedor foi flagrado em 2016 enviando dados de celulares. Neste tablet ele não entregava atualização desde 2018 | Grave | Removido |
| **Baidu Network Location** com internet e permissão para mudar configurações seguras, sem uso | Atenção | Removido |
| Serviços de chip rodando num tablet sem chip | Atenção | Removidos |
| Ferramentas de fábrica, incluindo um AutoDialer com permissão de ligação privilegiada e o Engineer Mode | Atenção | Removidos |
| Busca de Wi-Fi e Bluetooth sempre ligada | Atenção | Desligada |
| Play Services usando cerca de 320 MB de RAM e travando (ANR) | Atenção | Sem solução por ADB |
| Conta Google do adulto no tablet da criança | Atenção | Recomendação: [conta infantil](#para-entregar-o-tablet-a-uma-criança) |

## O que foi removido e o que ficou

Lista completa, com a função de cada pacote: [`removidos-HDT-7427GH.txt`](removidos-HDT-7427GH.txt).

**Removidos (18):** `com.adups.fota`, `com.adups.fota.sysoper`, `com.baidu.map.location`, `com.android.stk`, `com.mediatek.omacp`, `com.mediatek.simprocessor`, `org.simalliance.openmobileapi.service`, `.uicc1terminal`, `.uicc2terminal`, `.eseterminal`, `com.example`, `com.mediatek.engineermode`, `com.mediatek.factorymode`, `com.mediatek.mtklogger`, `com.mediatek.ygps`, `com.mediatek.lbs.em2.ui`, `com.mediatek.bluetooth.dtt`, `com.mediatek.sensorhub.ui`.

**Mantidos de propósito:**

| Pacote | Por que fica |
| --- | --- |
| `com.mid.autogen` | Gera o endereço de Wi-Fi e Bluetooth a cada boot. Sem ele o Wi-Fi pode parar |
| `com.mid.gsensorcali` | Calibra o acelerômetro (girar a tela) |
| `com.android.chrome` | Único navegador e WebView do sistema |
| `com.google.android.apps.photos` | Única galeria do tablet |
| `com.android.phone`, `mms.service`, `providers.telephony` | Base do Android; o sistema depende deles mesmo sem chip |
| `com.mediatek.duraspeed` | Gerenciador de segundo plano da MediaTek; o guia não mexe em limitadores de processo |
| Google Play Services e Play Store | Sem eles, YouTube Kids e Play Store não funcionam |

## Antes de remover: o caminho de volta

No Android 8 ou mais novo, um app de sistema removido volta com `adb shell cmd package install-existing PACOTE`. **No Android 7.0 deste tablet, não volta:**

- `pm install-existing` e `cmd package install-existing` respondem `Unknown command`.
- Os APKs de sistema são "odex", sem o código dentro. Por isso `pm install -r /system/.../X.apk` falha com `code is missing`.

O único caminho de volta é a **restauração de fábrica**. Para um tablet que vai para uma criança e não tem dados, isso não custa nada, mas precisa ser decidido antes. O script de remoção deste repositório agora testa isso e para se não houver caminho de volta.

## O que há no repositório

| Caminho | Conteúdo |
| --- | --- |
| `Prompt-tablet-diagnostico-e-limpeza.txt` | Prompt para um agente de IA diagnosticar e limpar um tablet Android antigo, com as notas técnicas do Android 7 |
| `Tutoriais/Passo-a-passo-Hyundai-HDT-7427GH.md` | Todos os comandos usados, na ordem, com o que cada um mostrou e os problemas encontrados |
| `scripts/varredura-android7.sh` | Varredura só de leitura, adaptada para Android 7 |
| `scripts/aplicar-grupo.sh` | Remove um grupo de pacotes para o usuário 0, registra tudo e testa antes se há caminho de volta |
| `removidos-HDT-7427GH.txt` | Pacotes removidos e mantidos, com a função de cada um |
| `restaurar-HDT-7427GH.bat` | Desfaz os ajustes de configuração |

A pasta `resultados/` (relatórios com identificadores do aparelho) e `platform-tools/` ficam fora do Git.

## Passo a passo resumido

Requisitos: Windows com Git Bash, o [ADB oficial](https://dl.google.com/android/repository/platform-tools-latest-windows.zip) extraído em `platform-tools`, cabo USB de dados e a Depuração USB ligada (Configurações > Sobre o tablet > 7 toques em Número da versão; depois Opções do desenvolvedor > Depuração USB).

```bash
export MSYS_NO_PATHCONV=1
./platform-tools/adb.exe devices -l          # pegue o SERIAL

# Varredura (só leitura): gera resultados/varredura.txt e antes.txt
bash scripts/varredura-android7.sh SERIAL resultados

# Teste o caminho de volta ANTES de remover
./platform-tools/adb.exe shell pm install-existing com.android.egg

# Remover um grupo (pare e leia a seção "o caminho de volta" se o teste acima falhar)
CONFIRMO_SEM_VOLTA=1 bash scripts/aplicar-grupo.sh SERIAL "Grupo A - ADUPS" com.adups.fota com.adups.fota.sysoper

# Ajustes
./platform-tools/adb.exe shell settings put global wifi_scan_always_enabled 0
./platform-tools/adb.exe shell settings put global ble_scan_always_enabled 0
./platform-tools/adb.exe shell settings put global window_animation_scale 0.5
./platform-tools/adb.exe shell settings put global transition_animation_scale 0.5
./platform-tools/adb.exe shell settings put global animator_duration_scale 0.5
./platform-tools/adb.exe shell settings put secure location_providers_allowed -gps   # Economia de bateria

./platform-tools/adb.exe reboot
```

Não remova o Play Services, a Play Store, o Chrome (se for o WebView), o teclado, a tela inicial, a galeria, a base de telefonia nem os pacotes `com.mid.*` que geram endereço de rede e calibram sensores.

## Para entregar o tablet a uma criança

Estes passos são manuais, na tela do tablet:

1. **Tire a sua conta Google** do tablet e use uma **conta infantil supervisionada pelo Family Link**. Com a sua conta, a criança tem acesso ao seu Gmail, Drive, fotos e compras. Confira, ao configurar, se o Family Link ainda aceita Android 7.0.
2. **Play Store:** foto do perfil > Configurações > Autenticação > exigir autenticação para compras. Em Família > Controle da família, limite a classificação dos apps.
3. **YouTube Kids** no lugar do YouTube.
4. **Toque em "Aguarde"** quando aparecer "Google Play Services não está respondendo".
5. **Atualizações da Play Store:** deixe o tablet na tomada e no Wi-Fi de vez em quando para as atualizações rodarem enquanto ninguém usa. Durante a compilação dos apps, ele fica mais lento.
6. **Certificados:** Configurações > Segurança > Credenciais confiáveis > aba Usuário deve estar vazia.
7. **Sincronização:** Configurações > Contas > Google: desligue Contatos e Agenda se não usar. O processo de contatos usava 24% da CPU com o tablet parado.
8. **DNS com filtro:** o Android 7 não tem DNS privado. Para filtrar conteúdo adulto e anúncios, configure no roteador um DNS de família.

## Usar com um agente de IA

O [`Prompt-tablet-diagnostico-e-limpeza.txt`](Prompt-tablet-diagnostico-e-limpeza.txt) começa com uma varredura só de leitura, mostra um relatório com as causas de cada sintoma e só muda algo depois da sua aprovação. Ele exige testar o caminho de volta antes de remover. Preencha a parte `DADOS` e cole em um agente com acesso ao terminal do computador ligado ao tablet.

O processo foi executado de ponta a ponta só no HDT-7427GH.

## Problemas comuns

| Problema | Solução |
| --- | --- |
| `adb devices` vazio e o Windows mostra "Dispositivo USB MTP" (VID_0E8D) | A Depuração USB está desligada |
| `unauthorized` mesmo depois de aceitar no tablet | `adb kill-server` e conecte de novo |
| `Unknown command: install-existing` | Android 7.0: os removidos só voltam com restauração de fábrica |
| `pm install -r` de um APK de `/system` falha com `code is missing` | O APK é odex; não há como reinstalar assim |
| `Unknown option: -U`, `Can't find service: thermalservice`, `cmd role` | Não existem no Android 7. Veja as alternativas no [passo a passo](Tutoriais/Passo-a-passo-Hyundai-HDT-7427GH.md) |
| `pm trim-caches` com SecurityException | Indisponível no Android 7 sem root |
| Caminho vira `C:/Program Files/Git/...` | Rode com `MSYS_NO_PATHCONV=1` |
| "Google Play Services não está respondendo" | Limite do hardware. Toque em **Aguarde**. Confira no logcat (`ANR in`) se começou antes de uma mudança |
| Tablet trava durante as medidas | É esperado: cada medida fecha e reabre apps |

## Limites

- **ADB não é antivírus.** Ele mostra indícios. Não encontrar nada não prova que o aparelho está limpo.
- Um sistema sem atualização de segurança desde 2017 continua vulnerável depois da limpeza. Não use o tablet para banco, senhas ou compras.
- 1 GB de RAM não aumenta. A limpeza tira o que não serve, mas não deixa o tablet rápido.
- Este guia não faz root, não desbloqueia o bootloader e não grava ROM. Uma ROM alternativa mais nova não foi avaliada.
- Se os sinais voltarem ou algo suspeito aparecer: troque a senha da conta **a partir de outro aparelho**, ative a verificação em duas etapas e faça a restauração de fábrica.

## Fontes

- [ADB, documentação oficial do Android](https://developer.android.com/tools/adb)
- Kryptowire, novembro de 2016: firmware ADUPS em celulares enviando mensagens e registros de chamadas para servidores na China (noticiado pelo New York Times em 15/11/2016)
- [Family Link](https://families.google.com/familylink/)
- [Universal Android Debloater Next Generation](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation), lista pública usada para identificar pacotes
- [Projeto original para tablets](https://github.com/cavaleiro-ai/Tirando-defeito-programado-dos-tablets)

## Licença

[MIT](LICENSE). Você pode usar, copiar e adaptar o guia, o prompt e os scripts, desde que mantenha o aviso de autoria. Não há garantia: confira cada pacote no seu aparelho antes de remover.

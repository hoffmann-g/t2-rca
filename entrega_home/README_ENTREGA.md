# Entrega — Ambiente HOME (cassol-joao)

**T2 - Redes Avançadas - PUCRS**
Grupo: Guilherme Hoffmann, Gabriel Ottoneli, João Carvalho, Guilherme Cassol

Coleta em **2026-06-23**, rede doméstica `192.168.0.0/24`.

---

## Pipeline de monitoramento utilizado

Como o **nProbe v11 exige licença comercial paga**, usamos uma cadeia equivalente
100% open-source que cumpre o mesmo papel (geração → coleta → visualização de
fluxos NetFlow):

```
softflowd (sonda, exporta NetFlow v9)  →  netflow2ng (coletor, proxy p/ ZMQ)  →  ntopng (visualização)
        wlan0 → 127.0.0.1:2055                  → tcp://127.0.0.1:5556                 -i tcp://127.0.0.1:5556
```

Evidências do funcionamento em `terminais/03`, `terminais/04` e `ntopng/05`
(ntopng mostrando "Collecting from 1 nProbe(s)" e 10.307 flows coletados via ZMQ).

---

## Status da coleta HOME

| Item | Status |
|------|--------|
| Identificação da máquina (`machine.txt`) | ✅ |
| Captura 35 min (`home_capture.pcap`, 65 MB, ~93k pacotes) | ✅ |
| Nmap hosts + serviços + OS (`nmap_*.txt/.xml`) | ✅ |
| Evidência do pipeline (softflowd → netflow2ng → ntopng) | ✅ `terminais/` + `ntopng/05` |
| Análise ntopng (hosts, flows, apps, protocolos, destinos, banda) | ✅ `ntopng/` |
| **Análise Wireshark** (dns/tls/dhcp/icmp/arp) | ⏳ **A FAZER** — offline, do `.pcap` |

---

## Ambiente HOME — dados-chave

- **Máquina de coleta:** `cassol-joao` — IP `192.168.0.224`, MAC `f4:6a:dd:58:6e:ed`, `wlan0`
- **Gateway/rede:** `192.168.0.1` (roteador ZTE) — `192.168.0.0/24`
- **Hosts ativos:** 8

### Hosts e serviços (nmap)

| IP | Fabricante | Portas/serviços | SO |
|----|-----------|-----------------|-----|
| `192.168.0.1` | ZTE (roteador) | 53 DNS, 80 HTTP, 443 HTTPS, **52869 UPnP** | Linux 3.2–4.14 |
| `192.168.0.3` | Hon Hai | 80 HTTP (nginx) | **Sony Bravia TV** |
| `192.168.0.28` | (Apple) | 49152, 62078 | **Apple iPhone (iOS 15)** |
| `192.168.0.150` | ASRock | **3389 RDP** | **Windows 10/11** |
| `192.168.0.224` | (esta máquina) | 3000 (ntopng), 8080 (netflow2ng) | Linux 5.x–6.x |

### Observações p/ "comportamentos inesperados" (escolher 3)

1. **~50% do tráfego classificado como Remote→Remote / IPv6** — boa parte do tráfego
   doméstico (Google/QUIC) já é IPv6.
2. **UPnP (52869) aberto no roteador** — superfície de ataque conhecida.
3. **RDP (3389) exposto** num host Windows da LAN.
4. **Smart TV Sony** com HTTP/nginx ativo respondendo na rede.
5. Tráfego dominado por **TLS + QUIC/Google + DNS**.

---

## Estrutura desta pasta

```
entrega_home/
├── README_ENTREGA.md
├── dados/                    <- arquivos brutos (pcap + nmap)
├── terminais/               <- 01..04 (identificação, captura, sonda, coletor)
├── ntopng/                  <- 05..11 (pipeline + análise da monitoração)
└── (a criar) wireshark/     <- prints dos 5 filtros (A FAZER pelo grupo)
```

## Falta para fechar o trabalho (grupo)

- [ ] **University:** repetir a coleta (`collect.sh university` + pipeline).
- [ ] **Wireshark (home):** `dns`, `tls.handshake.type == 1`, `dhcp`, `icmp`, `arp`.
- [ ] **Documento ≤5 págs** + **vídeo 10–15 min**.
- [ ] Anonimizar dados sensíveis.
- [ ] Justificar no doc o uso de softflowd+netflow2ng no lugar do nProbe (licença paga).

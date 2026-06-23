# T2 - Advanced Computer Networks - PUCRS
**Group:** Guilherme Hoffmann, Gabriel Ottoneli, João Carvalho, Guilherme Cassol

---

## Requirements

Install the required tools before running:

```bash
# Arch / Manjaro
sudo pacman -S nmap tcpdump wireshark-qt
```

nProbe requires a paid license. Use **softflowd** instead (same function, open source) + ntopng via Docker:

```bash
# softflowd — NetFlow probe (replaces nProbe)
yay -S softflowd

# ntopng — via Docker
docker pull ntop/ntopng
```

---

## Step 1 — Run the collection script

Open a terminal and run:

```bash
sudo ./collect.sh home
```

The script will:
- Save machine info (hostname, IP, MAC) to `machine.txt`
- Start a **35-minute traffic capture** (locks the terminal with a countdown)
- Run **Nmap** host discovery + service/OS detection in the background
- Print the commands to start nProbe and ntopng

---

## Step 2 — Start softflowd (Terminal 2)

softflowd replaces nProbe: it captures traffic and exports NetFlow to ntopng.

Replace `<IFACE>` with your interface (e.g. `wlp2s0`, `eth0`). The script prints the exact command for your machine.

```bash
sudo softflowd -i <IFACE> -n 127.0.0.1:2055 -v 9 -t maxlife=60
```

---

## Step 3 — Start ntopng (Terminal 3)

```bash
docker run -it --net=host -p 3000:3000 ntop/ntopng -i 0.0.0.0:2055
```

Then open **http://localhost:3000** in your browser.
Default login: `admin` / `admin`

---

## Step 4 — Take screenshots during monitoring

While the 35-minute capture runs, take screenshots of:

- [ ] ntopng dashboard (hosts overview)
- [ ] Top hosts by traffic volume
- [ ] Top flows / active connections
- [ ] Protocol breakdown (pie chart)
- [ ] Top applications
- [ ] External destinations / geo map
- [ ] nProbe terminal showing flows being exported

---

## Output files

The `home/` folder will contain:

| File | Description |
|------|-------------|
| `machine.txt` | Hostname, IP, MAC, gateway, timestamp |
| `*_capture.pcap` | Full traffic capture (open in Wireshark) |
| `nmap_hosts.txt` | Host discovery results |
| `nmap_hosts.xml` | Host discovery results (XML) |
| `nmap_services.txt` | Service and OS detection results |
| `nmap_services.xml` | Service and OS detection results (XML) |
| `ntopng_data/` | ntopng database and flow data |
| `pids.txt` | PIDs of background processes |

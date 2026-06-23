# T2 - Advanced Computer Networks - PUCRS
**Group:** Guilherme Hoffmann, Gabriel Ottoneli, João Carvalho, Guilherme Cassol

---

## Requirements

Install the required tools before running:

```bash
# Arch / Manjaro
sudo pacman -S nmap tcpdump wireshark-qt
```

nProbe and ntopng are not available in the AUR. Use Docker instead:

```bash
docker pull ntop/nprobe
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

## Step 2 — Start nProbe (Terminal 2)

While the script is running, open a second terminal.

Replace `<IFACE>` with your interface (e.g. `wlp2s0`, `eth0`). The script prints the exact command for your machine.

**If installed natively:**
```bash
sudo nprobe --interface <IFACE> --ntopng zmq://127.0.0.1:5556 -b 0
```

**Via Docker:**
```bash
docker run -it --net=host ntop/nprobe --interface <IFACE> --ntopng zmq://127.0.0.1:5556 -b 0
```

---

## Step 3 — Start ntopng (Terminal 3)

Open a third terminal:

**If installed natively:**
```bash
sudo ntopng -i zmq://127.0.0.1:5556 -d ./home/ntopng_data
```

**Via Docker:**
```bash
docker run -it --net=host -p 3000:3000 ntop/ntopng -i zmq://127.0.0.1:5556
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

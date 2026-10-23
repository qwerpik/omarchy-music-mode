# Setting up CoolerControl

`music-mode` doesn't invent fan curves — it switches between two
[CoolerControl](https://gitlab.com/coolercontrol/coolercontrol) **modes** you
create once. A mode is a saved snapshot of "which profile drives which fan".

## 0. Install CoolerControl

```bash
yay -S coolercontrol            # Arch / Omarchy (AUR)
sudo systemctl enable --now coolercontrold
```

Open the CoolerControl app (or <http://localhost:11987>) and log in. The default
user is **CCAdmin**; the password you set here is the one `install.sh` asks for and
stores in `~/.config/music-mode/password` (mode 600).

Tested with coolercontrold **5.1**.

## 1. A smoothing function

Without smoothing, a quiet curve hunts up and down with every CPU spike, and the
changing pitch is more noticeable than a steady fan. Create a **Function**:

| Field | Value | Why |
| :--- | :--- | :--- |
| Name | `Music Smooth` | |
| Type | Standard | |
| Response delay | 4 s | ignore short spikes |
| Deviance | 3 °C | ignore small wobbles |
| Step size (max) | 3 % | ramp gently |
| Threshold hopping | on | still jump if it gets really hot |

## 2. Two graph profiles

Both use the CPU temperature (`temp1` / Tctl) as the source and the
`Music Smooth` function:

| °C | Music CPU Fan | Music Case Fan |
| ---: | ---: | ---: |
| 30 | 25 % | 32 % |
| 60 | 28 % | 33 % |
| 70 | 40 % | 45 % |
| 78 | 65 % | 65 % |
| 85 | 100 % | 100 % |

![Fan curves](../assets/fan-curves.svg)

The idea: nearly flat and quiet up to 60 °C (listening, browsing, light work),
a normal curve above that. Pick floors your fans can actually spin at — check the
RPM readout in CoolerControl, some fans stall below ~20 %.

Exact reference values: [`examples/music-profiles.json`](../examples/music-profiles.json).

## 3. Two modes

1. Leave every fan on its default (board / **Default Profile**) and save a mode named **`Stock`**.
2. Assign `Music CPU Fan` to the CPU fan header and `Music Case Fan` to the case
   fan header(s), then save a mode named **`Music`**.

The names matter — or point music-mode at your own names:

```bash
MUSIC_MODE_MUSIC=Quiet MUSIC_MODE_STOCK=Default music-mode toggle
```

## 4. Check

```bash
music-mode status      # {"music":false}
music-mode toggle      # {"music":true}  — CoolerControl shows Music active
music-mode stock
```

## Configuration reference

| Variable | Default | Used by |
| :--- | :--- | :--- |
| `MUSIC_MODE_API` | `http://localhost:11987` | music-mode |
| `MUSIC_MODE_USER` | `CCAdmin` | music-mode |
| `MUSIC_MODE_MUSIC` / `MUSIC_MODE_STOCK` | `Music` / `Stock` | music-mode |
| `MUSIC_MODE_PASSWORD_FILE` | `~/.config/music-mode/password` | music-mode |
| `MUSIC_GUARD_LIMIT` | `70` (°C) | guard |
| `MUSIC_GUARD_HOLD` | `10` (s) | guard |
| `MUSIC_GUARD_INTERVAL` | `2` (s) | guard |
| `MUSIC_GUARD_CPU` / `MUSIC_GUARD_GPU` | auto (`k10temp` Tccd1 → Tctl, `coretemp`; `amdgpu` edge) | guard |

Set guard variables with `systemctl --user edit music-mode-guard.service`:

```ini
[Service]
Environment=MUSIC_GUARD_LIMIT=75
```

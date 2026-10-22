function power-status --description "Display Framework 13 Pro power, battery, and display status"
    python3 -c '
import os, glob, subprocess

BLUE = "\033[1;34m"
CYAN = "\033[1;36m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
MAGENTA = "\033[1;35m"
BOLD = "\033[1m"
RESET = "\033[0m"

print(f"{BOLD}{BLUE}====================================================={RESET}")
print(f"{BOLD}{BLUE}       Framework 13 Pro Power Management Status       {RESET}")
print(f"{BOLD}{BLUE}====================================================={RESET}\n")

# AC status
ac_online = False
if os.path.exists("/sys/class/power_supply/ACAD/online"):
    with open("/sys/class/power_supply/ACAD/online", "r") as f:
        ac_online = (f.read().strip() == "1")

ac_text = f"{GREEN}󱐋 Plugged in (Mains AC){RESET}" if ac_online else f"{YELLOW}󰂁 On Battery (Discharging){RESET}"
print(f"  {BOLD}Power Source:{RESET}       {ac_text}")

# Battery status
bat_dirs = glob.glob("/sys/class/power_supply/BAT*")
if bat_dirs:
    bat = bat_dirs[0]
    cap = open(f"{bat}/capacity").read().strip()
    status = open(f"{bat}/status").read().strip()
    cycles = open(f"{bat}/cycle_count").read().strip() if os.path.exists(f"{bat}/cycle_count") else "N/A"
    voltage = int(open(f"{bat}/voltage_now").read().strip()) / 1e6 if os.path.exists(f"{bat}/voltage_now") else 0
    current = int(open(f"{bat}/current_now").read().strip()) / 1e6 if os.path.exists(f"{bat}/current_now") else 0
    watts = voltage * current
    
    bat_icon = "󱊣" if int(cap) > 80 else ("󱊢" if int(cap) > 30 else "󱊡")
    print(f"  {BOLD}Battery Level:{RESET}      {CYAN}{bat_icon} {cap}%{RESET} ({status}, {cycles} cycles)")
    if current > 0:
        print(f"  {BOLD}Power Draw:{RESET}         {YELLOW}󰚥 {watts:.2f} W{RESET} ({voltage:.2f}V @ {current:.2f}A)")
    else:
        print(f"  {BOLD}Power Draw:{RESET}         {GREEN}Idle / AC powered (0.00 W draw){RESET}")

# Display Refresh Rate
try:
    xrandr_out = subprocess.check_output(["xrandr"], text=True, stderr=subprocess.DEVNULL)
    for line in xrandr_out.splitlines():
        if "*" in line:
            parts = line.strip().split()
            res = parts[0]
            rate = [p.replace("*", "").replace("+", "") for p in parts[1:] if "*" in p][0]
            rate_color = CYAN if float(rate) > 100 else GREEN
            print(f"  {BOLD}Display Mode:{RESET}       {res} @ {rate_color}{rate} Hz{RESET}")
            break
except Exception:
    pass

# TuneD Profile
try:
    tuned_out = subprocess.check_output(["tuned-adm", "active"], text=True, stderr=subprocess.DEVNULL)
    profile = tuned_out.split(":")[-1].strip()
    prof_color = GREEN if "battery" in profile or "powersave" in profile else CYAN
    print(f"  {BOLD}TuneD Profile:{RESET}      {prof_color}{profile}{RESET}")
except Exception:
    pass

# CPU EPP
if os.path.exists("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"):
    epp = open("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference").read().strip()
    epp_color = GREEN if "power" in epp else CYAN
    print(f"  {BOLD}CPU Energy Bias:{RESET}    {epp_color}{epp}{RESET}")

# PCIe ASPM
if os.path.exists("/sys/module/pcie_aspm/parameters/policy"):
    aspm = open("/sys/module/pcie_aspm/parameters/policy").read().strip()
    active_aspm = [p[1:-1] for p in aspm.split() if p.startswith("[")][0] if "[" in aspm else aspm
    aspm_color = GREEN if "powersupersave" in active_aspm else YELLOW
    print(f"  {BOLD}PCIe ASPM Policy:{RESET}   {aspm_color}{active_aspm}{RESET}")

# NVMe Runtime PM
if os.path.exists("/sys/class/nvme/nvme0/device/power/control"):
    nvme_pm = open("/sys/class/nvme/nvme0/device/power/control").read().strip()
    nvme_color = GREEN if nvme_pm == "auto" else YELLOW
    print(f"  {BOLD}NVMe Runtime PM:{RESET}    {nvme_color}{nvme_pm}{RESET}")

print(f"\n{BOLD}{BLUE}====================================================={RESET}")
'
end

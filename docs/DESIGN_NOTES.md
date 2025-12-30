# Design Notes - init-machine

## Origin
Initial linux install script (usually Ubuntu server). 
1. Create superuser group and add user to it - modify /etc/sudoers to never ask sudo password from superuser
2. apt update, apt upgrade
3. Install basic tools like: nano, jq, net-tools (iftop), btop, htop, iotop, glances, unzip
 - ask for additional packages
4. Configure nano as default text editor and set tab to 4 spaces, add .yaml, .cs support for coloring
5. install docker "curl https://get.docker.com | bash", use normal root required install but add/create group "docker", give socket group permissions and add user to docker group -> user does not need sudo to use docker
6. reboot

# Design Notes – automount-bench

## Origin
Initial design and requirements were developed in an interactive ChatGPT session
(Jan 2025).

The goals of the project:

- Safe-ish automount of non-root disks
- One large partition by default
- UUID-based fstab entries
- Deterministic mount paths:
  - NVMe → data_nvme_N
  - SSD → data_ssd_N
  - HDD → data_hdd_N
  - USB flash → data_usb_N
- Include / exclude disk filters
- Real-world benchmarks (fio preferred, dd fallback)
- Optional destructive RAID benchmark (explicit opt-in)

## Key CLI Flags
- --include-disks /dev/sdX,/dev/nvme0n1
- --exclude-disks /dev/sdY
- --skip-benchmark
- --benchmark
- --benchmark-max-files
- --benchmark-max-filesize
- --benchmark-max-total-filesize
- --raid-benchmark (destructive)

## Safety Principles
- Root filesystem disk must never be touched
- RAID requires explicit acknowledgment
- fstab entries use UUID + nofail
- Prefer correctness over speed

## Future Ideas
- --dry-run
- --json output
- Wear-safe USB benchmarks

# Design Notes – general

## Origin
After successfully tested script (preferably on multiple distros via docker or something)
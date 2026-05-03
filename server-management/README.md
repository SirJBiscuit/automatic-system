# Server Management Scripts

Safe shutdown, reboot, and service checking scripts for your server.

## Installation

```bash
cd /tmp
git clone https://github.com/SirJBiscuit/automatic-system.git
cd automatic-system/server-management

# Make scripts executable
chmod +x *.sh

# Copy to system location (optional)
sudo cp *.sh /usr/local/bin/
```

## Usage

### Safe Shutdown

Gracefully stops all services before shutting down:

```bash
sudo ./safe-shutdown.sh
```

Or if installed to /usr/local/bin:
```bash
sudo safe-shutdown.sh
```

**What it does:**
1. Confirms you want to shutdown
2. Stops Docker containers (Pingvin, Nextcloud)
3. Stops systemd services (filebrowser, cloudflared, wings)
4. Syncs filesystems
5. Shuts down server

### Safe Reboot

Gracefully stops all services before rebooting:

```bash
sudo ./safe-reboot.sh
```

**What it does:**
1. Confirms you want to reboot
2. Stops all services gracefully
3. Syncs filesystems
4. Reboots server
5. Services auto-start on boot

### Check Services

Verify all services are running after boot:

```bash
./check-services.sh
```

**Shows status of:**
- Cloudflare Tunnel
- Filebrowser
- Filebrowser Admin Panel
- Wings (Pterodactyl)
- Docker
- Pingvin Share
- Nextcloud
- Disk usage
- Network ports

## Installing 8TB Drive

### Before Installing Drive

1. **Safe shutdown:**
   ```bash
   sudo ./safe-shutdown.sh
   ```

2. **Physically install the 8TB drive**

3. **Boot the server**

### After Installing Drive

1. **Check if drive is detected:**
   ```bash
   lsblk
   sudo fdisk -l
   ```

2. **Format the drive (if new):**
   ```bash
   # Replace /dev/sdX with your drive (e.g., /dev/sdb)
   sudo mkfs.ext4 /dev/sdX1
   ```

3. **Create mount point:**
   ```bash
   sudo mkdir -p /mnt/storage
   ```

4. **Get drive UUID:**
   ```bash
   sudo blkid /dev/sdX1
   ```

5. **Add to /etc/fstab for auto-mount:**
   ```bash
   sudo nano /etc/fstab
   ```
   
   Add line:
   ```
   UUID=your-uuid-here /mnt/storage ext4 defaults 0 2
   ```

6. **Mount the drive:**
   ```bash
   sudo mount -a
   ```

7. **Verify:**
   ```bash
   df -h | grep storage
   ```

8. **Set permissions:**
   ```bash
   sudo chown -R $USER:$USER /mnt/storage
   sudo chmod 755 /mnt/storage
   ```

9. **Configure services to use new drive:**
   - Update Pingvin Share storage path
   - Update Nextcloud data directory
   - Move existing data if needed

## Auto-Start Services

All services are configured to auto-start on boot:

### Docker Containers
- Set with `restart: unless-stopped` in docker-compose.yml
- Auto-start when Docker service starts

### Systemd Services
- Enabled with `systemctl enable <service>`
- Auto-start on boot

### Verify Auto-Start

After reboot, run:
```bash
./check-services.sh
```

## Troubleshooting

### Service didn't start after reboot

```bash
# Check service status
sudo systemctl status <service-name>

# View logs
sudo journalctl -u <service-name> -n 50

# Manually start
sudo systemctl start <service-name>
```

### Docker container didn't start

```bash
# Check container status
docker ps -a

# View logs
docker logs <container-name>

# Manually start
cd /opt/<service-name>
docker-compose up -d
```

## Quick Reference

```bash
# Safe shutdown
sudo ./safe-shutdown.sh

# Safe reboot
sudo ./safe-reboot.sh

# Check all services
./check-services.sh

# Check specific service
sudo systemctl status <service>

# Restart specific service
sudo systemctl restart <service>

# View service logs
sudo journalctl -u <service> -f
```

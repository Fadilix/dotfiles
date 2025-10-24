# Setting up virtualbox on arch (the best way)

```bash
```
```bash
sudo pacman -Syu virtualbox virtualbox-host-dkms linux-headers

# rebuild kernel modules   
sudo dkms autoinstall
```

```bash
# load modules manually
sudo modprobe vboxdrv
sudo modprobe vboxnetflt
sudo modprobe vboxnetadp
sudo modprobe vboxpci

```

```bash
# check if modules are loaded correctly
lsmod | grep vbox
```

After that you can reboot virtualbox or reboot the system

```

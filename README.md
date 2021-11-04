# acpi_ec

`acpi_ec` is a simple kernel module which takes most of its code from `ec_sys.c`
and provides a simple interface between the ACPI embedded controller and the userspace.
Its main intent is to be used with [NoteBook Fan Control](https://github.com/hirschmann/nbfc)
but you can of course install it for another purpose.
You can access to the EC simply by read/write to `/dev/ec`.

It comes with a DKMS config to automatically rebuild it with signing support and
an install script which can be easily modified for another module.
The script can generate new keys and enroll them for Secure Boot.

# Installation

## Debian

You can find `.deb` in the [releases](https://github.com/MusiKid/acpi_ec/releases/latest).

## Other distributions

You should ensure that you have `dkms` and `mokutil` installed on your computer
(`mokutil` is generally included if you have a distro which supports Secure Boot).
You also need to install the kernel sources (`linux-headers` on Debian/Ubuntu or
`kernel-devel` on RPM distros).

### Debian

```sh
sudo apt install dkms build-essential linux-headers-$(uname -r)
```

### Fedora

```sh
sudo dnf install kernel-devel dkms make
```

Then just launch:

```sh
sudo ./install.sh
```

# Removing

If you want to finally remove the module:

```sh
sudo ./uninstall.sh
```

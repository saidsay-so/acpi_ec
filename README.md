# acpi_ec

`acpi_ec` is a simple kernel module which takes most of its code from `ec_sys.c` and provides a simple interface between the ACPI embedded controller and the userspace. Its main intent is to be used with [NoteBook Fan Control](https://github.com/hirschmann/nbfc) but you can of course install it for another purpose. You can access to the EC simply by read/write to `/dev/ec`.

It comes with a DKMS config to automatically rebuild it.
The repository also contains an install script that can be easily modified for another module. The script can generate new keys and enroll them for the Secure Boot.

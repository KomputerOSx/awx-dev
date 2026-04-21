# AWX and Ansible

This directory is an AWX-friendly Ansible project for provisioning fresh Ubuntu kiosk VMs and updating them later.

## What it does

The playbooks separate the work into two phases:

1. machine-wide provisioning that AWX can do over SSH
2. first graphical login setup that must run inside the kiosk user's GNOME session

That split matters because the existing RxTerminal installer applies `gsettings` and autostart entries for the logged-in desktop user. AWX can install packages and prepare the machine, but it cannot safely apply those GNOME session settings from a headless SSH session.

## Layout

- `inventories/production/hosts.yml`: sample inventory for kiosk machines
- `inventories/production/group_vars/kiosks.yml`: common variables used by both playbooks
- `playbooks/provision-kiosk.yml`: build a fresh Ubuntu machine into a kiosk machine
- `playbooks/update-kiosks.yml`: update `rxterminal` and optionally apply OS package updates
- `files/rxterminal-session-setup.sh`: runs once on the kiosk user's first desktop login

## Prerequisites

Before using these playbooks from AWX:

1. Publish the `rxterminal` package to your APT repository.
2. Make sure the target VM already has Ubuntu installed and reachable by SSH.
3. Make sure AWX can SSH as an admin user with `sudo`.
4. Use Ubuntu Desktop or allow the playbook to install `ubuntu-desktop-minimal`.

## Inventory

Update:

- `ansible_host`
- `ansible_user`
- `kiosk_user`
- `kiosk_password_hash`
- `rxterminal_install_script_url`

Generate a password hash for the kiosk user with one of these:

```bash
mkpasswd --method=SHA-512
```

or:

```bash
openssl passwd -6
```

## AWX setup

In AWX:

1. Create a Project pointing at this repository.
2. Create an Inventory and import or manually define your hosts.
3. Create a Machine credential for SSH access.
4. Create a Job Template for `ansible/playbooks/provision-kiosk.yml`.
5. Create a Job Template for `ansible/playbooks/update-kiosks.yml`.

Recommended extra variables for the provision template:

```yaml
target_group: kiosks
```

Recommended extra variables for the update template:

```yaml
target_group: kiosks
update_os_packages: false
reboot_if_required: true
```

## Fresh machine flow

Run `playbooks/provision-kiosk.yml` against a fresh Ubuntu VM.

It will:

- install desktop and kiosk dependencies
- create the kiosk user
- enable GDM autologin for that user
- download and run your RxTerminal bootstrap installer
- place a one-shot first-login script in the kiosk user's autostart folder

On the first graphical login of the kiosk user, the helper script runs:

```bash
/opt/RxTerminal/resources/scripts/install-ubuntu.sh
```

That finalizes:

- GNOME shortcut lockdown
- user autostart registration
- kiosk launcher wiring

## Updating machines

Run `playbooks/update-kiosks.yml` to:

- refresh APT metadata
- upgrade the `rxterminal` package
- optionally install broader OS package updates
- optionally reboot if `/var/run/reboot-required` exists

## Notes

- The provision playbook assumes `gdm3` as the display manager.
- If your VM platform needs guest tools like `open-vm-tools`, add them to `kiosk_base_packages` in group vars.
- If you already have a desktop image and do not want autologin, set `kiosk_enable_autologin: false`.

# AUR GitHub Mirror Updater

A Bash script that updates Arch User Repository (AUR) packages from the official [GitHub mirror](https://github.com/archlinux/aur) when the AUR website is down or experiencing connectivity issues.

## Overview

The AUR occasionally experiences downtime or DDoS attacks that make it inaccessible. This script provides a reliable fallback by leveraging the official AUR GitHub mirror to clone, build, and update your installed AUR packages.

## Features

- ✅ **Automatic package detection** - Scans all installed AUR packages
- ✅ **Version comparison** - Only updates packages with newer versions available
- ✅ **GitHub mirror fallback** - Works when aur.archlinux.org is down
- ✅ **Dry run mode** - Preview updates before applying them
- ✅ **Force rebuild** - Rebuild packages even if versions match
- ✅ **Comprehensive error handling** - Tracks and reports failed packages
- ✅ **Color-coded output** - Easy-to-read status messages
- ✅ **Automatic cleanup** - Temporary files removed after execution

## Installation

1. Clone this repository:
```bash
git clone https://github.com/AlenBadel/aur-git-update.git
cd aur-github-updater
```

2. Make the script executable:
```bash
chmod +x aur-github-updater.sh
```

3. Run the script:
```bash
./aur-github-updater.sh
```

## Usage

### Basic Update
Check and update all AUR packages:
```bash
./aur-github-updater.sh
```

### Dry Run
Preview what would be updated without making changes:
```bash
./aur-github-updater.sh --dry-run
```

### Force Rebuild
Rebuild all packages regardless of version:
```bash
./aur-github-updater.sh --force
```

### Help
Display usage information:
```bash
./aur-github-updater.sh --help
```

## Demo Output

Here's an example of the script checking and updating AUR packages:

```
=== AUR Package Updater via GitHub Mirror ===

Scanning for installed AUR packages...
Found 30 AUR packages installed

Checking: ani-cli
  Current version: 4.10-1
  Fetching from GitHub mirror...
  Available version: 4.10-1
  ✓ Already up to date

Checking: astro-bin
  Current version: 4.15.11-1
  Fetching from GitHub mirror...
  Available version: 4.15.11-1
  ✓ Already up to date

Checking: brave-bin
  Current version: 1.70.123-1
  Fetching from GitHub mirror...
  Available version: 1.71.118-1
  → Update available!
  [DRY RUN] Would update: 1.70.123-1 → 1.71.118-1

Checking: docker-desktop
  Current version: 4.34.2-1
  Fetching from GitHub mirror...
  Available version: 4.34.3-1
  → Update available!
  [DRY RUN] Would update: 4.34.2-1 → 4.34.3-1

Checking: google-chrome
  Current version: 129.0.6668.89-1
  Fetching from GitHub mirror...
  Available version: 129.0.6668.89-1
  ✓ Already up to date

Checking: visual-studio-code-bin
  Current version: 1.94.0-1
  Fetching from GitHub mirror...
  Available version: 1.94.2-1
  → Update available!
  [DRY RUN] Would update: 1.94.0-1 → 1.94.2-1

...

=== Update Summary ===
Updated: 3
Skipped (up to date): 26
Failed: 1

Failed packages:
  pop-shell-shortcuts-git

This was a dry run. Use without --dry-run to apply updates.
```

## How It Works

1. **Package Discovery**: Uses `pacman -Qqm` to identify all foreign (AUR) packages installed on your system
2. **GitHub Clone**: For each package, clones the PKGBUILD from the [official AUR GitHub mirror](https://github.com/archlinux/aur)
3. **Version Parsing**: Extracts version information from the PKGBUILD file
4. **Version Comparison**: Uses `vercmp` to determine if an update is needed
5. **Build & Install**: Runs `makepkg -si` to build and install updated packages
6. **Cleanup**: Automatically removes temporary files after execution

## Requirements

- Arch Linux or Arch-based distribution
- `pacman` package manager
- `git` for cloning repositories
- `base-devel` package group for building packages
- Internet connection to access GitHub

## Command Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would be updated without actually updating |
| `--force` | Force rebuild all packages even if versions match |
| `--help` | Display help message and exit |

## Troubleshooting

### Package fails to clone
Some packages might not exist in the AUR or may have been removed. The script will skip these and continue with other packages.

### Build failures
If a package fails to build:
1. Check the build log in the temporary directory
2. Ensure you have all required dependencies installed
3. Try building the package manually to see detailed error messages

### Permission errors
The script needs to run `makepkg` as a regular user (not root), but will prompt for sudo password when installing packages.

## Background

The AUR GitHub mirror is maintained by the Arch Linux team as documented in the [AUR downtime instructions](https://wiki.archlinux.org/title/Arch_User_Repository#Prerequisites):

> In the case of downtime for aur.archlinux.org:
> Packages: We maintain a mirror of AUR packages on GitHub. You can retrieve a package using:
> ```
> git clone --branch <package_name> --single-branch https://github.com/archlinux/aur.git <package_name>
> ```

This script automates that process for all your installed AUR packages.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use and modify as needed.

## Disclaimer

This script builds and installs packages from the AUR. Always review PKGBUILDs before installation, especially when running without `--dry-run`. The AUR is a collection of user-submitted packages, and you should verify their contents before building.

## See Also

- [Arch User Repository Wiki](https://wiki.archlinux.org/title/Arch_User_Repository)
- [AUR GitHub Mirror](https://github.com/archlinux/aur)
- [makepkg Documentation](https://wiki.archlinux.org/title/Makepkg)

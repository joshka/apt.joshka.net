# apt.joshka.net

A small, signed APT repository for Debian and Ubuntu. Its first package is [Jujutsu], built from
the project's official static Linux release binaries rather than rebuilt with Debian's Rust
toolchain. The shared repository code accepts any valid `.deb`, so other packages can be added
without creating more Cloudflare infrastructure or another trust root.

This is a proving ground for a possible Jujutsu-maintainer-owned repository. The domain, bucket,
signing key, package builder, and upstream release source remain independent so that Jujutsu can
be handed over without taking unrelated `apt.joshka.net` packages with it.

## Supported systems

- Ubuntu 24.04 LTS or newer
- Debian 13 or newer
- `amd64` and `arm64`

Jujutsu requires Git 2.41 or newer. Ubuntu 22.04 and Debian 12 ship older Git versions, so this
repository does not claim to support them or distribute a replacement Git package.

## Install

Install the repository bootstrap package, then install Jujutsu normally:

```shell
curl -fLO https://apt.joshka.net/joshka-archive-keyring.deb
sudo dpkg -i joshka-archive-keyring.deb
sudo apt update
sudo apt install jujutsu
```

The bootstrap package installs only:

- `/usr/share/keyrings/apt.joshka.net.gpg`
- `/etc/apt/sources.list.d/apt-joshka-net.sources`

Inspect it before installation with `dpkg-deb --contents joshka-archive-keyring.deb` if desired.
APT handles ordinary upgrades, version selection, holds, and removal:

```shell
sudo apt upgrade
apt-cache policy jujutsu
sudo apt-mark hold jujutsu
sudo apt remove jujutsu joshka-archive-keyring
```

The repository signing-key fingerprint is:

```text
4AA8 DA8B 725F 982F 6D81  E970 9996 CE33 A848 3178
```

## Build locally

Podman, Docker, or Colima is the only host requirement. The build container uses Debian 13's
standard package tools. Build each Jujutsu package on its native architecture:

```shell
scripts/build-in-container 0.43.0 arm64
scripts/build-in-container 0.43.0 amd64
```

Create or select a signing key, build the bootstrap package and repository, then sign it:

```shell
fingerprint=$(scripts/generate-signing-key)
scripts/build-keyring-package "$fingerprint"
scripts/build-repository build/packages build/repository
scripts/sign-repository "$fingerprint"
cp build/packages/joshka-archive-keyring_1.1_all.deb \
  build/repository/joshka-archive-keyring.deb
```

The repository-building commands need Debian package tools. Run them in the supplied container
when those tools are not installed on the host. Test the result in a clean Debian 13 container:

```shell
scripts/test-in-container arm64 0.43.0-0jj1
```

## Add another package

Create a reproducible builder that writes one `.deb` per architecture to `build/packages/`. Then
run the same `build-repository`, `sign-repository`, test, and publish steps. Repository generation
reads package names and architectures from each `.deb` and assigns their pool paths automatically.

See [adding packages] for the exact contract and a suggested CI layout.

## Backfill Jujutsu versions

Build any selected historical tags in a batch, then assemble, sign, test, and publish once:

```shell
scripts/backfill-jj 0.40.0 0.41.0 0.42.0
```

The builder skips package files already present locally. In hosted automation, manually dispatch
the publish workflow once per version; its concurrency group serializes the runs, and every run
retains all packages referenced by the currently published indexes.

## Publish

Cloudflare R2 directly serves the static repository through its custom-domain integration. There
is no Worker, Pages project, runtime application, or database.

```shell
scripts/publish-r2 build/repository
```

Publication uploads package payloads and content-addressed indexes first, mutable indexes next,
and `InRelease` last as the commit point. Existing pool files and by-hash indexes remain available
to support pinned versions and safe concurrent updates.

See [maintainer operations] for release automation, credentials, signing-key rotation, and
handover notes.

## Jujutsu versioning policy

An upstream `0.43.0` release becomes Debian version `0.43.0-0jj1`. This has two useful properties:

- A newer upstream release from this repository upgrades an older distribution package.
- A Debian or Ubuntu package of the same upstream version, such as `0.43.0-1`, takes precedence.

This avoids an epoch and lets users move naturally between upstream and distribution packaging.

[Jujutsu]: https://www.jj-vcs.dev/
[adding packages]: docs/adding-packages.md
[maintainer operations]: docs/maintainers.md

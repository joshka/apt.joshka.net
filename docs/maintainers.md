# Maintainer operations

## Release flow

The GitHub Actions workflow checks the latest stable `jj-vcs/jj` release hourly. It does nothing
when the corresponding Debian version already appears in the published APT index. A manual
dispatch can publish a particular release or replace a package with a larger `jj` revision.

For a publication, CI:

1. Downloads the official `amd64` and `arm64` musl archives.
1. Verifies each archive against the SHA-256 digest supplied by GitHub Releases.
1. Produces `.deb` packages on native GitHub-hosted runners.
1. Downloads packages already listed in the repository so pinned versions remain available.
1. Builds and signs fresh APT indexes.
1. Uploads immutable objects first and `InRelease` last.
1. Tests clean `amd64` and `arm64` APT installations before publishing.

## GitHub configuration

The workflow needs these repository secrets:

- `APT_SIGNING_KEY`: base64-encoded secret-key export for the repository signing key.
- `CLOUDFLARE_API_TOKEN`: a token restricted to object read/write for the production R2 bucket.
- `CLOUDFLARE_ACCOUNT_ID`: the Cloudflare account containing the bucket.

Export the signing key for GitHub Actions without writing the unencrypted key to disk:

```shell
gpg --batch --export-secret-keys --armor SIGNING_KEY_FINGERPRINT | base64
```

Set the secrets with the GitHub CLI after creating the remote repository:

```shell
gh secret set APT_SIGNING_KEY
gh secret set CLOUDFLARE_API_TOKEN
gh secret set CLOUDFLARE_ACCOUNT_ID
```

## Cloudflare resources

The proving-ground deployment uses:

- Account: `502e31467029905f886e2f24662bb8fd`
- Bucket: `jj-apt`
- Custom domain: `apt.joshka.net`
- Storage class: R2 Standard
- Minimum TLS version: 1.2

The initial repository signing-key fingerprint is
`4AA8 DA8B 725F 982F 6D81 E970 9996 CE33 A848 3178`.

The custom domain is connected directly to R2. The `r2.dev` development URL remains disabled.

To recreate the infrastructure in another account, set the destination zone ID and run:

```shell
CLOUDFLARE_ZONE_ID=... scripts/provision-cloudflare
```

## Signing-key rotation

Do not replace the key in a single release. Instead:

1. Generate the new signing key.
1. Publish a new `joshka-archive-keyring` package containing both old and new public keys.
1. Allow users to receive the keyring update.
1. Sign repository metadata with both keys during the overlap period.
1. Remove the old key only after the overlap period and its announced retirement date.

The repository key covers every package at `apt.joshka.net`. The Jujutsu project should generate
and control a new project-owned key as part of a handover to a separate project archive.

## Handover checklist

1. Create a repository owned by the `jj-vcs` organization.
1. Copy the Jujutsu builder and shared archive tooling into a project-owned repository.
1. Create a project-owned R2 bucket or equivalent static object store.
1. Generate a project-owned signing key and publish an overlapping keyring update.
1. Change the repository identity, URL, Cloudflare settings, and package maintainer address.
1. Add the new upstream APT repository to Jujutsu's installation documentation.
1. Keep `apt.joshka.net` available for an announced transition period.

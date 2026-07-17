# Adding a package

The archive code is package-agnostic. A package integration owns only how its `.deb` files are
produced and tested; the shared code owns APT indexes, signatures, retained versions, and R2
publication.

## Package-builder contract

A builder must:

1. Produce valid Debian binary packages in `build/packages/`.
1. Use the Debian architecture names `amd64`, `arm64`, or `all`.
1. Produce deterministic output from a named upstream version where practical.
1. Verify downloaded artifacts against an upstream digest or signature.
1. Declare runtime dependencies in the package control metadata.
1. Test installation and one meaningful command in a clean supported distribution container.

It does not need to know the R2 bucket, domain, repository layout, or signing key.

## Typical addition

Add `scripts/build-<name>-package`, then add native architecture jobs to the publication workflow:

```shell
scripts/build-my-package 1.2.3 amd64 build/packages
scripts/build-my-package 1.2.3 arm64 build/packages
scripts/build-repository build/packages build/repository
scripts/sign-repository SIGNING_KEY_FINGERPRINT build/repository
```

`scripts/build-repository` reads `Package` and `Architecture` fields from the packages and places
them under `pool/main/` automatically. `scripts/download-existing-packages` retrieves every
package referenced by the current indexes before a rebuild, preserving older published versions.

## When to use a separate repository

Use another domain, signing key, and bucket only when the package needs a different owner or trust
policy. A future Jujutsu-maintainer handover is such a boundary; another Josh-maintained command
line tool is not.

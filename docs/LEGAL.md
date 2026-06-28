# Legal and Compliance Notes

This document summarizes legal and compliance boundaries for TabSSH / OpenTabSsh. It is not legal advice.

## Project Status

TabSSH / OpenTabSsh is an independent open source project. It is not an official Huawei, HarmonyOS, OpenHarmony, OpenAtom Foundation, OpenSSH, SSH Communications Security, or libssh2 product.

Do not use language that implies official endorsement, certification, sponsorship, or affiliation unless the project actually has written authorization or certification.

Recommended wording:

- "TabSSH for HarmonyOS"
- "Compatible with HarmonyOS"
- "HarmonyOS/OpenHarmony target artifacts"
- "Independent open source SSH client project"

Avoid wording such as:

- "Official HarmonyOS SSH client"
- "Huawei-certified SSH client"
- "OpenHarmony official SSH tool"

## License

The repository source is licensed under the MIT License unless a file states otherwise.

Third-party components remain under their own licenses. The MIT License for this repository does not relicense third-party code, SDKs, binaries, APIs, tools, or documentation.

## Third-Party Dependencies

All third-party dependencies must be documented in `THIRD_PARTY_NOTICES.md` when they are added, linked, vendored, staged, or redistributed.

Special attention is required for:

- libssh2
- OpenSSL
- zlib
- Native static libraries
- ArkTS/ohpm packages
- GitHub Actions
- SDKs and command-line tools

## SDK and Toolchain Rules

Do not commit or redistribute proprietary SDK archives, extracted SDK directories, command-line tool packages, or vendor binaries unless redistribution rights have been verified.

CI may use SDKs and tools only when their license and account terms permit the intended build use. Build logs should not reveal secrets, private SDK URLs, tokens, or account credentials.

## Signing and Credentials

Do not commit:

- Signing certificates
- Keystores
- Private keys
- SSH credentials
- User connection profiles
- API tokens
- Device credentials
- Private infrastructure logs

Unsigned release artifacts should be clearly labeled as unsigned.

## Trademark Rules

HarmonyOS, OpenHarmony, Huawei, DevEco Studio, OpenSSH, SSH, libssh2, and other names may be trademarks of their respective owners. Use names only to describe compatibility, APIs, dependencies, or build targets.

Do not use third-party marks in a way that implies official endorsement.

## Release Rules

Before publishing a release, follow `docs/RELEASE_CHECKLIST.md`.

At minimum, a release should include:

- Clear artifact names.
- Checksums.
- Whether the HAP is signed or unsigned.
- Known limitations.
- Links to `LICENSE`, `NOTICE`, `THIRD_PARTY_NOTICES.md`, and `SECURITY.md`.

## Security and Privacy

Security issues should follow `SECURITY.md`.

Do not publish exploit details, private keys, passwords, tokens, or sensitive logs in public issues.

## Maintainer Reminder

When adding a dependency or changing release packaging, update:

- `THIRD_PARTY_NOTICES.md`
- `CHANGELOG.md`
- `docs/RELEASE_CHECKLIST.md`, if the release process changes
- `README.md`, if user-facing behavior changes

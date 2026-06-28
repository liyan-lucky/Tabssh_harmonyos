# Contributing to TabSSH / OpenTabSsh

Thank you for considering a contribution. This project is an early-stage HarmonyOS/OpenHarmony SSH client, so correctness, security, license compliance, and reproducible builds are more important than feature speed.

## Before You Start

Please read:

- `README.md`
- `LICENSE`
- `NOTICE`
- `THIRD_PARTY_NOTICES.md`
- `SECURITY.md`
- `CODE_OF_CONDUCT.md`

If you are changing build, dependency, native, SSH, SFTP, credential, or release behavior, review the legal and security notes first.

## Contribution Rules

Do not commit:

- Private keys, passwords, tokens, SSH credentials, host lists, or real connection profiles.
- Signing certificates, keystores, provisioning files, or private release credentials.
- Proprietary SDK archives or extracted SDK directories.
- Third-party binaries or vendored source code without their license texts and notices.
- Logs or screenshots containing secrets, user data, device identifiers, private IPs, or internal hostnames.

## Development Guidelines

- Keep changes focused and easy to review.
- Prefer small pull requests over large mixed changes.
- Document new behavior in README or project docs when appropriate.
- Add or update third-party notices when adding dependencies.
- Avoid claiming official support, certification, or affiliation with Huawei, HarmonyOS, OpenHarmony, OpenSSH, SSH, or libssh2.
- Use clear commit messages such as `fix:`, `docs:`, `ci:`, `build:`, `security:`, or `feat:`.

## Native and Dependency Changes

If you add or update native dependencies such as libssh2, OpenSSL, zlib, or other crypto/networking libraries:

1. Record the exact version and upstream source.
2. Include the license text and copyright notice.
3. Document whether the dependency is statically linked, dynamically linked, or build-only.
4. Update `THIRD_PARTY_NOTICES.md` in the same change.
5. Confirm that release artifacts do not contain SDK files, signing secrets, or unrelated binaries.

## Security-Sensitive Changes

Extra care is required for changes involving:

- SSH authentication.
- Host-key verification.
- Password or private-key handling.
- Credential storage.
- SFTP file access.
- Native memory handling.
- Logging.
- CI secrets and release signing.

Never log passwords, private keys, tokens, or full connection profiles. Prefer explicit redaction in logs and tests.

## Build and Test Expectations

Before submitting changes, run the relevant local or CI build where possible. At minimum, verify that the project remains buildable and that changed files do not include restricted content.

For HAP artifacts, check that:

- The package contains the expected ABI only.
- `libentry.so` is present for native builds.
- SDKs, certificates, secrets, and unrelated build outputs are not packaged.

## Pull Request Checklist

Before opening a pull request:

- [ ] The change is focused and described clearly.
- [ ] No secrets, credentials, SDK archives, or signing materials are included.
- [ ] Third-party license notices are updated if dependencies changed.
- [ ] README or docs are updated if behavior changed.
- [ ] Security-sensitive changes avoid logging or storing secrets.
- [ ] Build or verification notes are included when applicable.

## Reporting Security Issues

Do not open a public issue with exploit details or sensitive logs. Follow `SECURITY.md`.

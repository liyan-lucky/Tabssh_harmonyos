# Support Policy

TabSSH / OpenTabSsh is an independent open source project. It is not an official Huawei, HarmonyOS, OpenHarmony, OpenSSH, SSH, or libssh2 support channel.

## Where to Get Help

Use GitHub issues for:

- Reproducible build failures.
- HAP packaging problems.
- HarmonyOS/OpenHarmony compatibility reports.
- UI bugs.
- SSH, SFTP, terminal, or native bridge behavior that can be reproduced without exposing secrets.
- Documentation problems.

Before opening an issue, include:

- Commit SHA or release artifact name.
- Device or emulator model.
- OS/platform version.
- ABI, such as `arm64-v8a` or `x86_64`.
- Whether the issue affects HarmonyOS, OpenHarmony, or both.
- Minimal reproduction steps.
- Redacted logs.

## What Not to Share

Do not share:

- Passwords, SSH private keys, passphrases, or tokens.
- Real hostnames, private IPs, internal network diagrams, or user connection profiles.
- Signing certificates, keystores, provisioning files, or SDK account data.
- Proprietary SDK archives or extracted SDK contents.
- Logs containing secrets or personal data.

## Security Issues

For vulnerabilities or sensitive reports, follow `SECURITY.md`. Do not post exploit details, credentials, or sensitive logs publicly.

## Unsupported Requests

The project may close or decline requests involving:

- Unlicensed redistribution of SDKs, signing materials, or third-party binaries.
- Requests to bypass platform security, steal credentials, or access systems without authorization.
- Issues caused by modified private forks that cannot be reproduced on the public repository.
- Old artifacts or commits when the issue is fixed in the current branch.

## Response Expectations

This is a community project. No guaranteed response time or commercial support agreement is provided. Maintainers will prioritize reproducible security, build, packaging, and core functionality issues.

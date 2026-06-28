# Security Policy

## Supported Versions

TabSSH / OpenTabSsh is currently in an early development stage. Unless otherwise stated, only the latest commit on the default branch and the latest published release artifacts are considered supported for security review.

| Version / Branch | Security Support |
| --- | --- |
| default branch | Supported |
| latest release | Supported |
| older commits and old artifacts | Best effort only |

## Reporting a Vulnerability

Please do not report security vulnerabilities through public issues when the report includes secrets, exploit details, private device information, user credentials, private keys, or sensitive logs.

Use a private channel controlled by the maintainer whenever possible, such as GitHub private vulnerability reporting if it is enabled for this repository. If private reporting is not available, open a public issue only with a minimal non-sensitive summary and ask for a private contact path.

A useful security report should include:

- Affected commit, branch, release, or HAP artifact name.
- Device or emulator model, OS version, and ABI when relevant.
- Whether the issue affects HarmonyOS, OpenHarmony, or both.
- Clear reproduction steps.
- Impact assessment, such as credential exposure, code execution, file disclosure, authentication bypass, network security issue, or denial of service.
- Logs with secrets removed.
- Screenshots only if they do not expose credentials, tokens, hostnames, private IPs, SSH keys, or user data.

## Sensitive Data Rules

Do not attach or commit:

- SSH passwords, private keys, passphrases, host keys, known-host databases, or connection profiles containing real infrastructure.
- Signing certificates, keystores, private signing keys, provisioning files, or SDK account credentials.
- GitHub tokens, API keys, OAuth secrets, cloud credentials, or CI secrets.
- Proprietary SDK archives or extracted proprietary SDK directories.
- Device logs that contain user data or secrets unless they have been redacted.

## Expected Response Process

The maintainers should make a best-effort attempt to:

1. Acknowledge a valid vulnerability report.
2. Reproduce and assess the issue.
3. Prepare a fix or mitigation.
4. Avoid exposing sensitive details before a fix is available.
5. Publish a security note or release note when appropriate.

No guaranteed response time is promised for this early-stage project.

## Scope

Security issues in scope include:

- Credential leakage or unsafe storage of SSH secrets.
- Logging of passwords, private keys, tokens, or connection details.
- Unsafe handling of host-key verification.
- Native memory-safety issues in N-API or SSH code.
- Unsafe file access in SFTP features.
- CI or release artifacts that accidentally include SDKs, certificates, private keys, or tokens.
- Dependency vulnerabilities in redistributed or linked third-party components.

Out of scope examples:

- Issues caused by unsupported modified forks unless reproducible on the official repository.
- Vulnerabilities in third-party SDKs or tools that are not redistributed by this repository, unless TabSSH specifically exposes users to them.
- Reports without enough information to reproduce or assess the risk.

## Disclosure and Attribution

Responsible disclosure is appreciated. Public credit may be given to reporters when requested and appropriate, but only after the issue has been fixed or otherwise addressed.

# Third-Party Notices

This document records third-party components, SDKs, tools, libraries, and platform APIs that are referenced by, used to build, or expected to be linked with TabSSH / OpenTabSsh.

The repository is licensed under the MIT License, but third-party components remain governed by their own licenses. Before distributing a release package, each dependency listed here must be reviewed against the exact version and distribution form used in that release.

## Current Repository Dependency Status

As of the current source tree:

- Root `oh-package.json5` declares no runtime or development dependencies.
- `entry/oh-package.json5` declares no runtime dependencies.
- The Native C++ build is designed to use a Mock core when third-party native SSH libraries are absent.
- Real SSH support is expected to use staged headers and static libraries under `entry/src/main/cpp/third_party`, which should not be treated as automatically licensed by this project.

## Third-Party Components

| Component | Purpose | Expected License | Repository / Source | Distribution Status | Notes |
| --- | --- | --- | --- | --- | --- |
| HarmonyOS SDK / DevEco command-line tools | Build SDK, ArkTS, native toolchain, packaging tools | Proprietary / Huawei terms | Huawei / DevEco Studio distribution channels | Not redistributed in this repository | Must not commit SDK archives, extracted SDK files, signing certificates, or proprietary toolchains. CI may download SDKs only when permitted by their license and account terms. |
| OpenHarmony SDK / APIs | Platform compatibility and build target references | OpenHarmony project terms, Apache-2.0 for many OpenHarmony source components, plus component-specific terms | OpenHarmony project distribution channels | Not redistributed in this repository | Verify the exact SDK package license before redistribution. Current CI may use HarmonyOS API tooling for OpenHarmony-named artifacts unless a true OpenHarmony SDK is supplied. |
| Node.js | CI/build runtime | MIT License | https://nodejs.org/ | Not redistributed in source repository | GitHub Actions installs/provides Node.js for build execution. |
| pnpm | Package manager used during build | MIT License | https://pnpm.io/ | Not redistributed in source repository | Installed during CI/build. Keep lockfiles and package manifests under review if dependencies are added. |
| CMake | Native build generator | BSD-3-Clause License | https://cmake.org/ | Not redistributed in source repository | Used by the HarmonyOS/OpenHarmony native build toolchain. |
| libssh2 | Planned real SSH/SFTP implementation | BSD-style license | https://www.libssh2.org/ / https://github.com/libssh2/libssh2 | Not committed by default; may be staged under `entry/src/main/cpp/third_party` for real native builds | If headers/static libraries are included or linked into release packages, include libssh2 license and copyright notice. |
| OpenSSL | TLS/crypto dependency for native SSH stack | Apache License 2.0 for OpenSSL 3.x; dual OpenSSL/SSLeay license for older versions | https://www.openssl.org/ | Not committed by default; may be staged under `entry/src/main/cpp/third_party` for real native builds | Review the exact OpenSSL version. Include required license text and notices in source and binary distributions. |
| zlib | Compression dependency for native SSH stack | zlib License | https://zlib.net/ | Not committed by default; may be staged under `entry/src/main/cpp/third_party` for real native builds | Include zlib notice if redistributed or linked. |
| ArkTS / ArkUI / N-API platform APIs | Application framework and native bridge APIs | Platform SDK terms | HarmonyOS / OpenHarmony SDKs | Not redistributed as source in this repository | API usage does not imply official endorsement or certification. |
| GitHub Actions hosted runners and marketplace actions | CI automation | Action-specific licenses and GitHub terms | GitHub Actions marketplace / action repositories | Not redistributed in release packages | Review each action version before long-term or commercial use. |

## Native Third-Party Staging Rules

If real SSH support is enabled by placing third-party native files under `entry/src/main/cpp/third_party`, the maintainer must verify and document:

1. The exact component name and version.
2. The source URL or upstream release artifact.
3. The license text and copyright notice.
4. Whether the component was modified.
5. Whether it is statically linked, dynamically linked, or only used during build.
6. Whether the release package includes source, headers, static libraries, shared libraries, or object code derived from the component.
7. Any additional attribution, notice, source-offer, export-control, cryptography, or patent notice requirement.

## Prohibited Repository Contents

Do not commit any of the following unless the project has explicit redistribution rights and the compliance impact has been reviewed:

- Proprietary SDK archives or extracted proprietary SDK directories.
- Huawei, HarmonyOS, OpenHarmony, DevEco Studio, or vendor SDK packages that are not licensed for redistribution.
- Signing certificates, keystores, private keys, passwords, tokens, API keys, SSH credentials, device credentials, or account secrets.
- Third-party binary libraries without their corresponding license and notice files.
- Vendored source code copied from third-party projects without preserving copyright notices and license text.

## Release Checklist

Before publishing a source or binary release:

- Confirm that `LICENSE`, `NOTICE`, and this file are included.
- Confirm that all third-party native libraries included in the HAP or build package are listed here.
- Confirm that the HAP does not contain SDK files, signing secrets, credentials, or unrelated build artifacts.
- Confirm that the generated package contains only the expected ABI library for its artifact name.
- Confirm that third-party license texts required for binary redistribution are included in the release notes or bundled notices.

## Maintenance Note

This file is a living inventory. It is not legal advice. When dependencies are added, updated, vendored, linked, or redistributed, update this file in the same pull request or commit.

# Release Checklist

Use this checklist before publishing any TabSSH / OpenTabSsh source release, GitHub release, or HAP artifact.

## 1. Source Tree

- [ ] `LICENSE` is present and correct.
- [ ] `NOTICE` is present and correct.
- [ ] `THIRD_PARTY_NOTICES.md` reflects all third-party dependencies included in the release.
- [ ] `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `SUPPORT.md` are present.
- [ ] `CHANGELOG.md` includes the release version and notable changes.
- [ ] No proprietary SDK archives or extracted SDK files are committed.
- [ ] No signing certificates, keystores, private keys, passwords, tokens, or SSH credentials are committed.
- [ ] No real user connection profiles, private hostnames, private IP lists, or sensitive logs are committed.

## 2. Dependencies and Licenses

- [ ] Root `oh-package.json5` dependencies are reviewed.
- [ ] `entry/oh-package.json5` dependencies are reviewed.
- [ ] Native dependencies under `entry/src/main/cpp/third_party` are reviewed.
- [ ] Any libssh2, OpenSSL, zlib, or other native dependency version is listed in `THIRD_PARTY_NOTICES.md`.
- [ ] Required third-party license texts and notices are included with the release when needed.
- [ ] No GPL, LGPL, commercial, or restricted dependency is added without explicit review.

## 3. Build and Packaging

- [ ] GitHub Actions build is green for intended release artifacts.
- [ ] Each HAP artifact contains only its expected ABI.
- [ ] `libentry.so` is present in native HAP artifacts.
- [ ] HAP artifacts do not contain SDK files, certificates, private keys, tokens, logs, temporary files, or unrelated binaries.
- [ ] HAP artifact names clearly state platform and ABI.
- [ ] Checksums are generated and included.

## 4. Platform and Trademark

- [ ] Release text does not claim official Huawei, HarmonyOS, OpenHarmony, OpenAtom Foundation, OpenSSH, SSH, or libssh2 endorsement.
- [ ] HarmonyOS/OpenHarmony references are compatibility or build-target descriptions only.
- [ ] The release does not imply certification unless actual certification exists.

## 5. Security

- [ ] Security-sensitive changes were reviewed.
- [ ] Logs do not include secrets.
- [ ] SSH credentials are not stored insecurely by new code.
- [ ] Host-key verification behavior is documented and tested when changed.
- [ ] CI logs do not reveal tokens, SDK URLs that must remain private, signing material, or credentials.

## 6. Device Verification

- [ ] Install on target HarmonyOS device or emulator.
- [ ] Install on target OpenHarmony device or emulator, if supported.
- [ ] Verify startup without crash.
- [ ] Verify connection list and edit flow.
- [ ] Verify terminal behavior.
- [ ] Verify SSH authentication and host-key handling when real native SSH is enabled.
- [ ] Verify SFTP behavior when real native SSH is enabled.

## 7. Final Release Notes

- [ ] Include artifact list.
- [ ] Include checksums.
- [ ] Mention whether artifacts are unsigned or signed.
- [ ] Mention known limitations and Mock/real SSH status.
- [ ] Link to `LICENSE`, `NOTICE`, `THIRD_PARTY_NOTICES.md`, and `SECURITY.md`.

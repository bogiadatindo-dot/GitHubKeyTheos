# GitHubKey — Theos iOS tweak

## GitHub key file
The Raw file must contain one key per line, for example:

    key:bogiadat
    key:2006

Raw URL configured in `Tweak.xm`:
`https://raw.githubusercontent.com/bogiadatindo-dot/key/refs/heads/main/key`

## Configure app scope
Edit `GitHubKey.plist` and replace `com.example.target` with the exact bundle identifier(s) of apps you own or are authorized to modify.

This project intentionally uses an explicit app allowlist. It does not inject into every app or system process.

## Build
Install Theos and an iOS SDK, then:

Rootless:
    make package THEOS_PACKAGE_SCHEME=rootless

Rootful:
    make package

The resulting Debian package is placed in `packages/`.

## Important limitations
- GitHub Raw is public, so anyone can read keys in the repository.
- A client-side check can be modified or bypassed by a determined user. It is suitable only as a basic gate, not strong licensing/security.
- Do not put a GitHub token or other secret in this tweak.
- This sample validates on each app activation and does not persist successful authorization.
- Integrate the protected feature's own entry points with an authorization state; displaying a dialog alone does not protect feature code.
- Add your own app's bundle ID(s) to the allowlist. Verify behavior on a test device first.

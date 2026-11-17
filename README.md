# Funkit for iOS

Fun deposits and withdrawals in a native iOS app, with no React Native in the
host. This package ships Funkit as prebuilt frameworks.

## Requirements

| | |
| --- | --- |
| iOS | 17.0+ |
| Xcode | The version that built the release, or newer (see the release notes) |
| Stripe rail (optional) | stripe-ios 26.13.0 up to, not including, 27.0.0 |

## Install

```swift
dependencies: [
  .package(url: "https://github.com/fun-xyz/funkit-ios", exact: "<version>")
],
targets: [
  .target(name: "YourApp", dependencies: [
    .product(name: "Funkit", package: "funkit-ios"),
    // Only with the Stripe rail.
    .product(name: "FunkitStripe", package: "funkit-ios"),
  ])
]
```

`Funkit` and the runtime frameworks it links are XCFrameworks that
download from `sdk-cdn.fun.xyz`; Xcode embeds and signs them with your app.
`FunkitStripe` is source, because it compiles against your app's own
stripe-ios.

## Verify the binaries

Fun signs each XCFramework it builds with its Apple Distribution identity,
`Apple Distribution: The Fun Group Inc. (4YX7USBGCA)`. The current certificate
expires on 2027-11-11, and later releases are signed with its renewal from the
same team. Each signature is timestamped, so a release still verifies after
its certificate expires.
`React` and `ReactNativeDependencies` keep their publisher's signature. Each
release also carries a GitHub build provenance attestation and a CycloneDX
SBOM, next to its zips:

```sh
v=<version>
base=https://sdk-cdn.fun.xyz/funkit-swift/$v
curl -fsSL --remote-name-all $base/{SHA256SUMS,attestation.sigstore.json,Funkit.xcframework.zip}
gh attestation verify SHA256SUMS --bundle attestation.sigstore.json \
  --repo fun-xyz/funkit-swift \
  --signer-workflow fun-xyz/funkit-swift/.github/workflows/release.yml \
  --source-ref refs/tags/$v
shasum -a 256 --ignore-missing -c SHA256SUMS
ditto -x -k Funkit.xcframework.zip . && codesign --verify --strict Funkit.xcframework
codesign -dvv Funkit.xcframework 2>&1 | grep TeamIdentifier  # TeamIdentifier=4YX7USBGCA
```

The SBOM, `sbom.cdx.json`, lists every XCFramework with its zip's SHA-256,
the CocoaPods and npm packages inside them, and the Swift packages this
package declares. Check it the same way:

```sh
curl -fsSL --remote-name-all $base/{sbom.cdx.json,sbom.sigstore.json}
gh attestation verify sbom.cdx.json --bundle attestation.sigstore.json \
  --repo fun-xyz/funkit-swift \
  --signer-workflow fun-xyz/funkit-swift/.github/workflows/release.yml \
  --source-ref refs/tags/$v
gh attestation verify Funkit.xcframework.zip --bundle sbom.sigstore.json \
  --predicate-type https://cyclonedx.org/bom \
  --repo fun-xyz/funkit-swift \
  --signer-workflow fun-xyz/funkit-swift/.github/workflows/release.yml \
  --source-ref refs/tags/$v
```

It needs the GitHub CLI 2.102.0 or later, but no GitHub account. Offline,
add `--custom-trusted-root trusted_root.jsonl`, saved earlier with
`gh attestation trusted-root > trusted_root.jsonl`.

## Switching over outcomes

`Funkit` is built with library evolution, so later versions may add
cases to its enums. Add `@unknown default` to every `switch` over one:

```swift
switch try await funkit.deposit(depositConfig) {
case .submitted(let orderID, _): log(orderID) // not settled: credit from your webhook
case .closed: break
@unknown default: break
}
```

The integration guide covers configuration, presenting the flows, the
Stripe rail and the entitlements each provider needs.

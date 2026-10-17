# Funkit for iOS

Fun deposits and withdrawals in a native iOS app, with no React Native in the
host. This package ships Funkit as prebuilt frameworks.

## Requirements

| | |
| --- | --- |
| iOS | 17.0+ |
| Xcode | The version that built the release, or newer (see the release notes) |
| Stripe rail (optional) | stripe-ios 26.9.0 up to, not including, 27.0.0 |

## Install

```swift
dependencies: [
  .package(url: "https://github.com/fun-xyz/funkit-ios", exact: "<version>")
],
targets: [
  .target(name: "YourApp", dependencies: [
    .product(name: "FunkitConnect", package: "funkit-ios"),
    // Only with the Stripe rail.
    .product(name: "FunkitStripe", package: "funkit-ios"),
  ])
]
```

`FunkitConnect` and the runtime frameworks it links are XCFrameworks that
download from `sdk-cdn.fun.xyz`; Xcode embeds and signs them with your app.
`FunkitStripe` is source, because it compiles against your app's own
stripe-ios.

## Switching over outcomes

`FunkitConnect` is built with library evolution, so later versions may add
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

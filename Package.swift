// swift-tools-version: 6.0
// Funkit as binaries: the package clients add. The release copies this
// directory to the public repository, with FunkitStripe's source in place of
// the symlink.
//
// Funkit ships compiled, with library evolution, from
// scripts/build-xcframework.sh. FunkitStripe ships as source: it compiles
// against the host's own stripe-ios, which SPM builds without library
// evolution, so a prebuilt copy would break on the host's next Stripe update.
import PackageDescription

// BEGIN BINARY TARGETS
let shellFrameworks: [Target] = [
  .binaryTarget(
    name: "FunkitShell",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/FunkitShell.xcframework.zip",
    checksum: "9b4bf6fd8046e2fd99b3466b9dbd88dbc60fb04bea55e7f3c3c03e1a4f848bd1"
  ),
  .binaryTarget(
    name: "ExpoBrownfield",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/ExpoBrownfield.xcframework.zip",
    checksum: "e51771694373b2cba61fd3ea9d8eee4f5ccd8e9a3cdb6d9126bcd11e91636775"
  ),
  .binaryTarget(
    name: "ExpoFileSystem",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/ExpoFileSystem.xcframework.zip",
    checksum: "0d1a5eb3c381aa0e15febc55bef2ca20d81d2a2d6741f3610ce244d0469f61d6"
  ),
  .binaryTarget(
    name: "ExpoFont",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/ExpoFont.xcframework.zip",
    checksum: "09aa6940441e0b7e67042c0e9eb1cf029043e93819ff985247e148bd560eb307"
  ),
  .binaryTarget(
    name: "ExpoModulesCore",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/ExpoModulesCore.xcframework.zip",
    checksum: "eac9ec467fb8ea796c98bc996ad263e896e44c04c4b71dee285af60a842ab45f"
  ),
  .binaryTarget(
    name: "ExpoModulesJSI",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/ExpoModulesJSI.xcframework.zip",
    checksum: "1154192d1f88d481f3d164ebe3b8c42113f8c7b868fcc39501e5ffab33a79528"
  ),
  .binaryTarget(
    name: "ExpoModulesWorklets",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/ExpoModulesWorklets.xcframework.zip",
    checksum: "99cc7bf5b8769d16bcd749cff628171e420dc1d297822f06473b6b4cfae42451"
  ),
  .binaryTarget(
    name: "Funkit",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/Funkit.xcframework.zip",
    checksum: "2fdf6034aeee129b4206b3cce77fe1de50be6a52c5907a2a65167db540e030a6"
  ),
  .binaryTarget(
    name: "IdensicMobileSDK",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/IdensicMobileSDK.xcframework.zip",
    checksum: "82e784fc55e26bb671106eae50c19a95e222fbf141bbc0a33758f8c81dc4e712"
  ),
  .binaryTarget(
    name: "React",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/React.xcframework.zip",
    checksum: "94a9f12ac8ebb22c936c3ed12b98c66dd7cc00b517e28a8050cb115c38baccce"
  ),
  .binaryTarget(
    name: "ReactNativeDependencies",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/ReactNativeDependencies.xcframework.zip",
    checksum: "97c886a511c55a4d7cc57f612ced76c7dfe1c7785f2cc52b4c8948ed5f7a2e90"
  ),
  .binaryTarget(
    name: "hermesvm",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.10/hermesvm.xcframework.zip",
    checksum: "d7ae65e954b85f93b6de0593b106eeab6afbd564bc646a0bdf15bb35a0289911"
  ),
]
// END BINARY TARGETS

/// Funkit and the runtime frameworks it links. A host must embed every
/// one, so both products carry them all.
let runtime: [Target.Dependency] = shellFrameworks.map { .target(name: $0.name) }

let package = Package(
  name: "funkit-ios",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Funkit", targets: shellFrameworks.map(\.name)),
    .library(name: "FunkitStripe", targets: ["FunkitStripe"]),
  ],
  dependencies: [
    // Keep in step with the range in fun-xyz/funkit-swift's Package.swift.
    .package(url: "https://github.com/stripe/stripe-ios-spm", "26.13.0"..<"27.0.0")
  ],
  targets: shellFrameworks + [
    .target(
      name: "FunkitStripe",
      dependencies: runtime + [
        .product(name: "StripeCryptoOnramp", package: "stripe-ios-spm"),
        .product(name: "StripePaymentSheet", package: "stripe-ios-spm"),
        .product(name: "StripeApplePay", package: "stripe-ios-spm"),
      ],
      swiftSettings: [.swiftLanguageMode(.v5)]
    )
  ]
)

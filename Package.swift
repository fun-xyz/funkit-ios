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
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/FunkitShell.xcframework.zip",
    checksum: "94950e6ca0cc68db5ec0dc0bf8701b32c128231aad756202e5a49f3753bd69f6"
  ),
  .binaryTarget(
    name: "ExpoBrownfield",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/ExpoBrownfield.xcframework.zip",
    checksum: "d653b0563bd32ae3a7378ba53660c346a5d8cd80b6c125059981ead95dff94f3"
  ),
  .binaryTarget(
    name: "ExpoFileSystem",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/ExpoFileSystem.xcframework.zip",
    checksum: "55edc6431757a7b62d07323bf76e2d32b3fc1de8a0f29b33f5ae8b2d1da490d0"
  ),
  .binaryTarget(
    name: "ExpoFont",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/ExpoFont.xcframework.zip",
    checksum: "2a9b21c7d305e77e0fac46a9c707697e9b1cc48fbac0417bdbe5bc6c5eb65d8d"
  ),
  .binaryTarget(
    name: "ExpoModulesCore",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/ExpoModulesCore.xcframework.zip",
    checksum: "aecf8785b818f29d2297a425bf3faf4b4f68eaa4973fc6858a45eade6fa94654"
  ),
  .binaryTarget(
    name: "ExpoModulesJSI",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/ExpoModulesJSI.xcframework.zip",
    checksum: "36013374f7ebe8a003c501494780cee36518eec9c58dd28d6477eabd613e2b83"
  ),
  .binaryTarget(
    name: "ExpoModulesWorklets",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/ExpoModulesWorklets.xcframework.zip",
    checksum: "612bd2e091186e7a7b81c61f4ef53b06d7fecfb6164b823fb9d9f5d72693a0f7"
  ),
  .binaryTarget(
    name: "Funkit",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/Funkit.xcframework.zip",
    checksum: "47183d126a8901d8be456ae794c52d5d1d37f1ae169221d5964506e331121e90"
  ),
  .binaryTarget(
    name: "IdensicMobileSDK",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/IdensicMobileSDK.xcframework.zip",
    checksum: "1afbae95e45be941770ffefe24e3d842cf3bb4ed4147c1a6ef4bef5a53e4aeaa"
  ),
  .binaryTarget(
    name: "React",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/React.xcframework.zip",
    checksum: "838ab6705dd3e8f93c3639f34f9daff8da819adfbbde694de1ecf3fb434b8b7f"
  ),
  .binaryTarget(
    name: "ReactNativeDependencies",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/ReactNativeDependencies.xcframework.zip",
    checksum: "5e6f267276e6481e3e1415cc7932998f21f5e5f8ef8cc140067239d693cd025e"
  ),
  .binaryTarget(
    name: "hermesvm",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.9/hermesvm.xcframework.zip",
    checksum: "844d8f81f2b214b16d908012890781ecfd5d633670e08d22ddd28f61c84c3ed7"
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

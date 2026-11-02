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
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/FunkitShell.xcframework.zip",
    checksum: "af71c1ac82a83e4e1f928b3c8ff3e502ebd073bda0570902174ee80641f8a070"
  ),
  .binaryTarget(
    name: "ExpoBrownfield",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/ExpoBrownfield.xcframework.zip",
    checksum: "54095a0a5e6c3df71acf28ebb6605b77f6ba90ebc227f4fc2b209e5f111aed43"
  ),
  .binaryTarget(
    name: "ExpoFileSystem",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/ExpoFileSystem.xcframework.zip",
    checksum: "753747d1c38d1968ec6790369aef14b7e76b80960399dcf97a9a942054b46aeb"
  ),
  .binaryTarget(
    name: "ExpoFont",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/ExpoFont.xcframework.zip",
    checksum: "0dc9c9bffc5dfda604908b2b92ee365d26e62ab0fa287b7f69923fce3c1fbd07"
  ),
  .binaryTarget(
    name: "ExpoModulesCore",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/ExpoModulesCore.xcframework.zip",
    checksum: "9f51946de147fd6bf181ef422061af1ea092a3549e0053b981206a8121e38aab"
  ),
  .binaryTarget(
    name: "ExpoModulesJSI",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/ExpoModulesJSI.xcframework.zip",
    checksum: "e6097605cc3545b66712496d3ea5e47a45cb8fabd6064ddfcc9a2a0246f0afb3"
  ),
  .binaryTarget(
    name: "ExpoModulesWorklets",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/ExpoModulesWorklets.xcframework.zip",
    checksum: "ea2b46cd52f5297092ef068cc98d96f1bb2a928cfece685d36c91f4012165d8f"
  ),
  .binaryTarget(
    name: "Funkit",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/Funkit.xcframework.zip",
    checksum: "cb235334aeb887cdb011d2743514b4ee00441fa36326a7ac39bd92f23f9b902f"
  ),
  .binaryTarget(
    name: "IdensicMobileSDK",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/IdensicMobileSDK.xcframework.zip",
    checksum: "5cc8d52e7a38c90d7ca01601833472f6652e199e17394b2ceb580ff50cbb1599"
  ),
  .binaryTarget(
    name: "React",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/React.xcframework.zip",
    checksum: "33dadcfc35f5d94d6ac12bb2709b4cddacc02681ba78b8ecfd334d72c3c08e76"
  ),
  .binaryTarget(
    name: "ReactNativeDependencies",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/ReactNativeDependencies.xcframework.zip",
    checksum: "abf37f635d71bf42f6c99181effd723ec4c1757e1ff6b76b6bdd421aff0a47cb"
  ),
  .binaryTarget(
    name: "hermesvm",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.7/hermesvm.xcframework.zip",
    checksum: "62544396da05a0ddfdc79f03aca8c8a56d97554449cf2f43cbfb9eebfd51735b"
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

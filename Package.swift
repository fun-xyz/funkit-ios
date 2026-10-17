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
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/FunkitShell.xcframework.zip",
    checksum: "4fc054316d380e9813dd7b2fbbd6eafbe2c4a3b240240dac217b15afdbc11978"
  ),
  .binaryTarget(
    name: "ExpoBrownfield",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/ExpoBrownfield.xcframework.zip",
    checksum: "af5e4ad58e736b0cc9e6ec2dfea86cd99b5dd8c8e8c2183db5b460334a788595"
  ),
  .binaryTarget(
    name: "ExpoFileSystem",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/ExpoFileSystem.xcframework.zip",
    checksum: "40e52a80d4ecf1c764c8fe5bb737de1e9d6693b5baa029e1eced236f08974906"
  ),
  .binaryTarget(
    name: "ExpoFont",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/ExpoFont.xcframework.zip",
    checksum: "e0790e08e872416762c09d8b05a6a47673934493a0ba3183c8a292c23c392a97"
  ),
  .binaryTarget(
    name: "ExpoModulesCore",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/ExpoModulesCore.xcframework.zip",
    checksum: "f7cad51a824e964c44da5a89c313112a25b2c15c0518d568fd0e390083186594"
  ),
  .binaryTarget(
    name: "ExpoModulesJSI",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/ExpoModulesJSI.xcframework.zip",
    checksum: "38459b0721af63a26ce23109980a982c38c43dd426783bb716825555c2b73503"
  ),
  .binaryTarget(
    name: "ExpoModulesWorklets",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/ExpoModulesWorklets.xcframework.zip",
    checksum: "5f89937d46d203d232be60cb80c4c53ba75f9d0b4f8191061420c6c62b77f125"
  ),
  .binaryTarget(
    name: "Funkit",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/Funkit.xcframework.zip",
    checksum: "9d8a3893bd96625d2a93a297bc6ffb469ee10d2935c3225b10a4340d94e1467c"
  ),
  .binaryTarget(
    name: "IdensicMobileSDK",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/IdensicMobileSDK.xcframework.zip",
    checksum: "e66131990b88638443627f7195569da1549b1f3ca5680a2009a36a0fc05deaa5"
  ),
  .binaryTarget(
    name: "React",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/React.xcframework.zip",
    checksum: "e18f863c546afbd34ee5e8071924976f3ba1c29d7f9e7344dffdb36638d1b2de"
  ),
  .binaryTarget(
    name: "ReactNativeDependencies",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/ReactNativeDependencies.xcframework.zip",
    checksum: "509825e5dea7d63c1958cf5b7faf80944e628d48b2fb8e10bb8fa2bae0a9ed61"
  ),
  .binaryTarget(
    name: "hermesvm",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.4/hermesvm.xcframework.zip",
    checksum: "f888faa5a3db171339f050008c5c19540e8f14285681ab8470e66f4850d80a4f"
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
    .package(url: "https://github.com/stripe/stripe-ios-spm", "26.9.0"..<"27.0.0")
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

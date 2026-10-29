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
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/FunkitShell.xcframework.zip",
    checksum: "9fe5697089a8377228d18613d7b77d1e29be0e0bb000665b7295b57ab1f9b90f"
  ),
  .binaryTarget(
    name: "ExpoBrownfield",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/ExpoBrownfield.xcframework.zip",
    checksum: "64ac3220950c0f833e4c234d979ec0351f52b28b95e8066bb856685ffcc08765"
  ),
  .binaryTarget(
    name: "ExpoFileSystem",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/ExpoFileSystem.xcframework.zip",
    checksum: "d16da540d8a50f9a44676903e20686f3a1a6180c70c568edc0bfe00c141e04b6"
  ),
  .binaryTarget(
    name: "ExpoFont",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/ExpoFont.xcframework.zip",
    checksum: "6bbf5e2b80a68f19a0f705719af3f7f9b154794805013b9bca522c91fd8eb33b"
  ),
  .binaryTarget(
    name: "ExpoModulesCore",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/ExpoModulesCore.xcframework.zip",
    checksum: "c3764050f7103a7cfae35ad7deaae3e81dc69ed410f2b2e9e9dc2b517c526582"
  ),
  .binaryTarget(
    name: "ExpoModulesJSI",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/ExpoModulesJSI.xcframework.zip",
    checksum: "11c9721f786784edb3e6c1dc934269438dabc46a779ab74d4b835ca6023a0e01"
  ),
  .binaryTarget(
    name: "ExpoModulesWorklets",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/ExpoModulesWorklets.xcframework.zip",
    checksum: "5eaf9829159fa3a0810bf49ad6b0ee4da69f0252fcec02654b11346f61945aa6"
  ),
  .binaryTarget(
    name: "Funkit",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/Funkit.xcframework.zip",
    checksum: "48511cde77f79d236258cbbe85048f4265a73c5779be3851a5c914c1216f9535"
  ),
  .binaryTarget(
    name: "IdensicMobileSDK",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/IdensicMobileSDK.xcframework.zip",
    checksum: "e35b0f4d8b6aa462dbdedd92e5d5ea92e2e41d7fccc3e6b9cdc77e6b2aee6077"
  ),
  .binaryTarget(
    name: "React",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/React.xcframework.zip",
    checksum: "9e869b625ac56c30253deba15398044cc52ed54059d4ea285073a64b119fcb01"
  ),
  .binaryTarget(
    name: "ReactNativeDependencies",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/ReactNativeDependencies.xcframework.zip",
    checksum: "26b843e0148fe5680a5982b91bdaa417c4cbbbfb12bdf9ed40a5fcd9ada6ec4a"
  ),
  .binaryTarget(
    name: "hermesvm",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.6/hermesvm.xcframework.zip",
    checksum: "0a179d00be673dfb25a6c3c2db26e9032ec36104513fbccad78974ab80017b0a"
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

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
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/FunkitShell.xcframework.zip",
    checksum: "a03f301974b9dd631c4e2b479f7326809d6e91cf3a6178beb829c3ff9a92cfed"
  ),
  .binaryTarget(
    name: "ExpoBrownfield",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/ExpoBrownfield.xcframework.zip",
    checksum: "330942d08a1a3b2d3a8cdda12678d9c174002a25873536a112baeebcdabf2e32"
  ),
  .binaryTarget(
    name: "ExpoFileSystem",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/ExpoFileSystem.xcframework.zip",
    checksum: "89dfbac4d0bbc471dc276dfd81804053fd16431cf7c2cd031c013e8934820c26"
  ),
  .binaryTarget(
    name: "ExpoFont",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/ExpoFont.xcframework.zip",
    checksum: "388e765a9451ab77fa694fde5e6f50c27e77b54a70b8beb9da1a09b1b33db2cf"
  ),
  .binaryTarget(
    name: "ExpoModulesCore",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/ExpoModulesCore.xcframework.zip",
    checksum: "51bd7b6f52da808726957009e833d25fdbb5a8107f2843dbc4a7812f9b605f6b"
  ),
  .binaryTarget(
    name: "ExpoModulesJSI",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/ExpoModulesJSI.xcframework.zip",
    checksum: "390d9ab954d8b92414a1e2e257d45b544ac88a850b9f3faffea6bc858a48dca4"
  ),
  .binaryTarget(
    name: "ExpoModulesWorklets",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/ExpoModulesWorklets.xcframework.zip",
    checksum: "ef25f0f07b579f9732496af4cc11d6e999a47a956c00b163d3020f60ac842d96"
  ),
  .binaryTarget(
    name: "Funkit",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/Funkit.xcframework.zip",
    checksum: "ecfbd0396de863c00c165ed60c211e38b719ac1d4a10ed83406f0c7ca7c6938b"
  ),
  .binaryTarget(
    name: "IdensicMobileSDK",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/IdensicMobileSDK.xcframework.zip",
    checksum: "a9ac07d84c04bb5bfc2398a7f3d75d4c31cae101b5bdd4ba4429be1581d2e9af"
  ),
  .binaryTarget(
    name: "React",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/React.xcframework.zip",
    checksum: "22432f6726769b351edd96ac19fe98a6e84050f7f45d001bd5f6bc32a2f56eca"
  ),
  .binaryTarget(
    name: "ReactNativeDependencies",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/ReactNativeDependencies.xcframework.zip",
    checksum: "77160edd7470299e3dd511911f9e2ee28b794dfce86996a88e4b56f84938e1df"
  ),
  .binaryTarget(
    name: "hermesvm",
    url: "https://sdk-cdn.fun.xyz/funkit-swift/0.1.0-rc.8/hermesvm.xcframework.zip",
    checksum: "c43f440ae7442ef48ffa8ebd99ad2091e6495cfea8a4377a07b3cd949c00dc02"
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

// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.6.1"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "f71cff9e74f3d809b454a23ce0d17b33af2cf77ed821f406eb9f753056ff5817"

let sdkURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutComponentsSDK.xcframework.zip"

let package = Package(
  name: "CheckoutComponents",
  defaultLocalization: "en-GB",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "CheckoutComponents",
      targets: [
        "CheckoutComponentsPackage"
      ]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/checkout/checkout-risk-sdk-ios",
      from: "4.0.1"
    )
  ],
  targets: [
    .target(
      name: "CheckoutComponentsPackage",
      dependencies: [
        .product(name: "Risk", package: "checkout-risk-sdk-ios"),
        .target(name: "CheckoutComponentsSDK"),
      ],
      path: "CheckoutComponentsPackage"
    ),
    .binaryTarget(
      name: "CheckoutComponentsSDK",
      url: "https://github.com/checkout/checkout-ios-components/releases/download/1.6.2/CheckoutComponentsSDK.xcframework.zip",
      checksum: "01ab5117b949a29d921f27330207a0a448255c4c8047e6c78f06851afbb898ce"
    ),
    )
  ]
)

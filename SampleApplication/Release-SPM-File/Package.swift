// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.10.0-Test4"
let githubRepo = "cko-mobile/checkout-ios-components"

let sdkChecksum = "1a8288e5ed5c33fed1f53b1b985c980b57eccf748e0c29abded2c627a177cb85"

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
      url: sdkURL,
      checksum: sdkChecksum
    )
  ]
)

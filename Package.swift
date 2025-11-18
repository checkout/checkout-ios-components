// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.2.6"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "b911cd0edaba2d8e8f2e43f1c62650c3fe746935635230c189d90eb446bfffe2"
let kmpChecksum = "737407dfadcf271a257684257e20cf7c731b9e6f7f56daea6c22836e06328fa0"

let sdkURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutComponentsSDK.xcframework.zip"
let kmpURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutKMPRememberMe.xcframework.zip"

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
        .target(name: "CheckoutKMPRememberMe")
      ],
      path: "CheckoutComponentsPackage"
    ),

      .binaryTarget(
        name: "CheckoutComponentsSDK",
        url: sdkURL,
        checksum: sdkChecksum
      ),

      .binaryTarget(
        name: "CheckoutKMPRememberMe",
        url: kmpURL,
        checksum: kmpChecksum
      )
  ]
)

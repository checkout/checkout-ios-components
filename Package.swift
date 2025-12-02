// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.3.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "e7c3adec1325da118710a550e42f08fb16bd94652fbd2a88b98ba1ccff68e080"
let kmpChecksum = "021a44dccee94392f78f9509acb869f6a4ff9c0b8aa29a650c5cf44ad4d0535e"

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

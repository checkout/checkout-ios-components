// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.3.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "97b9d5168852015218006ea409f866307983f93c35f55777e9297ee449d348f8"
let kmpChecksum = "d22da7cd19616c3bc8e3557880a2835761fb57dae91beca40d8decf725555783"

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

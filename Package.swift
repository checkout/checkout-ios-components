// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.2.4"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "77b06857cdbeeece8775cc7cfe39c4fe190ce3a0f149973604b8fe1523f34230"
let kmpChecksum = "e7785811790f3c1d97920c6f9e9a72819fe4ea8592f5a48561e41eecd6992e53"

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
      from: "4.0.0"
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

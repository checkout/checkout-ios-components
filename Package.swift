// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.6.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "eff392d20ab1282006afcfa175e1d81a9fd2978829afa9d601c6f34b10db6791"

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
      url: "https://github.com/checkout/checkout-ios-components/releases/download/1.6.1-rc-1/CheckoutComponentsSDK.xcframework.zip",
      checksum: "a7d9df9206f09de4431c57965acb0428c8d6d7706e0b82661566bbc7f737acb9"
    ),
    )
  ]
)

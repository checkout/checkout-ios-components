// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.9.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "5d97ba492e40a54d702dc66433eab72a829bf660d64e22c129d3bed96f5dad4d"

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
      url: "https://github.com/checkout/checkout-ios-components/releases/download/1.10.0/CheckoutComponentsSDK.xcframework.zip",
      checksum: "ed3af19e84618840a0361fea186e921f8c216b6369c7a39628eb33a02ee45fa6"
    ),
  ]
)

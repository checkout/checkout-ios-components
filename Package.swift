// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.6.0-rc"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "e4883d7e10bd9d5bda07c4632901864634547301d07d62a57d57a59a34ddb83d"

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
      url: "https://github.com/checkout/checkout-ios-components/releases/download/1.6.0/CheckoutComponentsSDK.xcframework.zip",
      checksum: "0879d52806c687db67e3f08446ceb3cf8a38671e3d0556822ddbaf1a290a8a75"
    ),
    )
  ]
)

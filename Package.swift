// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.8.2"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "00e46902a08b8980772922f7bdf99d0bc80cee09ee0b94a7be9de3096fd98394"

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
      url: "https://github.com/checkout/checkout-ios-components/releases/download/1.8.3/CheckoutComponentsSDK.xcframework.zip",
      checksum: "aa12f47dd20e8275bfdcf9224d60038dc4fe847291d2a155eaacfaeef41b6135"
    ),
    )
  ]
)

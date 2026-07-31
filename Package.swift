// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.4.0-rc"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "97b72337779e27f76573ed89eeeaa35ba14f13406b4579dee3f456277b7fed11"
let paymentMethodsChecksum = "53bf341fa88fdfc587035b0e77c5c618aec3a4058ffd7a1b03cd2c47ec29432d"
let klarnaChecksum = "1b5d2cbe804d4f1b4a99d5883ccd1526f1a5cef766d7897d0dc67f2e403a8565"

let sdkURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutComponentsSDK.xcframework.zip"
let paymentMethodsURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutPaymentMethods.xcframework.zip"
let klarnaURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutKlarna.xcframework.zip"

let package = Package(
  name: "CheckoutComponents",
  defaultLocalization: "en-GB",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "CheckoutComponents",
      targets: ["CheckoutComponentsPackage"]
    ),
    .library(
      name: "CheckoutPaymentMethods",
      targets: ["CheckoutPaymentMethodsPackage"]
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
    ),
    .target(
      name: "CheckoutPaymentMethodsPackage",
      dependencies: [
        .target(name: "CheckoutPaymentMethods"),
        .target(name: "CheckoutComponentsPackage"),
      ],
      path: "CheckoutPaymentMethodsPackage"
    ),
    .binaryTarget(
      name: "CheckoutPaymentMethods",
      url: paymentMethodsURL,
      checksum: paymentMethodsChecksum
    ),
    .binaryTarget(
      name: "CheckoutKlarna",
      url: klarnaURL,
      checksum: klarnaChecksum
    ),
  ]
)

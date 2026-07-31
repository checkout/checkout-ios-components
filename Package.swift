// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.4.0-rc"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "c7975d437a2a21ed61f4e56c09e87eb574c71bddcf65618c55db8c79e560b5f6"
let paymentMethodsChecksum = "8848e0cd9f768195d1eecc0e8abc53cdfee84546b37e67375cf3fd4c966f8ef9"
let klarnaChecksum = "a43d3651e473c111c90a3b0b39b2f8fd45dfbe5510eb83c10912c0925dc8ffc0"

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

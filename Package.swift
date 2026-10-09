// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.9.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "bd5e60571bfc3d9560a4823f0720463ab720ae9303cb28ac0f7f9b676645c6cd"
let paymentMethodsChecksum = "48c5f72ae10ef50d87478a58e52180415f3983a176eeddde63dad26cb4e97d4d"
let klarnaChecksum = "310661709f507bcf528a28eafe8a7ccd87a108a9108d6a35377c17e0905b1bbd"

let sdkURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutComponentsSDK.xcframework.zip"
let paymentMethodsURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutPaymentMethods.xcframework.zip"
let klarnaURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutKlarnaSDK.xcframework.zip"

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
    .library(
      name: "CheckoutKlarnaSDK",
      targets: ["CheckoutKlarnaPackage"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/checkout/checkout-risk-sdk-ios",
      exact: "6.0.1"
    ),
    .package(
      url: "https://github.com/klarna/klarna-mobile-sdk-spm",
      from: "2.13.0"
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
    .target(
      name: "CheckoutKlarnaPackage",
      dependencies: [
        .target(name: "CheckoutKlarnaSDK"),
        .target(name: "CheckoutComponentsPackage"),
        .product(name: "KlarnaMobileSDK", package: "klarna-mobile-sdk-spm"),
      ],
      path: "CheckoutKlarnaPackage"
    ),
    .binaryTarget(
      name: "CheckoutKlarnaSDK",
      url: klarnaURL,
      checksum: klarnaChecksum
    )
  ]
)

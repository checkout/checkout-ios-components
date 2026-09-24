// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.7.0-rc"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "dbd66f30b806a376cc50a4dbed98f951061829b672b5d49bf854ec1c0b80cd90"
let paymentMethodsChecksum = "806c590b5f090480b7f68ac3f3a3698a0d97d413c05bf55c716424e5c21e9727"
let klarnaChecksum = "63dce038864ed87a8673ead07fdb5f97c0350aac2c1e7c8dd811b72b2bf7d45f"

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
      from: "4.0.1"
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

// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.10.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "a23b2676501bc2999d787ddb2701564b5e01b17e9c58f747cd90769bbb83c8c5"
let paymentMethodsChecksum = "c974c1e1b41750fb62ef037305671de472c582c703671cce2ea5febd3ab747a5"
let klarnaChecksum = "7963daad2948fb5807dc1f2dc4e5e0280d8e6b3f260e045148f26ccbed74eec1"

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

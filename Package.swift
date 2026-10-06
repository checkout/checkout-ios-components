// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.8.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "b1d3d123ff473ff12c66817e7bad5ec94910a73443aaf7638f2365e801ab32d4"
let paymentMethodsChecksum = "b1f0efbac0443ef95c0b0e5990e9e836e772e77f4df811b6bd8512c4163ce56b"
let klarnaChecksum = "36cab9afa9a3c3279e8676044475c81eaded55fbc010521838522eaaf1ae3ac1"

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

// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.6.1"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "14b1ab7cbcca18d21544732d1e1c69a8eafd75de26ebc44069fef6b31acab41c"
let paymentMethodsChecksum = "997f1516cfcf5cdd9157bd2cbacb53f80a8f0bb5cd09bfd258c03376c0a09a4a"
let klarnaChecksum = "4e2ae087e856f1d38558529686b5572d1d7d9fcce90858c7023a49a317d05927"

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

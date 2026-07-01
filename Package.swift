// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.2.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "8b92819b2a7b63ad0d7c880b681ab4ad36824a63913b04feda3525f88fdf5428"
let paymentMethodsChecksum = "8434b2b35f29b59a7f4d991c7579d5ea4bde1e98da23ce8c79ae3fc925abf9a8"

let sdkURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutComponentsSDK.xcframework.zip"
let paymentMethodsURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutPaymentMethods.xcframework.zip"

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
  ]
)
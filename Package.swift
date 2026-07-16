// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "2.3.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "4dc40807152b744ca3c3968d3452867a9ec09ba6de8059570be5455c7c457c79"
let paymentMethodsChecksum = "79f3b3a7aa23a1f126a7484cd5c35f263d81f6e2503626a1a23b9950feb5a3f9"

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

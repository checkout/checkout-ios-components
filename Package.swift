// swift-tools-version: 5.10
import PackageDescription

  let releaseVersion = "2.0.0-beta"
  let githubRepo = "checkout/checkout-ios-components"

  let sdkChecksum = "6af7b4e305d520d669cc2abacb1dd686ec18b1f239c1551f1cd7301d9b356b90"
  let paymentMethodsChecksum = "ba41f46ba1dd8b2c2d0b2e2dd59658f4dc73e90f080ff5eae40f77772f419184"

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
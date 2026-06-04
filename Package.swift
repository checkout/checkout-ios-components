// swift-tools-version: 5.10
import PackageDescription

  let releaseVersion = "2.0.0-beta"
  let githubRepo = "checkout/checkout-ios-components"

  let sdkChecksum = "cebe94e0bf9b9fadb836316f5042a8cf52700618e253340cb4147612918db698"
  let paymentMethodsChecksum = "3b5f3e8c3656c3d040d25b6457816d2691bc8cdf51f48155d6c8483fe03813ca"

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
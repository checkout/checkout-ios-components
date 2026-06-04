// swift-tools-version: 5.10
import PackageDescription

  let releaseVersion = "2.0.0"
  let githubRepo = "checkout/checkout-ios-components"

  let sdkChecksum = "4a5f41fa4f516e58fd25b67488a576d2e4544fea68f8eb0b228e6dac3386ed8a"
  let paymentMethodsChecksum = "9edfb84e39cb35f80c5e81ce6030cc4dce62ca0f3c36a970b89ce52a2b33035d"

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
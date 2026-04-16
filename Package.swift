// swift-tools-version: 5.10
import PackageDescription

let releaseVersion = "1.8.0"
let githubRepo = "checkout/checkout-ios-components"

let sdkChecksum = "9b97ce5f673903e01a0a5566c696aaf415ea950ead60ab9598d749dd90225b94"

let sdkURL = "https://github.com/\(githubRepo)/releases/download/\(releaseVersion)/CheckoutComponentsSDK.xcframework.zip"

let package = Package(
  name: "CheckoutComponents",
  defaultLocalization: "en-GB",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "CheckoutComponents",
      targets: [
        "CheckoutComponentsPackage"
      ]
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
      url: "https://github.com/checkout/checkout-ios-components/releases/download/1.8.1/CheckoutComponentsSDK.xcframework.zip",
      checksum: "6cb348cb241e27e90491a081f90ff93e0e562c447220500a47a51c97edb8cae6"
    ),
    )
  ]
)

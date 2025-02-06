// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
        "CheckoutComponentsSDK"
      ]
    ),
  ],
  targets: [
    .binaryTarget(
      name: "CheckoutComponentsSDK",
      path: "SDK/CheckoutComponentsSDK.xcframework"
    )
  ]
)

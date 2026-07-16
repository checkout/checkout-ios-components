//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import Foundation

// MARK: - Unified Configuration Schema

/// Platform-neutral, declarative launch configuration.
///
/// Mirrors the JSON schema shared with the Android sample app:
/// ```json
/// { "locale": "ar", "environment": "sandbox", "render": "auto", "amount": 10500, "currency": "GBP" }
/// ```
/// Every field is optional so that partial configurations from different
/// sources can be merged together (see `LaunchConfig.overlaying(_:)`).
struct LaunchConfig: Decodable, Equatable, Sendable {
  var locale: String?
  var environment: String?
  var render: String?
  var amount: Int?
  var currency: String?

  static let empty = LaunchConfig()

  /// `true` when the payload requests the flow to render without a tap.
  var rendersAutomatically: Bool {
    render?.lowercased() == "auto"
  }

  /// Returns a copy where any non-nil field from `higher` overrides the
  /// corresponding field in `self`. Used to apply the precedence hierarchy:
  /// a higher-priority source overlays a lower-priority baseline.
  func overlaying(_ higher: LaunchConfig) -> LaunchConfig {
    LaunchConfig(
      locale: higher.locale ?? locale,
      environment: higher.environment ?? environment,
      render: higher.render ?? render,
      amount: higher.amount ?? amount,
      currency: higher.currency ?? currency
    )
  }
}

// MARK: - State Hydrator

/// Resolves a `LaunchConfig` from the available delivery channels using a
/// strict precedence hierarchy, then leaves it to the caller to apply the
/// values to the view-model state before `makeComponent()` runs.
///
/// Precedence (highest first):
/// 1. Deep Link Token — a Base64URL-encoded JSON payload in the launch URL.
/// 2. Environment Variables — `LAUNCH_CONFIG` JSON string from `ProcessInfo`.
/// 3. Bundled JSON Asset — `LaunchConfig.json` packaged in the app bundle.
/// 4. Hardcoded App Defaults — whatever the view model initialises to (the
///    resolved config simply leaves those fields nil).
enum LaunchConfigHydrator {
  /// Query item used in deep links, e.g. `checkoutexponewarch://?config=<base64url>`.
  static let deepLinkQueryItem = "config"
  /// Environment variable carrying a raw JSON configuration string.
  static let environmentKey = "LAUNCH_CONFIG"
  /// Name of the bundled baseline asset (without extension).
  static let bundledAssetName = "LaunchConfig"

  /// Builds the effective configuration by overlaying each source on top of
  /// the lower-priority ones. Any individual source that is missing or
  /// malformed is silently skipped (Graceful Degradation, AC 2).
  static func resolve(
    deepLinkURL: URL?,
    environment: [String: String],
    bundle: Bundle = .main
  ) -> LaunchConfig {
    var config = LaunchConfig.empty

    if let bundled = bundledConfig(in: bundle) {
      config = config.overlaying(bundled)
    }
    if let fromEnvironment = environmentConfig(environment) {
      config = config.overlaying(fromEnvironment)
    }
    if let fromDeepLink = deepLinkConfig(from: deepLinkURL) {
      config = config.overlaying(fromDeepLink)
    }

    return config
  }

  // MARK: Sources

  /// Highest priority: Base64URL-encoded JSON in the launch URL's query.
  static func deepLinkConfig(from url: URL?) -> LaunchConfig? {
    guard
      let url,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let encoded = components.queryItems?.first(where: { $0.name == deepLinkQueryItem })?.value,
      let data = decodeBase64URL(encoded)
    else {
      return nil
    }
    return decode(data)
  }

  /// Second priority: a `LAUNCH_CONFIG` environment variable holding raw JSON.
  static func environmentConfig(_ environment: [String: String]) -> LaunchConfig? {
    guard
      let raw = environment[environmentKey],
      let data = raw.data(using: .utf8)
    else {
      return nil
    }
    return decode(data)
  }

  /// Third priority: a baseline JSON file packaged inside the app bundle.
  static func bundledConfig(in bundle: Bundle) -> LaunchConfig? {
    guard
      let url = bundle.url(forResource: bundledAssetName, withExtension: "json"),
      let data = try? Data(contentsOf: url)
    else {
      return nil
    }
    return decode(data)
  }

  // MARK: Helpers

  /// Decodes a `LaunchConfig`, returning nil on any malformed input so that
  /// callers never see a runtime exception (AC 2).
  private static func decode(_ data: Data) -> LaunchConfig? {
    try? JSONDecoder().decode(LaunchConfig.self, from: data)
  }

  /// Decodes a Base64URL string (RFC 4648 §5) into `Data`, restoring the
  /// standard Base64 alphabet and padding that command-line tools strip.
  static func decodeBase64URL(_ value: String) -> Data? {
    var base64 = value
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    let remainder = base64.count % 4
    if remainder > 0 {
      base64 += String(repeating: "=", count: 4 - remainder)
    }

    return Data(base64Encoded: base64)
  }
}

// MARK: - State Mutation

extension MainViewModel {
  /// Applies a resolved launch configuration to the `@Published` state of the
  /// view model. Unknown or unmappable values are ignored so the existing
  /// (hardcoded) defaults survive — Graceful Degradation, AC 2.
  ///
  /// - Returns: `true` when the payload requests automatic rendering.
  @discardableResult
  func applyLaunchConfig(_ config: LaunchConfig) -> Bool {
    if let localeString = config.locale,
       let locale = CheckoutComponents.Locale(rawValue: localeString) {
      selectedLocale = .locale(locale)
      paymentSessionSelectedLocale = .locale(locale)
    }

    if let environmentString = config.environment,
       let environment = CheckoutComponents.Environment(configValue: environmentString) {
      selectedEnvironment = environment
    }

    if let currencyString = config.currency,
       let currency = CurrencyOption(rawValue: currencyString.uppercased()) {
      selectedCurrency = currency
    }

    if let amount = config.amount {
      self.amount = amount
    }

    return config.rendersAutomatically
  }
}

extension CheckoutComponents.Environment {
  /// Maps a launch-config string (`"sandbox"` / `"production"`) to an
  /// `Environment`, returning nil for unrecognised values.
  init?(configValue: String) {
    switch configValue.lowercased() {
    case "sandbox":
      self = .sandbox
    case "production", "prod", "live":
      self = .production
    default:
      return nil
    }
  }
}

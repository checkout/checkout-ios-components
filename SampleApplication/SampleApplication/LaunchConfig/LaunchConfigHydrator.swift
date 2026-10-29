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
/// { "locale": "ar", "environment": "sandbox", "render": "auto", "paymentSessionAmount": 10500 }
/// ```
/// Every field is optional so that partial configurations from different
/// sources can be merged together (see `LaunchConfig.overlaying(_:)`).
struct LaunchConfig: Decodable, Equatable, Sendable {
  var locale: String?
  var environment: String?
  var render: String?
  var selectedComponent: String?
  var paymentSessionAmount: Int?
  var paymentSessionCurrency: String?
  var paymentSessionCountry: String?
  var merchantKey: String?
  var appearance: String?
  var paymentSessionEmail: String?
  var paymentSessionPhone: Phone?
  var rememberMeEmail: String?
  var rememberMePhoneNumber: Phone?
  var storedCardSource: String?
  var storedCardCustomerId: String?
  var storedCardInstrumentIds: [String]?
  var storedCardDefaultInstrumentId: String?
  var captureStoredCardCvv: Bool?
  var storedCardDisplayMode: String?
  var storedCardAcceptedSchemes: [String]?
  var storedCardShowPayButton: Bool?
  var componentCallbacks: [String]?
  var customTranslations: Bool?
  var paymentSessionLocale: String?
  var stagingKeys: [String]?
  var paymentMethods: [String]?
  var paymentSessionName: String?
  var storePaymentDetails: String?
  var showPayButton: Bool?
  var paymentButtonAction: String?
  var displayCardHolderName: String?
  var cardholderNameMaxLength: Int?
  var hideSecurityCode: Bool?
  var prefilledCardholderName: String?
  var acceptedCardSchemes: [String]?
  var acceptedCardTypes: [String]?
  var applePaySettings: ApplePaySettings?
  var showUpdateAmountSection: Bool?
  var showApmPayButton: Bool?
  var klarnaTheme: String?
  var klarnaReturnUrl: String?
  var showRememberMePayButton: Bool?
  var rememberMeCardSchemes: [String]?
  var rememberMeCardTypes: [String]?
  var storedCardAcceptedTypes: [String]?
  var storedCardPaymentButtonAction: String?
  var storedCardConsentOverride: String?
  var addressConfig: String?
  var customButtonOperation: String?
  var cvvLengths: [Int]?

  struct Phone: Decodable, Equatable, Sendable {
    var countryCode: String?
    var number: String?

    func overlaying(_ higher: Phone) -> Phone {
      Phone(countryCode: higher.countryCode ?? countryCode, number: higher.number ?? number)
    }
  }

  struct ApplePaySettings: Decodable, Equatable, Sendable {
    var showApplePayButton: Bool?
    var acceptedCardSchemes: [String]?
    var acceptedCardTypes: [String]?
    var buttonStyle: String?
    var buttonType: String?
    var totalType: String?

    func overlaying(_ higher: ApplePaySettings) -> ApplePaySettings {
      ApplePaySettings(
        showApplePayButton: higher.showApplePayButton ?? showApplePayButton,
        acceptedCardSchemes: higher.acceptedCardSchemes ?? acceptedCardSchemes,
        acceptedCardTypes: higher.acceptedCardTypes ?? acceptedCardTypes,
        buttonStyle: higher.buttonStyle ?? buttonStyle,
        buttonType: higher.buttonType ?? buttonType,
        totalType: higher.totalType ?? totalType
      )
    }
  }

  static let empty = LaunchConfig()

  /// `true` when the payload requests the flow to render without a tap.
  var rendersAutomatically: Bool {
    render?.lowercased() == "auto"
  }

  /// Returns a copy where any non-nil field from `higher` overrides the
  /// corresponding field in `self`. Used to apply the precedence hierarchy:
  /// a higher-priority source overlays a lower-priority baseline.
  func overlaying(_ higher: LaunchConfig) -> LaunchConfig {
    var merged = LaunchConfig(
      locale: higher.locale ?? locale,
      environment: higher.environment ?? environment,
      render: higher.render ?? render,
      selectedComponent: higher.selectedComponent ?? selectedComponent,
      paymentSessionAmount: higher.paymentSessionAmount ?? paymentSessionAmount,
      paymentSessionCurrency: higher.paymentSessionCurrency ?? paymentSessionCurrency,
      paymentSessionCountry: higher.paymentSessionCountry ?? paymentSessionCountry,
      merchantKey: higher.merchantKey ?? merchantKey,
      appearance: higher.appearance ?? appearance,
      paymentSessionEmail: higher.paymentSessionEmail ?? paymentSessionEmail,
      paymentSessionPhone: Self.merge(paymentSessionPhone, higher.paymentSessionPhone) { $0.overlaying($1) },
      rememberMeEmail: higher.rememberMeEmail ?? rememberMeEmail,
      rememberMePhoneNumber: Self.merge(rememberMePhoneNumber, higher.rememberMePhoneNumber) { $0.overlaying($1) },
      storedCardSource: higher.storedCardSource ?? storedCardSource,
      storedCardCustomerId: higher.storedCardCustomerId ?? storedCardCustomerId,
      storedCardInstrumentIds: higher.storedCardInstrumentIds ?? storedCardInstrumentIds,
      storedCardDefaultInstrumentId: higher.storedCardDefaultInstrumentId ?? storedCardDefaultInstrumentId,
      captureStoredCardCvv: higher.captureStoredCardCvv ?? captureStoredCardCvv,
      storedCardDisplayMode: higher.storedCardDisplayMode ?? storedCardDisplayMode,
      storedCardAcceptedSchemes: higher.storedCardAcceptedSchemes ?? storedCardAcceptedSchemes,
      storedCardShowPayButton: higher.storedCardShowPayButton ?? storedCardShowPayButton,
      componentCallbacks: higher.componentCallbacks ?? componentCallbacks
    )
    merged.overlaySettings(from: higher, over: self)
    return merged
  }

  private mutating func overlaySettings(from higher: LaunchConfig, over lower: LaunchConfig) {
    customTranslations = higher.customTranslations ?? lower.customTranslations
    paymentSessionLocale = higher.paymentSessionLocale ?? lower.paymentSessionLocale
    stagingKeys = higher.stagingKeys ?? lower.stagingKeys
    paymentMethods = higher.paymentMethods ?? lower.paymentMethods
    paymentSessionName = higher.paymentSessionName ?? lower.paymentSessionName
    storePaymentDetails = higher.storePaymentDetails ?? lower.storePaymentDetails
    showPayButton = higher.showPayButton ?? lower.showPayButton
    paymentButtonAction = higher.paymentButtonAction ?? lower.paymentButtonAction
    displayCardHolderName = higher.displayCardHolderName ?? lower.displayCardHolderName
    cardholderNameMaxLength = higher.cardholderNameMaxLength ?? lower.cardholderNameMaxLength
    hideSecurityCode = higher.hideSecurityCode ?? lower.hideSecurityCode
    prefilledCardholderName = higher.prefilledCardholderName ?? lower.prefilledCardholderName
    acceptedCardSchemes = higher.acceptedCardSchemes ?? lower.acceptedCardSchemes
    acceptedCardTypes = higher.acceptedCardTypes ?? lower.acceptedCardTypes
    applePaySettings = Self.merge(lower.applePaySettings, higher.applePaySettings) { $0.overlaying($1) }
    showUpdateAmountSection = higher.showUpdateAmountSection ?? lower.showUpdateAmountSection
    showApmPayButton = higher.showApmPayButton ?? lower.showApmPayButton
    klarnaTheme = higher.klarnaTheme ?? lower.klarnaTheme
    klarnaReturnUrl = higher.klarnaReturnUrl ?? lower.klarnaReturnUrl
    showRememberMePayButton = higher.showRememberMePayButton ?? lower.showRememberMePayButton
    rememberMeCardSchemes = higher.rememberMeCardSchemes ?? lower.rememberMeCardSchemes
    rememberMeCardTypes = higher.rememberMeCardTypes ?? lower.rememberMeCardTypes
    storedCardAcceptedTypes = higher.storedCardAcceptedTypes ?? lower.storedCardAcceptedTypes
    storedCardPaymentButtonAction = higher.storedCardPaymentButtonAction ?? lower.storedCardPaymentButtonAction
    storedCardConsentOverride = higher.storedCardConsentOverride ?? lower.storedCardConsentOverride
    addressConfig = higher.addressConfig ?? lower.addressConfig
    customButtonOperation = higher.customButtonOperation ?? lower.customButtonOperation
    cvvLengths = higher.cvvLengths ?? lower.cvvLengths
  }

  /// Nested objects merge member by member, so a partial override keeps the lower source's other members.
  private static func merge<Value>(_ lower: Value?, _ higher: Value?, _ overlay: (Value, Value) -> Value) -> Value? {
    guard let lower, let higher else {
      return higher ?? lower
    }
    return overlay(lower, higher)
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

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
  var sdkModule: String?
  var amount: Int?
  var currency: String?
  var country: String?
  var merchantKey: String?
  var appearance: String?
  var customerEmail: String?
  var customerPhoneCountryCode: String?
  var customerPhoneNumber: String?
  var rememberMeEmail: String?
  var rememberMePhoneCountryCode: String?
  var rememberMePhoneNumber: String?
  var storedCardSource: String?
  var storedCardCustomerId: String?
  var storedCardInstrumentIds: [String]?
  var storedCardDefaultInstrumentId: String?
  var captureStoredCardCvv: Bool?
  var storedCardDisplayMode: String?
  var storedCardAcceptedSchemes: [String]?
  var storedCardShowPayButton: Bool?
  var componentCallbacks: [String]?

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
      sdkModule: higher.sdkModule ?? sdkModule,
      amount: higher.amount ?? amount,
      currency: higher.currency ?? currency,
      country: higher.country ?? country,
      merchantKey: higher.merchantKey ?? merchantKey,
      appearance: higher.appearance ?? appearance,
      customerEmail: higher.customerEmail ?? customerEmail,
      customerPhoneCountryCode: higher.customerPhoneCountryCode ?? customerPhoneCountryCode,
      customerPhoneNumber: higher.customerPhoneNumber ?? customerPhoneNumber,
      rememberMeEmail: higher.rememberMeEmail ?? rememberMeEmail,
      rememberMePhoneCountryCode: higher.rememberMePhoneCountryCode ?? rememberMePhoneCountryCode,
      rememberMePhoneNumber: higher.rememberMePhoneNumber ?? rememberMePhoneNumber,
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
    applyGeneralSettings(from: config)
    applyPaymentSettings(from: config)
    applyCustomerSettings(from: config)
    applyRememberMeSettings(from: config)
    applyStoredCardSettings(from: config)
    applyStoredCardDisplaySettings(from: config)
    applyAppearanceSettings(from: config)
    return config.rendersAutomatically
  }

  private func applyGeneralSettings(from config: LaunchConfig) {
    if let localeString = config.locale,
       let locale = CheckoutComponents.Locale(rawValue: localeString) {
      selectedLocale = .locale(locale)
      paymentSessionSelectedLocale = .locale(locale)
    }

    if let environmentString = config.environment,
       let environment = CheckoutComponents.Environment(configValue: environmentString) {
      selectedEnvironment = environment
    }

    if let moduleString = config.sdkModule,
       let module = CheckoutComponent(configValue: moduleString) {
      selectedComponentType = module
    }

    #if INTERNAL_SAMPLE_APP
    if let merchantKeyName = config.merchantKey,
       let preset = availableMerchantKeys.first(where: { $0.name == merchantKeyName }) {
      selectedMerchantKey = preset
    }
    #endif
  }

  private func applyPaymentSettings(from config: LaunchConfig) {
    if let currencyString = config.currency,
       let currency = CurrencyOption(rawValue: currencyString.uppercased()) {
      selectedCurrency = currency
    }

    if let amount = config.amount {
      self.amount = amount
    }

    if let countryString = config.country,
       let country = CountryOption(rawValue: countryString.uppercased()) {
      selectedCountry = country
    }
  }

  private func applyCustomerSettings(from config: LaunchConfig) {
    if let email = config.customerEmail {
      paymentSessionUserEmail = email
    }
    if let countryCode = config.customerPhoneCountryCode {
      paymentSessionCountryCode = Self.dialingCode(from: countryCode)
    }
    if let number = config.customerPhoneNumber {
      paymentSessionPhoneNumber = number
    }
  }

  private func applyRememberMeSettings(from config: LaunchConfig) {
    if let email = config.rememberMeEmail, !email.isEmpty {
      userEmail = email
    }
    if let countryCode = config.rememberMePhoneCountryCode, !countryCode.isEmpty {
      userCountryCode = Self.dialingCode(from: countryCode)
    }
    if let number = config.rememberMePhoneNumber, !number.isEmpty {
      userPhoneNumber = number
    }
  }

  private func applyStoredCardSettings(from config: LaunchConfig) {
    if let sourceString = config.storedCardSource, let source = StoredCardSource(configValue: sourceString) {
      storedCardSource = source
    }
    if let customerId = config.storedCardCustomerId, !customerId.isEmpty {
      self.customerId = customerId
    }
    if let ids = config.storedCardInstrumentIds, !ids.isEmpty {
      instrumentIds = ids.joined(separator: ",")
    }
    if let defaultInstrumentId = config.storedCardDefaultInstrumentId, !defaultInstrumentId.isEmpty {
      self.defaultInstrumentId = defaultInstrumentId
    }
  }

  private func applyStoredCardDisplaySettings(from config: LaunchConfig) {
    if let captureCvv = config.captureStoredCardCvv {
      storedCardCaptureCVV = captureCvv
    }
    if let displayModeString = config.storedCardDisplayMode,
       let displayMode = CheckoutComponents.StoredCardDisplayMode(configValue: displayModeString) {
      storedCardDisplayMode = displayMode
    }
    if let schemes = config.storedCardAcceptedSchemes {
      storedCardAcceptedCardSchemes = Set(schemes.compactMap { CardScheme(configValue: $0) })
    }
    if let showPayButton = config.storedCardShowPayButton {
      showStoredCardPayButton = showPayButton
    }
  }

  private func applyAppearanceSettings(from config: LaunchConfig) {
    if let appearanceString = config.appearance,
       let appearance = AppearancePreset(configValue: appearanceString) {
      isDefaultAppearance = appearance == .default
    }
    if let callbacks = config.componentCallbacks {
      handleSubmitManually = callbacks.contains { $0.caseInsensitiveCompare("HandleSubmit") == .orderedSame }
    }
  }

  private static func dialingCode(from value: String) -> String {
    if let country = CheckoutComponents.Country(iso3166Alpha2: value.uppercased()) {
      return country.dialingCode
    }
    return value.hasPrefix("+") ? String(value.dropFirst()) : value
  }
}

enum AppearancePreset: Equatable {
  case `default`
  case dark

  init?(configValue: String) {
    switch configValue.lowercased() {
    case "default":
      self = .default
    case "dark":
      self = .dark
    default:
      return nil
    }
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

extension CheckoutComponent {
  /// Matches against `accessibilityIdentifier` rather than `rawValue`, since the latter is the
  /// human-readable Settings picker label (e.g. `"Apple Pay"`, `"Stored Card"`).
  init?(configValue: String) {
    let normalised = configValue.lowercased()
    guard let match = CheckoutComponent.allCases.first(where: { $0.accessibilityIdentifier == normalised }) else {
      return nil
    }
    self = match
  }
}

extension StoredCardSource {
  init?(configValue: String) {
    switch configValue.lowercased() {
    case "none":
      self = .none
    case "instrumentids":
      self = .instrumentIds
    case "customerid":
      self = .customerId
    default:
      return nil
    }
  }
}

extension CardScheme {
  init?(configValue: String) {
    let normalised = Self.normalisedName(configValue)
    guard let match = CardScheme.selectableCases.first(where: { Self.normalisedName($0.rawValue) == normalised }) else {
      return nil
    }
    self = match
  }

  private static func normalisedName(_ value: String) -> String {
    value.lowercased().filter { $0.isLetter || $0.isNumber }
  }
}

extension CheckoutComponents.StoredCardDisplayMode {
  init?(configValue: String) {
    switch configValue.lowercased() {
    case "default":
      self = .defaultCard
    case "all":
      self = .all
    default:
      return nil
    }
  }
}

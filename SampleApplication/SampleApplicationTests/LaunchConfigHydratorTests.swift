//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import XCTest
@testable import SampleApplication

@MainActor
final class LaunchConfigHydratorTests: XCTestCase {

  // MARK: - LaunchConfig.overlaying

  func test_overlaying_higherPriorityNonNilFieldsWin() {
    let base = LaunchConfig(locale: "en-GB", environment: "sandbox", render: nil, amount: 10500, currency: "GBP")
    let higher = LaunchConfig(locale: "ar", environment: nil, render: "auto", amount: nil, currency: nil)

    let result = base.overlaying(higher)

    XCTAssertEqual(result.locale, "ar")          // overridden
    XCTAssertEqual(result.environment, "sandbox") // base survives (higher is nil)
    XCTAssertEqual(result.render, "auto")         // added by higher
    XCTAssertEqual(result.amount, 10500)          // base survives
    XCTAssertEqual(result.currency, "GBP")        // base survives
  }

  func test_overlaying_emptyHigher_returnsBaseUnchanged() {
    let base = LaunchConfig(locale: "ar", environment: "production", render: "auto", amount: 99, currency: "AED")
    XCTAssertEqual(base.overlaying(.empty), base)
  }

  func test_rendersAutomatically_isCaseInsensitive() {
    XCTAssertTrue(LaunchConfig(render: "auto").rendersAutomatically)
    XCTAssertTrue(LaunchConfig(render: "AUTO").rendersAutomatically)
    XCTAssertFalse(LaunchConfig(render: "manual").rendersAutomatically)
    XCTAssertFalse(LaunchConfig.empty.rendersAutomatically)
  }

  // MARK: - Base64URL decoding

  func test_decodeBase64URL_matchesPRDExample() {
    // PRD §4: {"locale":"ar"} -> eyJsb2NhbGUiOiJhciJ9
    let data = LaunchConfigHydrator.decodeBase64URL("eyJsb2NhbGUiOiJhciJ9")
    XCTAssertEqual(data.flatMap { String(data: $0, encoding: .utf8) }, #"{"locale":"ar"}"#)
  }

  func test_decodeBase64URL_handlesURLSafeAlphabetAndMissingPadding() {
    // 2 bytes -> 3 significant base64 chars + 1 '=' padding. Stripping the
    // padding (as adb/xcrun do) forces the decoder to restore it.
    let original = Data([0xFB, 0xFF])
    let urlSafe = original.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")            // strip padding, as CLI tools do
    XCTAssertFalse(urlSafe.contains("="))                  // precondition: padding really stripped

    XCTAssertEqual(LaunchConfigHydrator.decodeBase64URL(urlSafe), original)
  }

  func test_decodeBase64URL_invalidInput_returnsNil() {
    XCTAssertNil(LaunchConfigHydrator.decodeBase64URL("!!! not base64 !!!"))
  }

  // MARK: - Deep link source

  func test_deepLinkConfig_parsesEncodedPayload() {
    let url = URL(string: "checkoutexponewarch://?config=eyJsb2NhbGUiOiJhciJ9")!
    XCTAssertEqual(LaunchConfigHydrator.deepLinkConfig(from: url)?.locale, "ar")
  }

  func test_deepLinkConfig_nilURL_returnsNil() {
    XCTAssertNil(LaunchConfigHydrator.deepLinkConfig(from: nil))
  }

  func test_deepLinkConfig_missingConfigQueryItem_returnsNil() {
    let url = URL(string: "checkoutexponewarch://?other=value")!
    XCTAssertNil(LaunchConfigHydrator.deepLinkConfig(from: url))
  }

  func test_deepLinkConfig_malformedBase64_returnsNil() {
    let url = URL(string: "checkoutexponewarch://?config=%21%21%21")! // "!!!"
    XCTAssertNil(LaunchConfigHydrator.deepLinkConfig(from: url))
  }

  // MARK: - Environment variable source

  func test_environmentConfig_parsesJSONString() {
    let env = ["LAUNCH_CONFIG": #"{"environment":"production","amount":250}"#]
    let config = LaunchConfigHydrator.environmentConfig(env)
    XCTAssertEqual(config?.environment, "production")
    XCTAssertEqual(config?.amount, 250)
  }

  func test_environmentConfig_missingKey_returnsNil() {
    XCTAssertNil(LaunchConfigHydrator.environmentConfig([:]))
  }

  func test_environmentConfig_malformedJSON_returnsNil() {
    XCTAssertNil(LaunchConfigHydrator.environmentConfig(["LAUNCH_CONFIG": "{not json"]))
  }

  // MARK: - Bundled asset source

  func test_bundledConfig_loadsPackagedBaseline() {
    // The host app bundle ships LaunchConfig.json.
    let config = LaunchConfigHydrator.bundledConfig(in: .main)
    XCTAssertEqual(config?.environment, "sandbox")
    XCTAssertEqual(config?.currency, "GBP")
    XCTAssertEqual(config?.amount, 10500)
  }

  // MARK: - Precedence (resolve)

  func test_resolve_deepLinkOverridesEnvironmentOverridesBundled() {
    let deepLink = URL(string: "checkoutexponewarch://?config=eyJsb2NhbGUiOiJhciJ9")! // {"locale":"ar"}
    let env = ["LAUNCH_CONFIG": #"{"locale":"en-GB","environment":"production"}"#]

    let resolved = LaunchConfigHydrator.resolve(deepLinkURL: deepLink, environment: env, bundle: .main)

    XCTAssertEqual(resolved.locale, "ar")            // deep link wins over env
    XCTAssertEqual(resolved.environment, "production") // env wins over bundled
    XCTAssertEqual(resolved.currency, "GBP")          // bundled baseline survives
    XCTAssertEqual(resolved.amount, 10500)            // bundled baseline survives
  }

  func test_resolve_noExternalSources_fallsBackToBundledBaseline() {
    let resolved = LaunchConfigHydrator.resolve(deepLinkURL: nil, environment: [:], bundle: .main)
    XCTAssertEqual(resolved.environment, "sandbox")
    XCTAssertEqual(resolved.locale, "en-GB")   // bundled baseline
    XCTAssertEqual(resolved.render, "manual")  // bundled baseline
  }

  func test_resolve_malformedSources_doNotThrowAndFallBack() {
    let badURL = URL(string: "checkoutexponewarch://?config=%21%21%21")!
    let badEnv = ["LAUNCH_CONFIG": "}{"]

    // Graceful degradation (AC 2): no crash, falls back to bundled baseline.
    let resolved = LaunchConfigHydrator.resolve(deepLinkURL: badURL, environment: badEnv, bundle: .main)
    XCTAssertEqual(resolved.environment, "sandbox")
  }

  // MARK: - State mutation (applyLaunchConfig)

  func test_applyLaunchConfig_mutatesPublishedState() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(locale: "ar", environment: "production", render: "auto", amount: 42, currency: "AED")

    let shouldAutoRender = viewModel.applyLaunchConfig(config)

    XCTAssertTrue(shouldAutoRender)
    XCTAssertEqual(viewModel.selectedLocale.localeString, "ar")
    XCTAssertEqual(viewModel.paymentSessionSelectedLocale.localeString, "ar")
    XCTAssertEqual(viewModel.selectedEnvironment, .production)
    XCTAssertEqual(viewModel.selectedCurrency, .aed)
    XCTAssertEqual(viewModel.amount, 42)
  }

  func test_applyLaunchConfig_ignoresUnknownValuesAndKeepsDefaults() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(locale: "klingon", environment: "mars", render: nil, amount: nil, currency: "XYZ")

    let shouldAutoRender = viewModel.applyLaunchConfig(config)

    XCTAssertFalse(shouldAutoRender)
    // Unmappable values are ignored; hardcoded defaults survive.
    XCTAssertEqual(viewModel.selectedLocale.localeString, "en-GB")
    XCTAssertEqual(viewModel.selectedEnvironment, .sandbox)
    XCTAssertEqual(viewModel.selectedCurrency, .gbp)
    XCTAssertEqual(viewModel.amount, 10500)
  }

  func test_applyLaunchConfig_emptyConfig_isNoOp() {
    let viewModel = MainViewModel()
    XCTAssertFalse(viewModel.applyLaunchConfig(.empty))
    XCTAssertEqual(viewModel.selectedLocale.localeString, "en-GB")
    XCTAssertEqual(viewModel.amount, 10500)
  }

  func test_applyLaunchConfig_explicitEmptyCustomerFields_overridesDefaults() {
    let viewModel = MainViewModel()
    XCTAssertFalse(viewModel.paymentSessionUserEmail.isEmpty)   // precondition: has a hardcoded default
    XCTAssertFalse(viewModel.paymentSessionCountryCode.isEmpty)
    XCTAssertFalse(viewModel.paymentSessionPhoneNumber.isEmpty)

    let config = LaunchConfig(customerEmail: "", customerPhoneCountryCode: "", customerPhoneNumber: "")
    viewModel.applyLaunchConfig(config)

    // An explicit "" is a request to clear the default, not to be ignored,
    // so createPaymentSession() sends nil instead of the sample-data default.
    XCTAssertEqual(viewModel.paymentSessionUserEmail, "")
    XCTAssertEqual(viewModel.paymentSessionCountryCode, "")
    XCTAssertEqual(viewModel.paymentSessionPhoneNumber, "")
  }

  // MARK: - Environment(configValue:)

  func test_environmentInit_mapsKnownValuesCaseInsensitively() {
    XCTAssertEqual(CheckoutComponents.Environment(configValue: "sandbox"), .sandbox)
    XCTAssertEqual(CheckoutComponents.Environment(configValue: "SANDBOX"), .sandbox)
    XCTAssertEqual(CheckoutComponents.Environment(configValue: "production"), .production)
    XCTAssertEqual(CheckoutComponents.Environment(configValue: "prod"), .production)
    XCTAssertEqual(CheckoutComponents.Environment(configValue: "live"), .production)
  }

  func test_environmentInit_unknownValue_returnsNil() {
    XCTAssertNil(CheckoutComponents.Environment(configValue: "staging"))
  }

  // MARK: - Customer identity, Remember Me and stored card fields

  func test_overlaying_newFields_higherPriorityWins() {
    let base = LaunchConfig(customerEmail: "base@example.com", storedCardSource: "instrumentIds",
                            storedCardInstrumentIds: ["src_base"], storedCardDisplayMode: "default")
    let higher = LaunchConfig(customerPhoneNumber: "7784123123", storedCardSource: "customerId",
                              storedCardCustomerId: "cus_higher", storedCardDisplayMode: "all")

    let result = base.overlaying(higher)

    XCTAssertEqual(result.customerEmail, "base@example.com")
    XCTAssertEqual(result.customerPhoneNumber, "7784123123")
    XCTAssertEqual(result.storedCardSource, "customerId")
    XCTAssertEqual(result.storedCardCustomerId, "cus_higher")
    XCTAssertEqual(result.storedCardInstrumentIds, ["src_base"])
    XCTAssertEqual(result.storedCardDisplayMode, "all")
  }

  func test_decode_readsCustomerAndRememberMeAndStoredCardFields() {
    let json = """
    {
      "customerEmail": "jane@example.com",
      "customerPhoneCountryCode": "+44",
      "customerPhoneNumber": "7784123123",
      "rememberMeEmail": "jane@example.com",
      "rememberMePhoneCountryCode": "+44",
      "rememberMePhoneNumber": "7784123123",
      "storedCardSource": "customerId",
      "storedCardCustomerId": "cus_123",
      "storedCardInstrumentIds": ["src_a", "src_b"],
      "storedCardDefaultInstrumentId": "src_a",
      "captureStoredCardCvv": true,
      "storedCardDisplayMode": "all"
    }
    """
    let config = try? JSONDecoder().decode(LaunchConfig.self, from: Data(json.utf8))

    XCTAssertEqual(config?.customerEmail, "jane@example.com")
    XCTAssertEqual(config?.customerPhoneCountryCode, "+44")
    XCTAssertEqual(config?.rememberMePhoneNumber, "7784123123")
    XCTAssertEqual(config?.storedCardSource, "customerId")
    XCTAssertEqual(config?.storedCardInstrumentIds, ["src_a", "src_b"])
    XCTAssertEqual(config?.captureStoredCardCvv, true)
    XCTAssertEqual(config?.storedCardDisplayMode, "all")
  }

  func test_applyLaunchConfig_mutatesCustomerRememberMeAndStoredCardState() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(
      customerEmail: "jane@example.com",
      customerPhoneCountryCode: "+44",
      customerPhoneNumber: "7784123123",
      rememberMeEmail: "jane@example.com",
      rememberMePhoneCountryCode: "+44",
      rememberMePhoneNumber: "7784123123",
      storedCardSource: "customerId",
      storedCardCustomerId: "cus_123",
      captureStoredCardCvv: true,
      storedCardDisplayMode: "all"
    )

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.paymentSessionUserEmail, "jane@example.com")
    XCTAssertEqual(viewModel.paymentSessionCountryCode, "44") // leading "+" stripped
    XCTAssertEqual(viewModel.paymentSessionPhoneNumber, "7784123123")
    XCTAssertEqual(viewModel.userEmail, "jane@example.com")
    XCTAssertEqual(viewModel.userCountryCode, "44")
    XCTAssertEqual(viewModel.userPhoneNumber, "7784123123")
    XCTAssertEqual(viewModel.storedCardSource, .customerId)
    XCTAssertEqual(viewModel.customerId, "cus_123")
    XCTAssertTrue(viewModel.storedCardCaptureCVV)
    XCTAssertEqual(viewModel.storedCardDisplayMode, .all)
  }

  func test_applyLaunchConfig_phoneCountryCode_resolvesIso3166Alpha2ToDialingCode() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(customerPhoneCountryCode: "GB", rememberMePhoneCountryCode: "gb")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.paymentSessionCountryCode, "44")
    XCTAssertEqual(viewModel.userCountryCode, "44")
  }

  func test_applyLaunchConfig_storedCardInstrumentIds_joinsIntoCommaSeparatedField() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(
      storedCardSource: "instrumentIds",
      storedCardInstrumentIds: ["src_a", "src_b"],
      storedCardDefaultInstrumentId: "src_a"
    )

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.storedCardSource, .instrumentIds)
    XCTAssertEqual(viewModel.instrumentIds, "src_a,src_b")
    XCTAssertEqual(viewModel.defaultInstrumentId, "src_a")
  }

  // MARK: - StoredCardSource(configValue:)

  func test_storedCardSourceInit_mapsAndroidWireValuesCaseInsensitively() {
    XCTAssertEqual(StoredCardSource(configValue: "customerId"), .customerId)
    XCTAssertEqual(StoredCardSource(configValue: "INSTRUMENTIDS"), .instrumentIds)
    XCTAssertEqual(StoredCardSource(configValue: "none"), .none)
    XCTAssertNil(StoredCardSource(configValue: "not_a_source"))
  }

  // MARK: - StoredCardDisplayMode(configValue:)

  func test_storedCardDisplayModeInit_mapsAndroidWireValuesCaseInsensitively() {
    XCTAssertEqual(CheckoutComponents.StoredCardDisplayMode(configValue: "default"), .defaultCard)
    XCTAssertEqual(CheckoutComponents.StoredCardDisplayMode(configValue: "ALL"), .all)
    XCTAssertNil(CheckoutComponents.StoredCardDisplayMode(configValue: "not_a_mode"))
  }

  // MARK: - sdkModule

  func test_overlaying_sdkModule_higherPriorityWins() {
    let base = LaunchConfig(sdkModule: "card")
    let higher = LaunchConfig(sdkModule: "flow")

    XCTAssertEqual(base.overlaying(higher).sdkModule, "flow")
    XCTAssertEqual(base.overlaying(.empty).sdkModule, "card")
  }

  func test_decode_readsSdkModule() {
    let config = try? JSONDecoder().decode(LaunchConfig.self, from: Data(#"{"sdkModule":"card"}"#.utf8))
    XCTAssertEqual(config?.sdkModule, "card")
  }

  func test_applyLaunchConfig_mutatesSelectedComponentType() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(sdkModule: "card")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.selectedComponentType, .card)
  }

  func test_applyLaunchConfig_unknownSdkModule_keepsDefault() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(sdkModule: "not_a_module")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.selectedComponentType, .flow)
  }

  // MARK: - CheckoutComponent(configValue:)

  func test_checkoutComponentInit_mapsAccessibilityIdentifiersCaseInsensitively() {
    XCTAssertEqual(CheckoutComponent(configValue: "flow"), .flow)
    XCTAssertEqual(CheckoutComponent(configValue: "CARD"), .card)
    XCTAssertEqual(CheckoutComponent(configValue: "google_apple_pay"), .applePay)
    XCTAssertEqual(CheckoutComponent(configValue: "stored_card"), .storedCard)
    XCTAssertEqual(CheckoutComponent(configValue: "stc_pay"), .stcPay)
    XCTAssertEqual(CheckoutComponent(configValue: "address"), .address)
    XCTAssertEqual(CheckoutComponent(configValue: "cvv"), .cvv)
  }

  func test_checkoutComponentInit_unknownValue_returnsNil() {
    XCTAssertNil(CheckoutComponent(configValue: "not_a_component"))
  }

}

// MARK: - Appearance, stored card and merchant key fields

extension LaunchConfigHydratorTests {

  // MARK: - appearance, stored card schemes, stored card pay button and component callbacks

  func test_overlaying_appearanceSchemesPayButtonAndComponentCallbacks_higherPriorityWins() {
    let base = LaunchConfig(appearance: "default", storedCardAcceptedSchemes: ["visa", "mastercard"],
                            storedCardShowPayButton: true, componentCallbacks: ["HandleTap"])
    let higher = LaunchConfig(appearance: "dark", storedCardAcceptedSchemes: ["cartesbancaires"],
                              storedCardShowPayButton: false, componentCallbacks: ["HandleSubmit"])

    let result = base.overlaying(higher)

    XCTAssertEqual(result.appearance, "dark")
    XCTAssertEqual(result.storedCardAcceptedSchemes, ["cartesbancaires"])
    XCTAssertEqual(result.storedCardShowPayButton, false)
    XCTAssertEqual(result.componentCallbacks, ["HandleSubmit"])
  }

  func test_overlaying_appearanceSchemesPayButtonAndComponentCallbacks_baseSurvivesWhenHigherIsNil() {
    let base = LaunchConfig(appearance: "dark", storedCardAcceptedSchemes: ["visa"],
                            storedCardShowPayButton: false, componentCallbacks: ["HandleSubmit"])

    let result = base.overlaying(.empty)

    XCTAssertEqual(result.appearance, "dark")
    XCTAssertEqual(result.storedCardAcceptedSchemes, ["visa"])
    XCTAssertEqual(result.storedCardShowPayButton, false)
    XCTAssertEqual(result.componentCallbacks, ["HandleSubmit"])
  }

  func test_decode_readsAppearanceSchemesPayButtonAndComponentCallbacks() {
    let json = """
    {
      "appearance": "dark",
      "storedCardAcceptedSchemes": ["visa", "cartesbancaires"],
      "storedCardShowPayButton": false,
      "componentCallbacks": ["HandleTap", "HandleSubmit"]
    }
    """
    let config = try? JSONDecoder().decode(LaunchConfig.self, from: Data(json.utf8))

    XCTAssertEqual(config?.appearance, "dark")
    XCTAssertEqual(config?.storedCardAcceptedSchemes, ["visa", "cartesbancaires"])
    XCTAssertEqual(config?.storedCardShowPayButton, false)
    XCTAssertEqual(config?.componentCallbacks, ["HandleTap", "HandleSubmit"])
  }

  func test_applyLaunchConfig_mutatesAppearanceSchemesPayButtonAndComponentCallbacks() {
    let viewModel = MainViewModel()
    XCTAssertTrue(viewModel.isDefaultAppearance)      // preconditions: the hardcoded defaults
    XCTAssertTrue(viewModel.showStoredCardPayButton)
    XCTAssertFalse(viewModel.handleSubmitManually)
    XCTAssertTrue(viewModel.storedCardAcceptedCardSchemes.isEmpty)

    let config = LaunchConfig(appearance: "dark", storedCardAcceptedSchemes: ["cartesbancaires", "visa"],
                              storedCardShowPayButton: false, componentCallbacks: ["HandleTap", "HandleSubmit"])

    viewModel.applyLaunchConfig(config)

    XCTAssertFalse(viewModel.isDefaultAppearance)
    XCTAssertEqual(viewModel.storedCardAcceptedCardSchemes, [.cartesBancaires, .visa])
    XCTAssertFalse(viewModel.showStoredCardPayButton)
    XCTAssertTrue(viewModel.handleSubmitManually)
  }

  func test_applyLaunchConfig_componentCallbacksWithoutHandleSubmit_disablesManualHandling() {
    let viewModel = MainViewModel()
    viewModel.handleSubmitManually = true

    viewModel.applyLaunchConfig(LaunchConfig(componentCallbacks: ["HandleTap"]))

    XCTAssertFalse(viewModel.handleSubmitManually)
  }

  func test_applyLaunchConfig_componentCallbacksMatchHandleSubmitCaseInsensitively() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(componentCallbacks: ["handlesubmit"]))

    XCTAssertTrue(viewModel.handleSubmitManually)
  }

  func test_applyLaunchConfig_unknownAppearance_keepsDefault() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(appearance: "DarkTheme"))

    XCTAssertTrue(viewModel.isDefaultAppearance)
  }

  func test_applyLaunchConfig_storedCardSchemes_dropUnknownNamesAndEmptyAcceptsEverything() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(storedCardAcceptedSchemes: ["visa", "not_a_scheme"]))
    XCTAssertEqual(viewModel.storedCardAcceptedCardSchemes, [.visa])

    // An explicit [] clears the restriction rather than being ignored.
    viewModel.applyLaunchConfig(LaunchConfig(storedCardAcceptedSchemes: []))
    XCTAssertTrue(viewModel.storedCardAcceptedCardSchemes.isEmpty)
  }

  func test_applyLaunchConfig_storedCardSchemes_noNamesMatch_acceptsEverything() {
    let viewModel = MainViewModel()
    viewModel.applyLaunchConfig(LaunchConfig(storedCardAcceptedSchemes: ["visa"]))

    viewModel.applyLaunchConfig(LaunchConfig(storedCardAcceptedSchemes: ["vsia", "not_a_scheme"]))

    XCTAssertTrue(viewModel.storedCardAcceptedCardSchemes.isEmpty)
  }

  // MARK: - AppearancePreset(configValue:)

  func test_appearancePresetInit_matchesIgnoringCase() {
    XCTAssertEqual(AppearancePreset(configValue: "default"), .default)
    XCTAssertEqual(AppearancePreset(configValue: "Dark"), .dark)
    XCTAssertNil(AppearancePreset(configValue: "DarkTheme"))
  }

  // MARK: - CardScheme(configValue:)

  func test_cardSchemeInit_matchesIgnoringCaseAndSeparators() {
    XCTAssertEqual(CardScheme(configValue: "visa"), .visa)
    XCTAssertEqual(CardScheme(configValue: "cartesbancaires"), .cartesBancaires)
    XCTAssertEqual(CardScheme(configValue: "cartes-bancaires"), .cartesBancaires)
    XCTAssertEqual(CardScheme(configValue: "CartesBancaires"), .cartesBancaires)
    XCTAssertEqual(CardScheme(configValue: "american_express"), .americanExpress)
    XCTAssertEqual(CardScheme(configValue: "chinaunionpay"), .chinaUnionPay)
  }

  func test_cardSchemeInit_rejectsUnknownAndNonSelectableValues() {
    XCTAssertNil(CardScheme(configValue: "not_a_scheme"))
    XCTAssertNil(CardScheme(configValue: ""))
    // `unknown` is a detection result, not something a merchant can accept.
    XCTAssertNil(CardScheme(configValue: "unknown"))
  }

  func test_cardSchemeInit_resolvesEverySelectableCase() {
    for scheme in CardScheme.selectableCases {
      XCTAssertEqual(CardScheme(configValue: scheme.rawValue), scheme)
    }
  }

  // MARK: - country and merchantKey

  func test_overlaying_countryAndMerchantKey_higherPriorityWins() {
    let base = LaunchConfig(country: "GB", merchantKey: "base-merchant")
    let higher = LaunchConfig(country: "AE", merchantKey: "higher-merchant")

    let result = base.overlaying(higher)

    XCTAssertEqual(result.country, "AE")
    XCTAssertEqual(result.merchantKey, "higher-merchant")
  }

  func test_overlaying_countryAndMerchantKey_baseSurvivesWhenHigherIsNil() {
    let base = LaunchConfig(country: "GB", merchantKey: "base-merchant")
    let higher = LaunchConfig()

    let result = base.overlaying(higher)

    XCTAssertEqual(result.country, "GB")
    XCTAssertEqual(result.merchantKey, "base-merchant")
  }

  func test_decode_readsCountryAndMerchantKey() {
    let json = """
    {
      "country": "AE",
      "merchantKey": "qa-merchant"
    }
    """
    let config = try? JSONDecoder().decode(LaunchConfig.self, from: Data(json.utf8))

    XCTAssertEqual(config?.country, "AE")
    XCTAssertEqual(config?.merchantKey, "qa-merchant")
  }

  func test_applyLaunchConfig_mutatesSelectedCountry() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(country: "AE")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.selectedCountry, .ae)
  }

  func test_applyLaunchConfig_unknownCountry_keepsDefault() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(country: "FR")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.selectedCountry, .gb)
  }
}

private struct MockMerchantKeyPresetProvider: MerchantKeyPresetProviding {
  let presets: MerchantKeyPresets

  func load() async -> MerchantKeyPresets {
    presets
  }
}

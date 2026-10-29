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
    let base = LaunchConfig(locale: "en-GB", environment: "sandbox", render: nil, paymentSessionAmount: 10500, paymentSessionCurrency: "GBP")
    let higher = LaunchConfig(locale: "ar", environment: nil, render: "auto", paymentSessionAmount: nil, paymentSessionCurrency: nil)

    let result = base.overlaying(higher)

    XCTAssertEqual(result.locale, "ar")          // overridden
    XCTAssertEqual(result.environment, "sandbox") // base survives (higher is nil)
    XCTAssertEqual(result.render, "auto")         // added by higher
    XCTAssertEqual(result.paymentSessionAmount, 10500)          // base survives
    XCTAssertEqual(result.paymentSessionCurrency, "GBP")        // base survives
  }

  func test_overlaying_emptyHigher_returnsBaseUnchanged() {
    let base = LaunchConfig(locale: "ar", environment: "production", render: "auto", paymentSessionAmount: 99, paymentSessionCurrency: "AED")
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
    let env = ["LAUNCH_CONFIG": #"{"environment":"production","paymentSessionAmount":250}"#]
    let config = LaunchConfigHydrator.environmentConfig(env)
    XCTAssertEqual(config?.environment, "production")
    XCTAssertEqual(config?.paymentSessionAmount, 250)
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
    XCTAssertEqual(config?.paymentSessionCurrency, "GBP")
    XCTAssertEqual(config?.paymentSessionAmount, 10500)
  }

  // MARK: - Precedence (resolve)

  func test_resolve_deepLinkOverridesEnvironmentOverridesBundled() {
    let deepLink = URL(string: "checkoutexponewarch://?config=eyJsb2NhbGUiOiJhciJ9")! // {"locale":"ar"}
    let env = ["LAUNCH_CONFIG": #"{"locale":"en-GB","environment":"production"}"#]

    let resolved = LaunchConfigHydrator.resolve(deepLinkURL: deepLink, environment: env, bundle: .main)

    XCTAssertEqual(resolved.locale, "ar")            // deep link wins over env
    XCTAssertEqual(resolved.environment, "production") // env wins over bundled
    XCTAssertEqual(resolved.paymentSessionCurrency, "GBP")          // bundled baseline survives
    XCTAssertEqual(resolved.paymentSessionAmount, 10500)            // bundled baseline survives
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
    let config = LaunchConfig(locale: "ar", environment: "production", render: "auto", paymentSessionAmount: 42, paymentSessionCurrency: "AED")

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
    let config = LaunchConfig(locale: "klingon", environment: "mars", render: nil, paymentSessionAmount: nil, paymentSessionCurrency: "XYZ")

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

    let config = LaunchConfig(paymentSessionEmail: "", paymentSessionPhone: .init(countryCode: "", number: ""))
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
    let base = LaunchConfig(paymentSessionEmail: "base@example.com", storedCardSource: "instrumentIds",
                            storedCardInstrumentIds: ["src_base"], storedCardDisplayMode: "default")
    let higher = LaunchConfig(paymentSessionPhone: .init(number: "7784123123"), storedCardSource: "customerId",
                              storedCardCustomerId: "cus_higher", storedCardDisplayMode: "all")

    let result = base.overlaying(higher)

    XCTAssertEqual(result.paymentSessionEmail, "base@example.com")
    XCTAssertEqual(result.paymentSessionPhone?.number, "7784123123")
    XCTAssertEqual(result.storedCardSource, "customerId")
    XCTAssertEqual(result.storedCardCustomerId, "cus_higher")
    XCTAssertEqual(result.storedCardInstrumentIds, ["src_base"])
    XCTAssertEqual(result.storedCardDisplayMode, "all")
  }

  func test_decode_readsCustomerAndRememberMeAndStoredCardFields() {
    let json = """
    {
      "paymentSessionEmail": "jane@example.com",
      "paymentSessionPhone": { "countryCode": "+44", "number": "7784123123" },
      "rememberMeEmail": "jane@example.com",
      "rememberMePhoneNumber": { "countryCode": "+44", "number": "7784123123" },
      "storedCardSource": "customerId",
      "storedCardCustomerId": "cus_123",
      "storedCardInstrumentIds": ["src_a", "src_b"],
      "storedCardDefaultInstrumentId": "src_a",
      "captureStoredCardCvv": true,
      "storedCardDisplayMode": "all"
    }
    """
    let config = try? JSONDecoder().decode(LaunchConfig.self, from: Data(json.utf8))

    XCTAssertEqual(config?.paymentSessionEmail, "jane@example.com")
    XCTAssertEqual(config?.paymentSessionPhone?.countryCode, "+44")
    XCTAssertEqual(config?.rememberMePhoneNumber?.number, "7784123123")
    XCTAssertEqual(config?.storedCardSource, "customerId")
    XCTAssertEqual(config?.storedCardInstrumentIds, ["src_a", "src_b"])
    XCTAssertEqual(config?.captureStoredCardCvv, true)
    XCTAssertEqual(config?.storedCardDisplayMode, "all")
  }

  func test_applyLaunchConfig_mutatesCustomerRememberMeAndStoredCardState() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(
      paymentSessionEmail: "jane@example.com",
      paymentSessionPhone: .init(countryCode: "+44", number: "7784123123"),
      rememberMeEmail: "jane@example.com",
      rememberMePhoneNumber: .init(countryCode: "+44", number: "7784123123"),
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
    let config = LaunchConfig(paymentSessionPhone: .init(countryCode: "GB"), rememberMePhoneNumber: .init(countryCode: "gb"))

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
    // Spelled out: a bare `.none` would read as Optional.none.
    XCTAssertEqual(StoredCardSource(configValue: "none"), StoredCardSource.none)
    XCTAssertNil(StoredCardSource(configValue: "not_a_source"))
  }

  // MARK: - StoredCardDisplayMode(configValue:)

  func test_storedCardDisplayModeInit_mapsAndroidWireValuesCaseInsensitively() {
    XCTAssertEqual(CheckoutComponents.StoredCardDisplayMode(configValue: "default"), .defaultCard)
    XCTAssertEqual(CheckoutComponents.StoredCardDisplayMode(configValue: "ALL"), .all)
    XCTAssertNil(CheckoutComponents.StoredCardDisplayMode(configValue: "not_a_mode"))
  }

  // MARK: - selectedComponent

  func test_overlaying_selectedComponent_higherPriorityWins() {
    let base = LaunchConfig(selectedComponent: "card")
    let higher = LaunchConfig(selectedComponent: "flow")

    XCTAssertEqual(base.overlaying(higher).selectedComponent, "flow")
    XCTAssertEqual(base.overlaying(.empty).selectedComponent, "card")
  }

  func test_decode_readsSelectedComponent() {
    let config = try? JSONDecoder().decode(LaunchConfig.self, from: Data(#"{"selectedComponent":"card"}"#.utf8))
    XCTAssertEqual(config?.selectedComponent, "card")
  }

  func test_applyLaunchConfig_mutatesSelectedComponentType() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(selectedComponent: "card")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.selectedComponentType, .card)
  }

  func test_applyLaunchConfig_unknownSelectedComponent_keepsDefault() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(selectedComponent: "not_a_module")

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

  func test_applyLaunchConfig_componentCallbacksWithOnAuthorizedReject_enablesRejection() {
    let viewModel = MainViewModel()
    XCTAssertFalse(viewModel.rejectPaymentOnAuthorized)

    viewModel.applyLaunchConfig(LaunchConfig(componentCallbacks: ["HandleTap", "OnAuthorizedReject"]))

    XCTAssertTrue(viewModel.rejectPaymentOnAuthorized)
  }

  func test_applyLaunchConfig_componentCallbacksWithoutOnAuthorizedReject_disablesRejection() {
    let viewModel = MainViewModel()
    viewModel.rejectPaymentOnAuthorized = true

    viewModel.applyLaunchConfig(LaunchConfig(componentCallbacks: ["HandleSubmit"]))

    XCTAssertFalse(viewModel.rejectPaymentOnAuthorized)
  }

  func test_applyLaunchConfig_componentCallbacksMatchOnAuthorizedRejectCaseInsensitively() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(componentCallbacks: ["onauthorizedreject"]))

    XCTAssertTrue(viewModel.rejectPaymentOnAuthorized)
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
    let base = LaunchConfig(paymentSessionCountry: "GB", merchantKey: "base-merchant")
    let higher = LaunchConfig(paymentSessionCountry: "AE", merchantKey: "higher-merchant")

    let result = base.overlaying(higher)

    XCTAssertEqual(result.paymentSessionCountry, "AE")
    XCTAssertEqual(result.merchantKey, "higher-merchant")
  }

  func test_overlaying_countryAndMerchantKey_baseSurvivesWhenHigherIsNil() {
    let base = LaunchConfig(paymentSessionCountry: "GB", merchantKey: "base-merchant")
    let higher = LaunchConfig()

    let result = base.overlaying(higher)

    XCTAssertEqual(result.paymentSessionCountry, "GB")
    XCTAssertEqual(result.merchantKey, "base-merchant")
  }

  func test_decode_readsCountryAndMerchantKey() {
    let json = """
    {
      "paymentSessionCountry": "AE",
      "merchantKey": "qa-merchant"
    }
    """
    let config = try? JSONDecoder().decode(LaunchConfig.self, from: Data(json.utf8))

    XCTAssertEqual(config?.paymentSessionCountry, "AE")
    XCTAssertEqual(config?.merchantKey, "qa-merchant")
  }

  func test_applyLaunchConfig_mutatesSelectedCountry() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(paymentSessionCountry: "AE")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.selectedCountry, .ae)
  }

  func test_applyLaunchConfig_unknownCountry_keepsDefault() {
    let viewModel = MainViewModel()
    let config = LaunchConfig(paymentSessionCountry: "FR")

    viewModel.applyLaunchConfig(config)

    XCTAssertEqual(viewModel.selectedCountry, .gb)
  }
}

// MARK: - Shared base config and the remaining settings

extension LaunchConfigHydratorTests {

  func test_decode_sharedBaseConfig_appliesEverySetting() throws {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(try decode(Self.sharedBaseJSON))

    XCTAssertEqual(viewModel.selectedComponentType, .flow)
    XCTAssertEqual(viewModel.selectedLocale, .locale(.en_GB))
    XCTAssertEqual(viewModel.amount, 10500)
    XCTAssertEqual(viewModel.selectedCurrency, .gbp)
    XCTAssertEqual(viewModel.paymentSessionUserEmail, "customer+test1@checkout.com")
    XCTAssertEqual(viewModel.paymentSessionCountryCode, "44")
    XCTAssertEqual(viewModel.paymentSessionPhoneNumber, "7700123456")
    XCTAssertTrue(viewModel.isShowUpdateView)
    XCTAssertTrue(viewModel.showCardPayButton)
    XCTAssertEqual(viewModel.paymentButtonAction, .payment)
    XCTAssertEqual(viewModel.displayCardHolderName, .top)
    XCTAssertEqual(viewModel.cardHolderNameMaxLength, 50)
    XCTAssertFalse(viewModel.hideSecurityCode)
    XCTAssertEqual(viewModel.cardAcceptedCardSchemes, [.visa, .mastercard])
    XCTAssertEqual(viewModel.cardAcceptedCardTypes, [.credit, .debit])
    XCTAssertTrue(viewModel.showApplePayButton)
    XCTAssertEqual(viewModel.applePayAcceptedCardSchemes, [])
    XCTAssertTrue(viewModel.showRememberMePayButton)
    XCTAssertEqual(viewModel.userEmail, "ckoautomationtest@checkout.com")
    XCTAssertEqual(viewModel.userCountryCode, "44")
    XCTAssertEqual(viewModel.userPhoneNumber, "7700900900")
    XCTAssertEqual(viewModel.rememberMeAcceptedCardSchemes, [.mastercard])
    XCTAssertEqual(viewModel.rememberMeAcceptedCardTypes, [.credit, .debit])
  }

  func test_decode_wronglyTypedValue_rejectsThePayload() {
    // Strict decoding: a phone sent as a plain string, as the old native schema did, fails the whole payload.
    let json = #"{"locale": "ar", "rememberMePhoneNumber": "7784123123"}"#
    XCTAssertNil(LaunchConfigHydrator.environmentConfig(["LAUNCH_CONFIG": json]))
  }

  func test_overlaying_remainingSettings_higherPriorityWinsAndBaseSurvives() {
    let base = LaunchConfig(showPayButton: true, applePaySettings: .init(showApplePayButton: true), cvvLengths: [3])
    let higher = LaunchConfig(showPayButton: false, acceptedCardSchemes: [])

    let result = base.overlaying(higher)

    XCTAssertEqual(result.showPayButton, false)
    XCTAssertEqual(result.acceptedCardSchemes, [])
    XCTAssertEqual(result.applePaySettings, .init(showApplePayButton: true))
    XCTAssertEqual(result.cvvLengths, [3])
    XCTAssertEqual(base.overlaying(.empty), base)
  }

  func test_applyLaunchConfig_localesComponentAndPaymentMethods() throws {
    let arabic = try XCTUnwrap(CheckoutComponents.Locale(rawValue: "ar"))
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(
      locale: "en-GB", selectedComponent: "applePay", paymentSessionLocale: "ar",
      paymentMethods: ["card", "googlepay", "klarna", "remember_me"]
    ))

    XCTAssertEqual(viewModel.selectedLocale, .locale(.en_GB))
    XCTAssertEqual(viewModel.paymentSessionSelectedLocale, .locale(arabic))
    XCTAssertEqual(viewModel.selectedComponentType, .applePay)
    XCTAssertEqual(viewModel.selectedPaymentMethodTypes, [.card, .applePay, .klarna])
  }

  func test_applyLaunchConfig_customTranslations_selectsCustomisedLocaleOnly() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(locale: "en-GB", customTranslations: true))

    XCTAssertEqual(viewModel.selectedLocale, .customised)
    XCTAssertEqual(viewModel.paymentSessionSelectedLocale, .locale(.en_GB))
  }

  func test_applyLaunchConfig_cardSettings() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(
      showPayButton: false, paymentButtonAction: "tokenize", displayCardHolderName: "hidden",
      cardholderNameMaxLength: 8, hideSecurityCode: true, prefilledCardholderName: "Jane Doe",
      acceptedCardSchemes: ["americanExpress", "unknown"], acceptedCardTypes: ["deferred_debit"],
      customButtonOperation: "tokenization", cvvLengths: [4, 7]
    ))

    XCTAssertFalse(viewModel.showCardPayButton)
    XCTAssertEqual(viewModel.paymentButtonAction, .tokenization)
    XCTAssertEqual(viewModel.displayCardHolderName, .hidden)
    XCTAssertEqual(viewModel.cardHolderNameMaxLength, 8)
    XCTAssertTrue(viewModel.hideSecurityCode)
    XCTAssertEqual(viewModel.prefilledCardholderName, "Jane Doe")
    XCTAssertEqual(viewModel.cardAcceptedCardSchemes, [.americanExpress])
    XCTAssertEqual(viewModel.cardAcceptedCardTypes, [.deferredDebit])
    XCTAssertEqual(viewModel.customButtonOperation, .tokenization)
    XCTAssertEqual(viewModel.selectedCVVLengths, [.four])
  }

  func test_applyLaunchConfig_outOfRangeCardValues_keepDefaults() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(cardholderNameMaxLength: 0, cvvLengths: []))

    XCTAssertEqual(viewModel.cardHolderNameMaxLength, 255)
    XCTAssertEqual(viewModel.selectedCVVLengths, [.three, .four])
  }

  func test_applyLaunchConfig_walletAndKlarnaSettings() throws {
    let viewModel = MainViewModel()
    let config = try decode("""
    {
      "applePaySettings": {
        "showApplePayButton": false, "acceptedCardTypes": ["credit"],
        "buttonStyle": "white_outline", "buttonType": "add_money", "totalType": "pending"
      },
      "showUpdateAmountSection": true, "showApmPayButton": false, "klarnaTheme": "dark", "klarnaReturnUrl": "app://klarna"
    }
    """)

    viewModel.applyLaunchConfig(config)

    XCTAssertFalse(viewModel.showApplePayButton)
    XCTAssertEqual(viewModel.applePayAcceptedCardTypes, [.credit])
    XCTAssertEqual(viewModel.applePayButtonStyle, .whiteOutline)
    XCTAssertEqual(viewModel.applePayButtonType, .addMoney)
    XCTAssertEqual(viewModel.selectedApplePayType, .pending)
    XCTAssertTrue(viewModel.isShowUpdateView)
    XCTAssertFalse(viewModel.showAPMPayButton)
    #if canImport(CheckoutKlarnaSDK)
    XCTAssertEqual(viewModel.klarnaTheme, .dark)
    XCTAssertEqual(viewModel.klarnaReturnURLString, "app://klarna")
    #endif
  }

  func test_applyLaunchConfig_sessionRememberMeStoredCardAndAddressSettings() {
    addTeardownBlock {
      UserDefaults.standard.removeObject(forKey: "checkout_components_force_stored_card_consent_type")
    }
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(
      paymentSessionName: "Test User", storePaymentDetails: "undefined",
      showRememberMePayButton: false, rememberMeCardTypes: ["prepaid"], storedCardAcceptedTypes: ["debit"],
      storedCardPaymentButtonAction: "tokenization", storedCardConsentOverride: "implicit", addressConfig: "no_prefill"
    ))

    XCTAssertEqual(viewModel.paymentSessionUsername, "Test User")
    XCTAssertEqual(viewModel.storePaymentDetails, .undefined)
    XCTAssertFalse(viewModel.showRememberMePayButton)
    XCTAssertEqual(viewModel.rememberMeAcceptedCardTypes, [.prepaid])
    XCTAssertEqual(viewModel.storedCardAcceptedCardTypes, [.debit])
    XCTAssertEqual(viewModel.storedCardPaymentButtonAction, .tokenization)
    XCTAssertEqual(viewModel.storedCardConsentOverride, .implicit)
    XCTAssertEqual(viewModel.selectedAddressConfiguration, .noPrefill)
  }

  func test_applyLaunchConfig_emptyAddressConfig_isRejectedForStandaloneAddress() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(render: "auto", selectedComponent: "address", addressConfig: "empty"))

    XCTAssertEqual(viewModel.selectedComponentType, .address)
    XCTAssertEqual(viewModel.selectedAddressConfiguration, .prefillCustomized)
    XCTAssertNotNil(viewModel.selectedAddressConfiguration.addressConfiguration)
  }

  func test_applyLaunchConfig_emptyAddressConfig_isAcceptedForCard() {
    let viewModel = MainViewModel()

    viewModel.applyLaunchConfig(LaunchConfig(selectedComponent: "card", addressConfig: "empty"))

    XCTAssertEqual(viewModel.selectedAddressConfiguration, .empty)
  }

  func test_overlaying_partialPhones_mergeMembersAcrossSources() {
    let environment = LaunchConfig(
      paymentSessionPhone: .init(countryCode: "971", number: "500000000"),
      rememberMePhoneNumber: .init(countryCode: "44", number: "7700900900")
    )
    let deepLink = LaunchConfig(
      paymentSessionPhone: .init(number: "511111111"),
      rememberMePhoneNumber: .init(countryCode: "", number: nil)
    )

    let result = environment.overlaying(deepLink)

    XCTAssertEqual(result.paymentSessionPhone, .init(countryCode: "971", number: "511111111"))
    XCTAssertEqual(result.rememberMePhoneNumber, .init(countryCode: "", number: "7700900900"))

    let viewModel = MainViewModel()
    viewModel.applyLaunchConfig(result)
    XCTAssertEqual(viewModel.paymentSessionCountryCode, "971")
    XCTAssertEqual(viewModel.paymentSessionPhoneNumber, "511111111")
    XCTAssertEqual(viewModel.userPhoneNumber, "7700900900")
  }

  func test_overlaying_partialApplePaySettings_keepLowerMembers() {
    let environment = LaunchConfig(applePaySettings: .init(
      showApplePayButton: false, acceptedCardSchemes: ["visa"], acceptedCardTypes: [], buttonStyle: "black"
    ))
    let deepLink = LaunchConfig(applePaySettings: .init(buttonStyle: "white_outline"))

    let result = environment.overlaying(deepLink)

    XCTAssertEqual(result.applePaySettings, .init(
      showApplePayButton: false, acceptedCardSchemes: ["visa"], acceptedCardTypes: [], buttonStyle: "white_outline"
    ))

    let viewModel = MainViewModel()
    viewModel.applyLaunchConfig(result)
    XCTAssertFalse(viewModel.showApplePayButton)
    XCTAssertEqual(viewModel.applePayAcceptedCardSchemes, [.visa])
    XCTAssertEqual(viewModel.applePayButtonStyle, .whiteOutline)
  }

  func test_applyLaunchConfig_stagingKeys_replaceTheFlagSelection() {
    preserveStagingFlagDefaults()
    let viewModel = MainViewModel()
    viewModel.hidePrefilledDataEnabled = true

    viewModel.applyLaunchConfig(LaunchConfig(
      stagingKeys: ["enable_capture_rm_saved_card_cvv", "ENABLE-REMEMBER-ME-DISCREET-UI", "enable_custom_tabs"]
    ))

    XCTAssertTrue(viewModel.captureCvvEnabled)
    XCTAssertTrue(viewModel.rememberMeDiscreetUIEnabled)
    XCTAssertFalse(viewModel.hidePrefilledDataEnabled)   // unlisted, so switched off
    XCTAssertFalse(viewModel.isIgnoreRememberMeEmailFeatureFlagEnabled)
    XCTAssertFalse(viewModel.storedCardsWithRememberMeEnabled)
  }

  func test_applyLaunchConfig_stagingKeys_emptyClearsAndAbsentLeavesAlone() {
    preserveStagingFlagDefaults()
    let viewModel = MainViewModel()
    viewModel.storedCardsWithRememberMeEnabled = true

    viewModel.applyLaunchConfig(LaunchConfig(locale: "ar"))
    XCTAssertTrue(viewModel.storedCardsWithRememberMeEnabled)

    viewModel.applyLaunchConfig(LaunchConfig(stagingKeys: []))
    XCTAssertFalse(viewModel.storedCardsWithRememberMeEnabled)
  }

  func test_bundledConfig_matchesTheViewModelDefaults() throws {
    preserveStagingFlagDefaults()
    let bundled = try XCTUnwrap(LaunchConfigHydrator.bundledConfig(in: .main))
    let defaults = MainViewModel()
    let hydrated = MainViewModel()

    hydrated.applyLaunchConfig(bundled)

    // Every setting the bundled file drives, so it can only restate the defaults.
    func same<Value: Equatable>(_ keyPath: KeyPath<MainViewModel, Value>, line: UInt = #line) {
      XCTAssertEqual(hydrated[keyPath: keyPath], defaults[keyPath: keyPath], line: line)
    }
    same(\.selectedEnvironment)
    same(\.selectedLocale)
    same(\.paymentSessionSelectedLocale)
    same(\.selectedComponentType)
    same(\.isDefaultAppearance)
    same(\.amount)
    same(\.selectedCurrency)
    same(\.selectedCountry)
    same(\.paymentSessionUserEmail)
    same(\.paymentSessionUsername)
    same(\.paymentSessionCountryCode)
    same(\.paymentSessionPhoneNumber)
    same(\.storePaymentDetails)
    same(\.showCardPayButton)
    same(\.paymentButtonAction)
    same(\.displayCardHolderName)
    same(\.cardHolderNameMaxLength)
    same(\.hideSecurityCode)
    same(\.prefilledCardholderName)
    same(\.cardAcceptedCardSchemes)
    same(\.cardAcceptedCardTypes)
    same(\.selectedAddressConfiguration)
    same(\.customButtonOperation)
    same(\.selectedCVVLengths)
    same(\.showApplePayButton)
    same(\.applePayAcceptedCardSchemes)
    same(\.applePayAcceptedCardTypes)
    same(\.applePayButtonStyle)
    same(\.applePayButtonType)
    same(\.selectedApplePayType)
    same(\.isShowUpdateView)
    same(\.showAPMPayButton)
    #if canImport(CheckoutKlarnaSDK)
    same(\.klarnaTheme)
    same(\.klarnaReturnURLString)
    #endif
    same(\.showRememberMePayButton)
    same(\.userEmail)
    same(\.userCountryCode)
    same(\.userPhoneNumber)
    same(\.rememberMeAcceptedCardSchemes)
    same(\.rememberMeAcceptedCardTypes)
    same(\.storedCardSource)
    same(\.customerId)
    same(\.instrumentIds)
    same(\.defaultInstrumentId)
    same(\.storedCardCaptureCVV)
    same(\.storedCardDisplayMode)
    same(\.storedCardAcceptedCardSchemes)
    same(\.storedCardAcceptedCardTypes)
    same(\.showStoredCardPayButton)
    same(\.storedCardPaymentButtonAction)
    same(\.storedCardConsentOverride)
    same(\.handleSubmitManually)
    same(\.isIgnoreRememberMeEmailFeatureFlagEnabled)
    same(\.captureCvvEnabled)
    same(\.hidePrefilledDataEnabled)
    same(\.rememberMeDiscreetUIEnabled)
    same(\.storedCardsWithRememberMeEnabled)
  }

  func test_checkoutComponentInit_acceptsCaseNames() {
    XCTAssertEqual(CheckoutComponent(configValue: "applePay"), .applePay)
    XCTAssertEqual(CheckoutComponent(configValue: "googlePay"), .applePay)
    XCTAssertEqual(CheckoutComponent(configValue: "tabby"), .tabby)
    XCTAssertEqual(CheckoutComponent(configValue: "storedCard"), .storedCard)
  }

  // MARK: - Helpers

  private func decode(_ json: String) throws -> LaunchConfig {
    try JSONDecoder().decode(LaunchConfig.self, from: Data(json.utf8))
  }

  /// The flags persist to UserDefaults in `didSet`, so restore whatever the suite started with.
  private func preserveStagingFlagDefaults() {
    let keys = [
      "checkout_components_disable_forwarding_emails",
      "checkout_components_capture_cvv",
      "checkout_components_hide_prefilled_data",
      "checkout_components_use_remember_me_discreet_ui",
      "checkout_components_use_stored_cards_with_remember_me"
    ]
    let saved = keys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
    addTeardownBlock {
      for (key, value) in saved {
        UserDefaults.standard.set(value, forKey: key)
      }
    }
  }

  private static let sharedBaseJSON = """
  {
    "environment": "sandbox", "locale": "en-GB", "selectedComponent": "flow",
    "paymentSessionAmount": 10500, "paymentSessionCurrency": "GBP",
    "paymentSessionEmail": "customer+test1@checkout.com",
    "paymentSessionPhone": { "countryCode": "44", "number": "7700123456" },
    "showUpdateAmountSection": true, "showPayButton": true, "paymentButtonAction": "payment",
    "displayCardHolderName": "top", "cardholderNameMaxLength": 50, "hideSecurityCode": false,
    "acceptedCardSchemes": ["visa", "mastercard"], "acceptedCardTypes": ["credit", "debit"],
    "applePaySettings": { "showApplePayButton": true, "acceptedCardSchemes": [], "acceptedCardTypes": [] },
    "googlePaySettings": { "acceptedCardSchemes": [], "acceptedCardTypes": [] },
    "isRememberMeEnabled": false, "showRememberMePayButton": true,
    "rememberMeEmail": "ckoautomationtest@checkout.com",
    "rememberMePhoneNumber": { "countryCode": "44", "number": "7700900900" },
    "rememberMeCardSchemes": ["mastercard"], "rememberMeCardTypes": ["credit", "debit"]
  }
  """
}

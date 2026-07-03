//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import XCTest
@testable import SampleApplication

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
    XCTAssertNil(resolved.locale)   // not in baseline -> view model defaults apply
    XCTAssertNil(resolved.render)
  }

  func test_resolve_malformedSources_doNotThrowAndFallBack() {
    let badURL = URL(string: "checkoutexponewarch://?config=%21%21%21")!
    let badEnv = ["LAUNCH_CONFIG": "}{"]

    // Graceful degradation (AC 2): no crash, falls back to bundled baseline.
    let resolved = LaunchConfigHydrator.resolve(deepLinkURL: badURL, environment: badEnv, bundle: .main)
    XCTAssertEqual(resolved.environment, "sandbox")
  }

  // MARK: - State mutation (applyLaunchConfig)

  @MainActor
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

  @MainActor
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

  @MainActor
  func test_applyLaunchConfig_emptyConfig_isNoOp() {
    let viewModel = MainViewModel()
    XCTAssertFalse(viewModel.applyLaunchConfig(.empty))
    XCTAssertEqual(viewModel.selectedLocale.localeString, "en-GB")
    XCTAssertEqual(viewModel.amount, 10500)
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
}

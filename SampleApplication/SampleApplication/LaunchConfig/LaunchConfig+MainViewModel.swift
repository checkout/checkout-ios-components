//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

#if canImport(CheckoutKlarnaSDK)
import CheckoutKlarnaSDK
#endif

import Foundation

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
    applyCardSettings(from: config)
    applyStandaloneComponentSettings(from: config)
    applyWalletSettings(from: config)
    applyKlarnaSettings(from: config)
    applyRememberMeSettings(from: config)
    applyStoredCardSettings(from: config)
    applyStoredCardDisplaySettings(from: config)
    applyAppearanceSettings(from: config)
    applyStagingKeys(from: config)
    return config.rendersAutomatically
  }

  private func applyGeneralSettings(from config: LaunchConfig) {
    if let localeString = config.locale,
       let locale = CheckoutComponents.Locale(rawValue: localeString) {
      selectedLocale = .locale(locale)
      paymentSessionSelectedLocale = .locale(locale)
    }
    if let localeString = config.paymentSessionLocale,
       let locale = CheckoutComponents.Locale(rawValue: localeString) {
      paymentSessionSelectedLocale = .locale(locale)
    }
    if config.customTranslations == true {
      selectedLocale = .customised
    }

    if let environmentString = config.environment,
       let environment = CheckoutComponents.Environment(configValue: environmentString) {
      selectedEnvironment = environment
    }

    if let moduleString = config.selectedComponent,
       let module = CheckoutComponent(configValue: moduleString) {
      selectedComponentType = module
    }

    if let methods = config.paymentMethods {
      selectedPaymentMethodTypes = Set(methods.compactMap(PaymentMethodType.init(configValue:)))
    }

    #if INTERNAL_SAMPLE_APP
    if let merchantKeyName = config.merchantKey,
       let preset = availableMerchantKeys.first(where: { $0.name == merchantKeyName }) {
      selectedMerchantKey = preset
    }
    #endif
  }

  private func applyPaymentSettings(from config: LaunchConfig) {
    if let currencyString = config.paymentSessionCurrency,
       let currency = CurrencyOption(rawValue: currencyString.uppercased()) {
      selectedCurrency = currency
    }

    if let amount = config.paymentSessionAmount {
      self.amount = amount
    }

    if let countryString = config.paymentSessionCountry,
       let country = CountryOption(rawValue: countryString.uppercased()) {
      selectedCountry = country
    }

    if let option = ConfigName.match(config.storePaymentDetails, as: StorePaymentDetailsOption.self) {
      storePaymentDetails = option
    }
  }

  private func applyCustomerSettings(from config: LaunchConfig) {
    if let email = config.paymentSessionEmail {
      paymentSessionUserEmail = email
    }
    if let name = config.paymentSessionName {
      paymentSessionUsername = name
    }
    if let countryCode = config.paymentSessionPhone?.countryCode {
      paymentSessionCountryCode = Self.dialingCode(from: countryCode)
    }
    if let number = config.paymentSessionPhone?.number {
      paymentSessionPhoneNumber = number
    }
  }

  private func applyCardSettings(from config: LaunchConfig) {
    if let showPayButton = config.showPayButton {
      showCardPayButton = showPayButton
    }
    if let action = config.paymentButtonAction.flatMap(CheckoutComponents.PaymentButtonAction.init(configValue:)) {
      paymentButtonAction = action
    }
    if let position = ConfigName.match(config.displayCardHolderName, as: CheckoutComponents.DisplayCardHolderName.self) {
      displayCardHolderName = position
    }
    if let maxLength = config.cardholderNameMaxLength, (1...255).contains(maxLength) {
      cardHolderNameMaxLength = UInt(maxLength)
    }
    if let hide = config.hideSecurityCode {
      hideSecurityCode = hide
    }
    if let name = config.prefilledCardholderName {
      prefilledCardholderName = name
    }
    if let schemes = config.acceptedCardSchemes {
      cardAcceptedCardSchemes = CardScheme.set(fromConfig: schemes)
    }
    if let types = config.acceptedCardTypes {
      cardAcceptedCardTypes = CheckoutComponents.CardType.set(fromConfig: types)
    }
  }

  private func applyStandaloneComponentSettings(from config: LaunchConfig) {
    if let operation = ConfigName.match(config.customButtonOperation, as: CustomButtonOperation.self) {
      customButtonOperation = operation
    }
    if let lengths = config.cvvLengths {
      let selection = Set(lengths.compactMap { UInt(exactly: $0).flatMap(CVVLength.init(rawValue:)) })
      // iOS has no "unset" CVV length, so an empty or all-unknown list leaves the selection alone.
      if !selection.isEmpty {
        selectedCVVLengths = selection
      }
    }
  }

  private func applyWalletSettings(from config: LaunchConfig) {
    if let applePay = config.applePaySettings {
      applyApplePaySettings(applePay)
    }
    if let show = config.showUpdateAmountSection {
      isShowUpdateView = show
    }
    if let show = config.showApmPayButton {
      showAPMPayButton = show
    }
  }

  private func applyApplePaySettings(_ settings: LaunchConfig.ApplePaySettings) {
    if let show = settings.showApplePayButton {
      showApplePayButton = show
    }
    if let schemes = settings.acceptedCardSchemes {
      applePayAcceptedCardSchemes = CardScheme.set(fromConfig: schemes)
    }
    if let types = settings.acceptedCardTypes {
      applePayAcceptedCardTypes = CheckoutComponents.CardType.set(fromConfig: types)
    }
    if let style = ConfigName.match(settings.buttonStyle, as: CheckoutComponents.ApplePayButtonStyle.self) {
      applePayButtonStyle = style
    }
    if let type = ConfigName.match(settings.buttonType, as: CheckoutComponents.ApplePayButtonType.self) {
      applePayButtonType = type
    }
    if let totalType = ConfigName.match(settings.totalType, as: ApplePayType.self) {
      selectedApplePayType = totalType
    }
  }

  private func applyKlarnaSettings(from config: LaunchConfig) {
    #if canImport(CheckoutKlarnaSDK)
    if let theme = ConfigName.match(config.klarnaTheme, as: CheckoutKlarna.Theme.self) {
      klarnaTheme = theme
    }
    if let returnUrl = config.klarnaReturnUrl {
      klarnaReturnURLString = returnUrl
    }
    #endif
  }

  private func applyRememberMeSettings(from config: LaunchConfig) {
    if let show = config.showRememberMePayButton {
      showRememberMePayButton = show
    }
    if let email = config.rememberMeEmail, !email.isEmpty {
      userEmail = email
    }
    if let countryCode = config.rememberMePhoneNumber?.countryCode, !countryCode.isEmpty {
      userCountryCode = Self.dialingCode(from: countryCode)
    }
    if let number = config.rememberMePhoneNumber?.number, !number.isEmpty {
      userPhoneNumber = number
    }
    if let schemes = config.rememberMeCardSchemes {
      rememberMeAcceptedCardSchemes = CardScheme.set(fromConfig: schemes)
    }
    if let types = config.rememberMeCardTypes {
      rememberMeAcceptedCardTypes = CheckoutComponents.CardType.set(fromConfig: types)
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
    if let override = ConfigName.match(config.storedCardConsentOverride, as: StoredCardConsentOverride.self) {
      storedCardConsentOverride = override
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
      storedCardAcceptedCardSchemes = CardScheme.set(fromConfig: schemes)
    }
    if let types = config.storedCardAcceptedTypes {
      storedCardAcceptedCardTypes = CheckoutComponents.CardType.set(fromConfig: types)
    }
    if let showPayButton = config.storedCardShowPayButton {
      showStoredCardPayButton = showPayButton
    }
    if let action = config.storedCardPaymentButtonAction.flatMap(CheckoutComponents.PaymentButtonAction.init(configValue:)) {
      storedCardPaymentButtonAction = action
    }
  }

  private func applyAppearanceSettings(from config: LaunchConfig) {
    if let appearanceString = config.appearance,
       let appearance = AppearancePreset(configValue: appearanceString) {
      isDefaultAppearance = appearance == .default
    }
    if let address = ConfigName.match(config.addressConfig, as: AddressComponentConfiguration.self),
       address.addressConfiguration != nil || selectedComponentType != .address {
      selectedAddressConfiguration = address
    }
    if let callbacks = config.componentCallbacks {
      handleSubmitManually = callbacks.contains { $0.caseInsensitiveCompare("HandleSubmit") == .orderedSame }
      rejectPaymentOnAuthorized = callbacks.contains {
        $0.caseInsensitiveCompare("OnAuthorizedReject") == .orderedSame
      }
    }
  }

  /// Listed flags are switched on and every other known flag off; an absent key leaves them alone.
  private func applyStagingKeys(from config: LaunchConfig) {
    guard let keys = config.stagingKeys else {
      return
    }
    let enabled = Set(keys.map(ConfigName.normalised))
    func isOn(_ key: String) -> Bool { enabled.contains(ConfigName.normalised(key)) }

    isIgnoreRememberMeEmailFeatureFlagEnabled = isOn("disable_forwarding_emails")
    captureCvvEnabled = isOn("enable_capture_rm_saved_card_cvv")
    hidePrefilledDataEnabled = isOn("enable_hide_rm_prefilled_data")
    rememberMeDiscreetUIEnabled = isOn("enable_remember_me_discreet_ui")
    storedCardsWithRememberMeEnabled = isOn("enable_stored_cards_with_remember_me")
  }

  private static func dialingCode(from value: String) -> String {
    if let country = CheckoutComponents.Country(iso3166Alpha2: value.uppercased()) {
      return country.dialingCode
    }
    return value.hasPrefix("+") ? String(value.dropFirst()) : value
  }
}

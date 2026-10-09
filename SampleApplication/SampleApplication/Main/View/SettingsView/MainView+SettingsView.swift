//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

#if canImport(CheckoutKlarnaSDK)
import CheckoutKlarnaSDK
#endif

import SwiftUI

enum CheckoutComponent: String, CaseIterable {
  case flow = "Flow"
  case address = "Address"
  case cvv = "CVV"
  case card = "Card"
  case storedCard = "Stored Card"
  case applePay = "Apple Pay"
  case tabby = "Tabby"
  case tamara = "Tamara"
  case ideal = "iDEAL"
  case knet = "KNET"
  case stcPay = "STC Pay"
#if canImport(CheckoutKlarnaSDK)
  case klarna = "Klarna"
#endif

  /// Address and CVV are `SessionlessComponent` cases, so the SDK renders them with just the
  /// public key and the sample app skips the payment session call for them.
  var isSessionless: Bool {
    self == .address || self == .cvv
  }

  var accessibilityIdentifier: String {
    switch self {
    case .flow:
      return "flow"
    case .address:
      return "address"
    case .cvv:
      return "cvv"
    case .card:
      return "card"
    case .storedCard:
      return "stored_card"
    case .applePay:
      return "google_apple_pay"
    case .tabby:
      return "tabby"
    case .tamara:
      return "tamara"
    case .ideal:
      return "ideal"
    case .knet:
      return "knet"
    case .stcPay:
      return "stc_pay"
#if canImport(CheckoutKlarnaSDK)
    case .klarna:
      return "klarna"
#endif
    }
  }
}

enum ApplePayType: String, CaseIterable {
  case final
  case pending
}


/// The security code lengths `CardCVVConfiguration` accepts.
enum CVVLength: UInt, CaseIterable {
  case three = 3
  case four = 4

  var accessibilityIdentifier: String {
    "cvv_length_\(rawValue)"
  }
}

extension MainView {
  var settingView: some View {
    ScrollView {
      VStack(alignment: .leading) {
        sdkOptionsView
        environmentView
        #if INTERNAL_SAMPLE_APP
        merchantKeyPresetView
        #endif
        appearanceView
        localeView
        paymentSessionLocaleView
        countryView
        currencyView

        advancedFeaturesView
        paymentSessionConfigurationView
        rememberMeConfigurationsView
        storedCardConfigurationsView
        cvvConfigurationsView
        #if canImport(CheckoutKlarnaSDK)
        klarnaConfigurationsView
        #endif
      }
      .padding(.horizontal)
    }
  }

  var sdkOptionsView: some View {
    HStack {
      Text("Component:")

      Picker("Component:",
             selection: $viewModel.selectedComponentType) {
        ForEach(CheckoutComponent.allCases, id: \.self) {
          Text($0.rawValue)
            .accessibilityIdentifier($0.accessibilityIdentifier)
        }
      }.accessibilityIdentifier(AccessibilityIdentifier.SettingsView.sdkPicker.rawValue)

      if viewModel.selectedComponentType == .flow {
        Text("with")

        Menu(viewModel.selectedPaymentMethodsTitle) {
          Toggle("Card", isOn: $viewModel.isCardSelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.cardPaymentMethodOption.rawValue)
          Toggle("Apple Pay", isOn: $viewModel.isApplePaySelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.applePayPaymentMethodOption.rawValue)
          Toggle("Tabby", isOn: $viewModel.isTabbySelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.tabbyPaymentMethodOption.rawValue)
          Toggle("Tamara", isOn: $viewModel.isTamaraSelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.tamaraPaymentMethodOption.rawValue)
          Toggle("iDEAL", isOn: $viewModel.isIdealSelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.idealPaymentMethodOption.rawValue)
          Toggle("KNET", isOn: $viewModel.isKnetSelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.knetPaymentMethodOption.rawValue)
          Toggle("STC Pay", isOn: $viewModel.isSTCPaySelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.stcPayPaymentMethodOption.rawValue)
          Toggle("Klarna", isOn: $viewModel.isKlarnaSelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.klarnaPaymentMethodOption.rawValue)
        }.accessibilityIdentifier(AccessibilityIdentifier.SettingsView.paymentMethodPicker.rawValue)
      }
    }
  }

  var cardOptionsView: some View {
    VStack(alignment: .leading) {
      // Show card pay button as a toggle/switch
      Toggle("Show card pay button", isOn: $viewModel.showCardPayButton)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showPayButtonPicker.rawValue)

      // Payment button action picker - only visible when showCardPayButton is true
      if viewModel.showCardPayButton {
        HStack {
          Text("Payment button action:")

          Picker("Payment button action",
                 selection: $viewModel.paymentButtonAction) {
            Text("Payment")
              .tag(CheckoutComponents.PaymentButtonAction.payment)
              .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.payment.rawValue)

            Text("Tokenize")
              .tag(CheckoutComponents.PaymentButtonAction.tokenization)
              .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.tokenize.rawValue)
          }.accessibilityIdentifier(AccessibilityIdentifier.SettingsView.payButtonPicker.rawValue)
        }
      }
    }
  }

  var submitPaymentMethodView: some View {
    HStack {
      Text("Submit payment managed by:")

      Picker("Submit payment managed by:",
             selection: $viewModel.handleSubmitManually) {
        Text("SDK")
          .tag(false)

        Text("handleSubmit callback")
          .tag(true)
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.submitPaymentPicker.rawValue)
    }
  }

  var showApplePayButtonView: some View {
    Toggle("Show Apple Pay button", isOn: $viewModel.showApplePayButton)
  }

  var showAPMPayButtonView: some View {
    Toggle("Show APM pay button", isOn: $viewModel.showAPMPayButton)
  }

  var applePayButtonStyleView: some View {
    HStack {
      Text("Apple Pay button style:")

      Picker("Apple Pay button style", selection: $viewModel.applePayButtonStyle) {
        ForEach(CheckoutComponents.ApplePayButtonStyle.allCases, id: \.self) {
          Text($0.displayName)
            .tag($0)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.applePayButtonStylePicker.rawValue)
    }
  }

  var applePayButtonTypeView: some View {
    HStack {
      Text("Apple Pay button type:")

      Picker("Apple Pay button type", selection: $viewModel.applePayButtonType) {
        ForEach(CheckoutComponents.ApplePayButtonType.allCases, id: \.self) {
          Text($0.displayName)
            .tag($0)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.applePayButtonTypePicker.rawValue)
    }
  }

  var localeView: some View {
    HStack {
      Text("Locale:")

      Picker("Locale", selection: $viewModel.selectedLocale) {
        ForEach(LocaleOption.allOptions, id: \.self) { option in
          Text(option.displayName)
            .tag(option)
            .accessibilityIdentifier(option.accessibilityIdentifier)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.localePicker.rawValue)
    }
  }
  
  var paymentSessionLocaleView: some View {
    HStack {
      Text("PS Locale:")

      Picker("Locale", selection: $viewModel.paymentSessionSelectedLocale) {
        ForEach(LocaleOption.paymentSessionOptions, id: \.self) { option in
          Text(option.displayName)
            .tag(option)
            .accessibilityIdentifier(option.accessibilityIdentifier)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.paymentSessionLocalePicker.rawValue)
    }
  }

  var countryView: some View {
    HStack {
      Text("Country:")

      Picker("Country", selection: $viewModel.selectedCountry) {
        ForEach(CountryOption.allCases, id: \.self) { option in
          Text(option.displayName)
            .tag(option)
            .accessibilityIdentifier(option.accessibilityIdentifier)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.countryPicker.rawValue)
    }
  }

  var currencyView: some View {
    HStack {
      Text("Currency:")

      Picker("Currency", selection: $viewModel.selectedCurrency) {
        ForEach(CurrencyOption.allCases, id: \.self) { option in
          Text(option.displayName)
            .tag(option)
            .accessibilityIdentifier(option.accessibilityIdentifier)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.currencyPicker.rawValue)
    }
  }

  var environmentView: some View {
    HStack {
      Text("Environment:")

      Picker("Environment", selection: $viewModel.selectedEnvironment) {
        Text("Sandbox")
          .tag(CheckoutComponents.Environment.sandbox)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.sandboxEnvironmentOption.rawValue)

        Text("Production")
          .tag(CheckoutComponents.Environment.production)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.productionEnvironmentOption.rawValue)
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.environmentPicker.rawValue)
      #if INTERNAL_SAMPLE_APP
      .onChange(of: viewModel.selectedEnvironment) { _ in
        viewModel.onEnvironmentChanged()
      }
      #endif
    }
  }

  var appearanceView: some View {
    HStack {
      Text("Appearance:")

      Picker("Appearance", selection: $viewModel.isDefaultAppearance) {
        Text("Default")
          .tag(true)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.defaultAppearanceOption.rawValue)

        Text("Dark theme")
          .tag(false)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.darkThemeOption.rawValue)
      }.accessibilityIdentifier(AccessibilityIdentifier.SettingsView.appearancePicker.rawValue)
    }
  }

  var advancedFeaturesView: some View {
    expandableSection(title: "Advanced Features",
                      isExpanded: $viewModel.isAdvancedFeaturesExpanded,
                      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.advancedFeaturesExpandable.rawValue) {
      VStack(alignment: .leading, spacing: 12) {
        cardOptionsView
        showApplePayButtonView
        showAPMPayButtonView
        applePayButtonStyleView
        applePayButtonTypeView
        applePayTypeView
        cardHolderNamePositionView
        hideSecurityCodeView
        cardHolderNameMaxLengthView
        prefilledCardholderNameView

        cardAcceptedCardSchemesView
        applePayAcceptedCardSchemesView
        rememberMeAcceptedCardSchemesView

        cardAcceptedCardTypesView
        applePayAcceptedCardTypesView
        rememberMeAcceptedCardTypesView

        VStack(alignment: .leading, spacing: 12) {
          submitPaymentMethodView
          if viewModel.handleSubmitManually {
            updateAmountSettingView
          } else {
            customButtonOperationView
          }
        }

        addressConfigurationView
      }
      .padding(.leading, 16)
      .transition(.opacity.combined(with: .slide))
    }
  }
  
  var paymentSessionConfigurationView: some View {
    expandableSection(title: "Payment session Configurations",
                      isExpanded: $viewModel.isPaymentSessionConfigurationExpanded,
                      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.paymentSessionConfigurationsExpandable.rawValue) {
      VStack(alignment: .leading, spacing: 12) {
        paymentSessionUsername
        paymentSessionUserEmail
        paymentSessionCountryCodeView
        paymentSessionPhoneNumberView
      }
      .padding(.leading, 16)
      .transition(.opacity.combined(with: .slide))
    }
  }

  var cvvConfigurationsView: some View {
    expandableSection(title: "CVV Configurations",
                      isExpanded: $viewModel.isCVVExpanded,
                      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.cvvConfigurationsExpandable.rawValue) {
      VStack(alignment: .leading, spacing: 12) {
        cvvLengthView
      }
      .padding(.leading, 16)
      .transition(.opacity.combined(with: .slide))
    }
  }

  /// Multi-select so both lengths can be sent together, which is what `[3, 4]` means to the
  /// component: accept a code of either length.
  var cvvLengthView: some View {
    DisclosureGroup {
      ForEach(CVVLength.allCases, id: \.self) { length in
        Button(action: {
          if viewModel.selectedCVVLengths.contains(length) {
            viewModel.selectedCVVLengths.remove(length)
          } else {
            viewModel.selectedCVVLengths.insert(length)
          }
        }) {
          HStack {
            Text(String(length.rawValue))
            Spacer()
            if viewModel.selectedCVVLengths.contains(length) {
              Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(length.accessibilityIdentifier)
      }
    } label: {
      Text("CVV length:")
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
    }
    .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.cvvLengthPicker.rawValue)
  }

  var paymentSessionUsername: some View {
    HStack {
      Text("Customer name: ")
      TextField("Customer name", text: $viewModel.paymentSessionUsername)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.paymentSessionUsernameTextField.rawValue)
        .keyboardType(.namePhonePad)
    }
  }

  var paymentSessionUserEmail: some View {
    HStack {
      Text("Customer email: ")
      TextField("Customer email", text: $viewModel.paymentSessionUserEmail)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.paymentSessionUserEmailTextField.rawValue)
        .keyboardType(.emailAddress)
    }
  }
  
  var paymentSessionCountryCodeView: some View {
    HStack {
      Text("Country Code: ")
      TextField("Country Code", text: $viewModel.paymentSessionCountryCode)
        .accessibilityIdentifier(
          AccessibilityIdentifier.SettingsView.customerPhoneCountryCodePicker.rawValue
        )
        .keyboardType(.phonePad)
    }
  }

  var paymentSessionPhoneNumberView: some View {
    HStack {
      Text("Phone Number: ")
      TextField("Phone Number", text: $viewModel.paymentSessionPhoneNumber)
        .accessibilityIdentifier(
          AccessibilityIdentifier.SettingsView.customerPhoneNumberInput.rawValue
        )
        .keyboardType(.phonePad)
    }
  }

  var customButtonOperationView: some View {
    HStack {
      Text("Custom button type:")

      Picker("Custom button type",
             selection: $viewModel.customButtonOperation) {
        ForEach(CustomButtonOperation.allCases, id: \.self) { operation in
          Text(operation.rawValue)
            .tag(operation)
        }
      }
    }
  }

  var addressConfigurationView: some View {
    HStack {
      Text("Address Config:")

      Picker("Address Config", selection: $viewModel.selectedAddressConfiguration) {
        ForEach(AddressComponentConfiguration.allCases, id: \.self) {
          Text($0.rawValue)
            .accessibilityIdentifier($0.accessibilityIdentifier)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.addressPicker.rawValue)
    }
  }
  
  var applePayTypeView: some View {
    HStack {
      Text("Apple Pay type:")

      Picker("Apple Pay type", selection: $viewModel.selectedApplePayType) {
        ForEach(ApplePayType.allCases, id: \.self) {
          Text($0.rawValue.capitalized)
            .accessibilityIdentifier($0.rawValue)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.applePayTypePicker.rawValue)
    }
  }
  
  var cardHolderNamePositionView: some View {
    HStack {
      Text("Display Cardholder Name:")

      Picker("Display Cardholder Name", selection: $viewModel.displayCardHolderName) {
        ForEach(CheckoutComponents.DisplayCardHolderName.allCases, id: \.self) {
          Text($0.rawValue.capitalized)
            .accessibilityIdentifier($0.rawValue)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.displayCardholderNamePicker.rawValue)
    }
  }
  
  var hideSecurityCodeView: some View {
    HStack {
      Text("Hide Security Code (CVV)")
      Spacer()
      Toggle("Hide Security Code (CVV)", isOn: $viewModel.hideSecurityCode)
        .labelsHidden()
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.hideSecurityCodeToggle.rawValue)
    }
  }
  
  var cardHolderNameMaxLengthView: some View {
    HStack {
      Text("Cardholder Name max length: ")
      
      TextField("Cardholder Name max length",
                value: $viewModel.cardHolderNameMaxLength,
                format: .number)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.cardholderNameMaxLengthInput.rawValue)
        .keyboardType(.numberPad)
    }
  }

  var prefilledCardholderNameView: some View {
    HStack {
      Text("Pre-populated cardholder name: ")

      TextField("Pre-populated cardholder name",
                text: $viewModel.prefilledCardholderName)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.prefilledCardholderNameInput.rawValue)
        .autocorrectionDisabled()
    }
  }
  
  var updateAmountSettingView: some View {
    Toggle("Show update amount view", isOn: $viewModel.isShowUpdateView)
  }

}

// MARK: - Helping Structures

extension MainView {
  @ViewBuilder
  func expandableSection<Content: View>(title: String,
                                        isExpanded: Binding<Bool>,
                                        accessibilityIdentifier: String? = nil,
                                        @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading) {
      Button(action: {
        withAnimation(.easeInOut(duration: 0.3)) {
          isExpanded.wrappedValue.toggle()
        }
      }) {
        HStack {
          Text(title)
          
          Spacer()
          
          Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .accessibilityIdentifier(accessibilityIdentifier ?? "")
      
      if isExpanded.wrappedValue {
        VStack(alignment: .leading, spacing: 12) {
          content()
        }
        .padding(.leading, 16)
        .transition(.opacity.combined(with: .slide))
      }
    }
  }
}

// MARK: - Apple Pay display helpers

extension CheckoutComponents.ApplePayButtonStyle {
  var displayName: String {
    switch self {
    case .white: return "White"
    case .whiteOutline: return "White Outline"
    case .black: return "Black"
    }
  }
}

extension CheckoutComponents.ApplePayButtonType {
  var displayName: String {
    switch self {
    case .plain: return "Plain"
    case .buy: return "Buy"
    case .setUp: return "Set Up"
    case .inStore: return "In Store"
    case .donate: return "Donate"
    case .checkout: return "Checkout"
    case .book: return "Book"
    case .subscribe: return "Subscribe"
    case .reload: return "Reload"
    case .addMoney: return "Add Money"
    case .topUp: return "Top Up"
    case .order: return "Order"
    case .rent: return "Rent"
    case .support: return "Support"
    case .contribute: return "Contribute"
    case .tip: return "Tip"
    }
  }
}

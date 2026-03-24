//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

enum CheckoutComponent: String, CaseIterable {
  case flow = "Flow"
  case card = "Card"
  case applePay = "Apple Pay"

  var accessibilityIdentifier: String {
    switch self {
    case .flow:
      return "flow"
    case .card:
      return "card"
    case .applePay:
      return "google_apple_pay"
    }
  }
}

enum ApplePayType: String, CaseIterable {
  case final
  case pending
}

extension MainView {
  var settingView: some View {
    ScrollView {
      VStack(alignment: .leading) {
        sdkOptionsView
        environmentView
        appearanceView
        localeView
        paymentSessionLocaleView

        advancedFeaturesView
        rememberMeConfigurationsView
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
      }.accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showPayButtonPicker.rawValue)
    }
  }

  var showApplePayButtonView: some View {
    Toggle("Show Apple Pay button", isOn: $viewModel.showApplePayButton)
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
        applePayTypeView
        cardHolderNamePositionView
        hideSecurityCodeView

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
  
  var rememberMeConfigurationsView: some View {
    expandableSection(title: "RememberMe Configurations",
                      isExpanded: $viewModel.isRememberMeExpanded,
                      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.rememberMeConfigurationsExpandable.rawValue) {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Enable Remember Me", isOn: $viewModel.showRememberMe)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showRememberMeToggle.rawValue)

        if viewModel.showRememberMe {
          Toggle("Show Remember Me pay button", isOn: $viewModel.showRememberMePayButton)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showRememberMePayButtonToggle.rawValue)

          userEmailView
          countryCodeView
          userPhoneNumberView
        }
      }
      .padding(.leading, 16)
      .transition(.opacity.combined(with: .slide))
    }
  }
  
  var userEmailView: some View {
    HStack {
      Text("Email: ")
      TextField("Email", text: $viewModel.userEmail)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.userEmailTextField.rawValue)
        .keyboardType(.emailAddress)
    }
  }
  
  var countryCodeView: some View {
    HStack {
      Text("Country Code: ")
      TextField("Country Code", text: $viewModel.userCountryCode)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.userCountryCodeTextField.rawValue)
        .keyboardType(.phonePad)
    }
  }
  
  var userPhoneNumberView: some View {
    HStack {
      Text("Phone Number: ")
      TextField("Phone Number", text: $viewModel.userPhoneNumber)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.userPhoneNumberTextField.rawValue)
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
    Toggle("Hide Security Code (CVV)", isOn: $viewModel.hideSecurityCode)
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.hideSecurityCodeToggle.rawValue)
  }
  
  private var allCardSchemes: [CardScheme] {
    [
      .americanExpress, .cartesBancaires,
      .chinaUnionPay, .dinersClub,
      .discover, .jcb,
      .mada, .mastercard,
      .visa, .maestro
    ]
  }

  func acceptedCardSchemesPicker(title: String,
                                 selectedSchemes: Binding<Set<CardScheme>>,
                                 accessibilityIdentifierSuffix: String) -> some View {
    DisclosureGroup {
      ForEach(allCardSchemes, id: \.self) { scheme in
        Button(action: {
          if selectedSchemes.wrappedValue.contains(scheme) {
            selectedSchemes.wrappedValue.remove(scheme)
          } else {
            selectedSchemes.wrappedValue.insert(scheme)
          }
        }) {
          HStack {
            Text(scheme.rawValue.capitalized)
            Spacer()
            if selectedSchemes.wrappedValue.contains(scheme) {
              Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    } label: {
      Text(title)
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
    }
    .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.acceptedCardSchemesPicker.rawValue + accessibilityIdentifierSuffix)
  }

  var cardAcceptedCardSchemesView: some View {
    acceptedCardSchemesPicker(title: "Card accepted card schemes:",
                              selectedSchemes: $viewModel.cardAcceptedCardSchemes,
                              accessibilityIdentifierSuffix: "_card")
  }

  var applePayAcceptedCardSchemesView: some View {
    acceptedCardSchemesPicker(title: "Apple Pay accepted card schemes:",
                              selectedSchemes: $viewModel.applePayAcceptedCardSchemes,
                              accessibilityIdentifierSuffix: "_apple_pay")
  }
  
  var rememberMeAcceptedCardSchemesView: some View {
    acceptedCardSchemesPicker(title: "Remember Me accepted card schemes:",
                              selectedSchemes: $viewModel.rememberMeAcceptedCardSchemes,
                              accessibilityIdentifierSuffix: "_remember_me")
  }
  
  private var allCardTypes: [CheckoutComponents.CardType] {
    [
      .credit, .debit,
      .prepaid, .charge,
      .deferredDebit
    ]
  }
  
  func acceptedCardTypesPicker(title: String,
                               selectedTypes: Binding<Set<CheckoutComponents.CardType>>,
                               cardTypes: [CheckoutComponents.CardType],
                               accessibilityIdentifierSuffix: String) -> some View {
    DisclosureGroup {
      ForEach(cardTypes, id: \.self) { type in
        Button(action: {
          if selectedTypes.wrappedValue.contains(type) {
            selectedTypes.wrappedValue.remove(type)
          } else {
            selectedTypes.wrappedValue.insert(type)
          }
        }) {
          HStack {
            Text(type.rawValue.capitalized)
            Spacer()
            if selectedTypes.wrappedValue.contains(type) {
              Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    } label: {
      Text(title)
        .accessibilityIdentifier(title)
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.acceptedCardTypesPicker.rawValue + accessibilityIdentifierSuffix)
  }
  
  var cardAcceptedCardTypesView: some View {
    acceptedCardTypesPicker(title: "Card accepted card types:",
                            selectedTypes: $viewModel.cardAcceptedCardTypes,
                            cardTypes: allCardTypes,
                            accessibilityIdentifierSuffix: "_card")
  }
  
  var applePayAcceptedCardTypesView: some View {
    acceptedCardTypesPicker(title: "Apple Pay accepted card types:",
                            selectedTypes: $viewModel.applePayAcceptedCardTypes,
                            cardTypes: [.credit, .debit],
                            accessibilityIdentifierSuffix: "_apple_pay")
  }

  var rememberMeAcceptedCardTypesView: some View {
    acceptedCardTypesPicker(title: "RememberMe accepted card types:",
                            selectedTypes: $viewModel.rememberMeAcceptedCardTypes,
                            cardTypes: allCardTypes,
                            accessibilityIdentifierSuffix: "_remember_me")
  }

  var updateAmountSettingView: some View {
    Toggle("Show update amount view", isOn: $viewModel.isShowUpdateView)
  }

}

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

#Preview {
  MainView().settingView
}

//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

enum ModuleType: String, CaseIterable {
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

extension MainView {
  var settingView: some View {
    VStack {
      sdkOptionsView
      cardOptionsView
      addressConfigurationView
      localeView
      environmentView
      appearanceView
    }
  }
  
  var sdkOptionsView: some View {
    HStack {
      Text("SDK Module:")
      
      Picker("SDK module",
             selection: $viewModel.selectedModuleType) {
        ForEach(ModuleType.allCases, id: \.self) {
          Text($0.rawValue)
            .accessibilityIdentifier($0.accessibilityIdentifier)
        }
      }
             .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.sdkPicker.rawValue)
      
      if viewModel.selectedModuleType == .flow {
        Text("with")
        
        Menu(viewModel.selectedPaymentMethodsTitle) {
          Toggle("Card", isOn: $viewModel.isCardSelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.cardPaymentMethodOption.rawValue)
          Toggle("Apple Pay", isOn: $viewModel.isApplePaySelected)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.applePayPaymentMethodOption.rawValue)
        }
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.paymentMethodPicker.rawValue)
      }
    }
  }
  
  var cardOptionsView: some View {
    HStack {
      Text("Card options:")
      
      Picker("Payment button action",
             selection: $viewModel.paymentButtonAction) {
        Text("Payment")
          .tag(CheckoutComponents.PaymentButtonAction.payment)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.payment.rawValue)
        
        Text("Tokenize")
          .tag(CheckoutComponents.PaymentButtonAction.tokenization)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.tokenize.rawValue)
      }
             .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.payButtonPicker.rawValue)
      
      Picker("Show pay button",
             selection: $viewModel.showPayButton) {
        Text("True")
          .tag(true)
        
        Text("False")
          .tag(false)
      }
             .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showPayButtonPicker.rawValue)
    }
  }
  
  var localeView: some View {
    HStack {
      Text("Locale:")
      
      Picker("Locale", selection: $viewModel.selectedLocale) {
        Text("Customised")
          .tag("Customised")
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.customLocale.rawValue)
        
        ForEach(viewModel.getLocales(), id: \.self) {
          Text($0)
            .accessibilityIdentifier($0)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.environmentPicker.rawValue)
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
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.appearancePicker.rawValue)
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
  
}

#Preview {
  MainView().settingView
}

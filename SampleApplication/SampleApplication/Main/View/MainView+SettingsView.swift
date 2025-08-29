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

extension MainView {
  var settingView: some View {
    VStack(alignment: .leading) {
      sdkOptionsView
      environmentView
      appearanceView
      localeView

      advancedFeaturesView
    }
    .padding(.horizontal)
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
      }.accessibilityIdentifier(AccessibilityIdentifier.SettingsView.appearancePicker.rawValue)
    }
  }

  var advancedFeaturesView: some View {
    VStack(alignment: .leading) {
      Button(action: {
        withAnimation(.easeInOut(duration: 0.3)) {
          viewModel.isAdvancedFeaturesExpanded.toggle()
        }
      }) {
        HStack {
          Text("Advanced Features")

          Spacer()

          Image(systemName: viewModel.isAdvancedFeaturesExpanded ? "chevron.up" : "chevron.down")
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
      }
      .buttonStyle(PlainButtonStyle())

      if viewModel.isAdvancedFeaturesExpanded {
        VStack(alignment: .leading, spacing: 12) {
          cardOptionsView
          showApplePayButtonView

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

  var updateAmountSettingView: some View {
    Toggle("Show update amount view", isOn: $viewModel.isShowUpdateView)
  }

}

#Preview {
  MainView().settingView
}

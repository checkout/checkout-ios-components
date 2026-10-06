//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

extension MainView {
  var rememberMeConfigurationsView: some View {
    expandableSection(title: "RememberMe Configurations",
                      isExpanded: $viewModel.isRememberMeExpanded,
                      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.rememberMeConfigurationsExpandable.rawValue) {
      VStack(alignment: .leading, spacing: 12) {
        // The RememberMeConfiguration passed into the card component. Off means we
        // pass nil. That does not hide Remember Me, the payment session decides
        // that. It only means no merchant overrides.
        Toggle("Pass RM session configuration", isOn: $viewModel.passRememberMeConfiguration)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showRememberMeToggle.rawValue)

        if viewModel.passRememberMeConfiguration {
          Toggle("Show Remember Me pay button", isOn: $viewModel.showRememberMePayButton)
            .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showRememberMePayButtonToggle.rawValue)
          
          rememberMeSDKSetupView
        }

        // Session and staging feature flags. They change how Remember Me behaves
        // even when no configuration is passed, so they are not gated on one.
        Toggle(
          "Feature Flag: Ignore Payment Session Email",
          isOn: $viewModel.isIgnoreRememberMeEmailFeatureFlagEnabled
        )
        .accessibilityIdentifier(
          AccessibilityIdentifier.SettingsView.ignoreRememberMeEmailFeatureFlagToggle.rawValue
        )
        
        Toggle(
          "Feature Flag: Capture CVV",
          isOn: $viewModel.captureCvvEnabled
        )
        .accessibilityIdentifier(
          AccessibilityIdentifier.SettingsView.captureCvvFeatureFlagToggle.rawValue
        )
        
        Toggle(
          "Feature Flag: Hide Prefilled Data",
          isOn: $viewModel.hidePrefilledDataEnabled
        )
        .accessibilityIdentifier(
          AccessibilityIdentifier.SettingsView.hidePrefilledDataFeatureFlagToggle.rawValue
        )
        
        Toggle(
          "Feature Flag: RM Discreet UI",
          isOn: $viewModel.rememberMeDiscreetUIEnabled
        )
        .accessibilityIdentifier(
          AccessibilityIdentifier.SettingsView.rememberMeDiscreetUIFeatureFlagToggle.rawValue
        )
      }
      .padding(.leading, 16)
      .transition(.opacity.combined(with: .slide))
    }
  }
  
  var rememberMeSDKSetupView: some View {
    expandableSection(
      title: "SDK Setup",
      isExpanded: $viewModel.isRememberMeSDKSetupExpanded,
      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.rememberMeSDKSetupExpandable.rawValue
    ) {
      VStack(alignment: .leading, spacing: 12) {
        userEmailView
        countryCodeView
        userPhoneNumberView
      }
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
}

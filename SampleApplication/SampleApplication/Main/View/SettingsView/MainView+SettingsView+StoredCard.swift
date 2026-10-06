//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

enum StorePaymentDetailsOption: String, CaseIterable {
  case enabled
  case disabled
  case undefined
  case collectConsent = "collect_consent"

  var displayName: String {
    switch self {
    case .enabled: return "Enabled"
    case .disabled: return "Disabled"
    case .undefined: return "Undefined"
    case .collectConsent: return "Collect consent"
    }
  }

  /// `undefined` omits `store_payment_details` from the payment session request.
  var requestValue: String? {
    self == .undefined ? nil : rawValue
  }
}

enum StoredCardConsentOverride: String, CaseIterable {
  case serverDefault
  case explicit
  case implicit

  var displayName: String {
    switch self {
    case .serverDefault: return "Server default"
    case .explicit: return "Force explicit"
    case .implicit: return "Force implicit"
    }
  }

  var flagValue: String? {
    self == .serverDefault ? nil : rawValue
  }
}

enum StoredCardSource: String, CaseIterable {
  /// Omits `stored_card` from the request.
  case none

  /// Sends `instrument_ids` with the exact instruments to expose, optionally with
  /// `default_instrument_id` to pick which of them is pre-selected.
  case instrumentIds = "instrument_ids"

  /// Sends `customer_id` and lets the backend resolve that customer's instruments.
  case customerId = "customer_id"

  var displayName: String {
    switch self {
    case .none: return "None"
    case .instrumentIds: return "Instrument ids"
    case .customerId: return "Customer id"
    }
  }
}

extension CheckoutComponents.StoredCardDisplayMode {
  var displayName: String {
    switch self {
    case .defaultCard: return "Default card"
    case .all: return "All"
    }
  }
}

extension MainView {
  
  var storedCardConfigurationsView: some View {
    expandableSection(title: "Stored Card Configurations",
                      isExpanded: $viewModel.isStoredCardExpanded,
                      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.storedCardConfigurationsExpandable.rawValue) {
      VStack(alignment: .leading, spacing: 12) {
        storedCardSourceView

        switch viewModel.storedCardSource {
        case .none:
          EmptyView()

        case .instrumentIds:
          instrumentIds
          defaultInstrumentId

        case .customerId:
          customerId
        }

        storedCardDisplayModeView
        storePaymentDetailsView
        showStoredCardPayButtonView
        if viewModel.showStoredCardPayButton {
          storedCardPaymentButtonActionView
        }
        storedCardCaptureCVVView
        storedCardAcceptedCardSchemesView
        storedCardAcceptedCardTypesView
        storedCardWithRMFeatureFlag
        storedCardConsentOverrideView
      }
    }
    .transition(.opacity.combined(with: .slide))
  }
  
  var showStoredCardPayButtonView: some View {
    Toggle("Show Stored Card pay button", isOn: $viewModel.showStoredCardPayButton)
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.showStoredCardPayButtonToggle.rawValue)
  }

  /// Only affects the Card component embedded in the "Use a new card" row.
  var storedCardPaymentButtonActionView: some View {
    HStack {
      Text("Payment button action:")

      Picker("Payment button action",
             selection: $viewModel.storedCardPaymentButtonAction) {
        Text("Payment")
          .tag(CheckoutComponents.PaymentButtonAction.payment)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storedCardPaymentAction.rawValue)

        Text("Tokenize")
          .tag(CheckoutComponents.PaymentButtonAction.tokenization)
          .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storedCardTokenizeAction.rawValue)
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storedCardPaymentButtonActionPicker.rawValue)
    }
  }

  var storedCardCaptureCVVView: some View {
    Toggle("Capture CVV", isOn: $viewModel.storedCardCaptureCVV)
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storedCardCaptureCVVToggle.rawValue)
  }

  var storedCardDisplayModeView: some View {
    HStack {
      Text("Display mode:")

      Picker("Display mode", selection: $viewModel.storedCardDisplayMode) {
        ForEach(CheckoutComponents.StoredCardDisplayMode.allCases, id: \.self) {
          Text($0.displayName)
            .tag($0)
            .accessibilityIdentifier($0.rawValue)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storedCardDisplayModePicker.rawValue)
    }
  }

  var storePaymentDetailsView: some View {
    HStack {
      Text("Store payment details:")

      Picker("Store payment details", selection: $viewModel.storePaymentDetails) {
        ForEach(StorePaymentDetailsOption.allCases, id: \.self) {
          Text($0.displayName)
            .tag($0)
            .accessibilityIdentifier($0.rawValue)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storePaymentDetailsPicker.rawValue)
    }
  }

  var storedCardSourceView: some View {
    HStack {
      Text("Source:")

      Picker("Source", selection: $viewModel.storedCardSource) {
        ForEach(StoredCardSource.allCases, id: \.self) {
          Text($0.displayName)
            .tag($0)
            .accessibilityIdentifier($0.rawValue)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storedCardSourcePicker.rawValue)
    }
  }

  var customerId: some View {
    HStack {
      Text("Customer id: ")
      TextField("Customer id", text: $viewModel.customerId)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.customerIdTextField.rawValue)
    }
  }

  var instrumentIds: some View {
    HStack {
      Text("Instrument ids: ")
      TextField("Comma-separated", text: $viewModel.instrumentIds)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.instrumentIdsTextField.rawValue)
    }
  }

  /// Names one of the listed instruments, so it is meaningless without the list above.
  var defaultInstrumentId: some View {
    HStack {
      Text("Default instrument id: ")
      TextField("Optional", text: $viewModel.defaultInstrumentId)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.defaultInstrumentIdTextField.rawValue)
    }
  }
  
  var storedCardWithRMFeatureFlag: some View {
    Toggle(
      "Feature Flag: Stored Cards With RM",
      isOn: $viewModel.storedCardsWithRememberMeEnabled
    )
    .accessibilityIdentifier(
      AccessibilityIdentifier.SettingsView.storedCardsWithRememberMeFeatureFlagToggle.rawValue
    )
  }
  
  var storedCardConsentOverrideView: some View {
    HStack {
      Text("Consent mode:")

      Picker("Consent mode", selection: $viewModel.storedCardConsentOverride) {
        ForEach(StoredCardConsentOverride.allCases, id: \.self) {
          Text($0.displayName)
            .tag($0)
            .accessibilityIdentifier($0.rawValue)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.storedCardConsentOverridePicker.rawValue)
    }
  }
}

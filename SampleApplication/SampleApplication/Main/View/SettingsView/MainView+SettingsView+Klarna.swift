//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

#if canImport(CheckoutKlarnaSDK)
import CheckoutKlarnaSDK
#endif

import SwiftUI

#if canImport(CheckoutKlarnaSDK)
extension MainView {
  var klarnaConfigurationsView: some View {
    expandableSection(title: "Klarna Configurations",
                      isExpanded: $viewModel.isKlarnaConfigurationExpanded,
                      accessibilityIdentifier: AccessibilityIdentifier.SettingsView.klarnaConfigurationsExpandable.rawValue) {
      VStack(alignment: .leading, spacing: 12) {
        klarnaThemeView
        klarnaReturnURLView
      }
      .padding(.leading, 16)
      .transition(.opacity.combined(with: .slide))
    }
  }

  var klarnaThemeView: some View {
    HStack {
      Text("Theme:")

      Picker("Theme", selection: $viewModel.klarnaTheme) {
        ForEach(CheckoutKlarna.Theme.allCases, id: \.self) {
          Text($0.displayName)
            .tag($0)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.klarnaThemePicker.rawValue)
    }
  }

  var klarnaReturnURLView: some View {
    HStack {
      Text("Return URL: ")
      TextField("Return URL", text: $viewModel.klarnaReturnURLString)
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.klarnaReturnURLTextField.rawValue)
        .keyboardType(.URL)
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
  }
}

extension CheckoutKlarna.Theme {
  var displayName: String {
    switch self {
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }
}
#endif

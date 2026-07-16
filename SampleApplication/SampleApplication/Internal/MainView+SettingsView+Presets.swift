//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

#if INTERNAL_SAMPLE_APP
extension MainView {
  @ViewBuilder
  var merchantKeyPresetView: some View {
    if !viewModel.availableMerchantKeys.isEmpty {
      HStack {
        Text("Merchant Keys Preset:")

        Picker("Merchant", selection: $viewModel.selectedMerchantKey) {
          ForEach(viewModel.availableMerchantKeys) { merchantKey in
            Text(merchantKey.name.capitalized)
              .tag(Optional(merchantKey))
              .accessibilityIdentifier("merchant_key_option_\(merchantKey.name.lowercased())")
          }
        }
        .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.merchantKeyPresetPicker.rawValue)
      }
    }
  }
}
#endif

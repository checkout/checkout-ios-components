//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import Foundation

#if INTERNAL_SAMPLE_APP
extension MainViewModel {

  func loadMerchantKeyPresets() async {
    merchantKeysPreset = await merchantKeyPresetProvider.load()
    selectedMerchantKey = availableMerchantKeys.first
  }

  var selectedEnvironmentKey: String {
    selectedEnvironment == .sandbox ? "sandbox" : "production"
  }

  var availableMerchantKeys: [MerchantKeyPreset] {
    merchantKeysPreset[selectedEnvironmentKey] ?? []
  }

  func onEnvironmentChanged() {
    if let selectedMerchantKey, availableMerchantKeys.contains(selectedMerchantKey) {
      return
    }
    selectedMerchantKey = availableMerchantKeys.first
  }

  // MARK: - Keys

  var resolvedPublicKey: String {
    if let publicKey = selectedMerchantKey?.publicKey {
      return publicKey
    }
    return selectedEnvironment == .sandbox ? EnvironmentVars.sandboxPublicKey : EnvironmentVars.productionPublicKey
  }

  var resolvedSecretKey: String {
    if let secretKey = selectedMerchantKey?.secretKey {
      return secretKey
    }
    return selectedEnvironment == .sandbox ? EnvironmentVars.sandboxSecretKey : EnvironmentVars.productionSecretKey
  }

  var resolvedProcessingChannelID: String? {
    if let processingChannelId = selectedMerchantKey?.processingChannelId {
      return processingChannelId
    }
    return selectedEnvironment == .sandbox ? EnvironmentVars.sandboxProcessingChannelID : nil
  }
}
#endif

//  Copyright © 2024 Checkout.com. All rights reserved.

import Foundation

protocol MerchantKeyPresetProviding: Sendable {
  func load() async -> MerchantKeyPresets
}

actor MerchantKeyPresetProvider: MerchantKeyPresetProviding {
  private var cached: MerchantKeyPresets?

  func load() async -> MerchantKeyPresets {
    if let cached {
      return cached
    }
    let presets = Self.decode()
    cached = presets
    return presets
  }

  private static func decode() -> MerchantKeyPresets {
    guard let url = Bundle.main.url(forResource: "components_environments", withExtension: "json") else {
      debugPrint("components_environments.json not found in bundle; falling back to EnvironmentVars.")
      return [:]
    }

    do {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(MerchantKeyPresets.self, from: data)
    } catch {
      debugPrint("Failed to decode components_environments.json: \(error.localizedDescription)")
      return [:]
    }
  }
}

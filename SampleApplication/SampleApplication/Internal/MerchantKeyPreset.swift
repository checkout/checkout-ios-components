//  Copyright © 2024 Checkout.com. All rights reserved.

import Foundation

struct MerchantKeyPreset: Decodable, Identifiable, Hashable, Sendable {
  let name: String
  let publicKey: String?
  let secretKey: String?
  let processingChannelId: String?

  var id: String { name }

  enum CodingKeys: String, CodingKey {
    case name
    case publicKey = "public_key"
    case secretKey = "secret_key"
    case processingChannelId = "processing_channel_id"
  }
}

/// The list of merchant key presets configured for that environment.
typealias MerchantKeyPresets = [String: [MerchantKeyPreset]]

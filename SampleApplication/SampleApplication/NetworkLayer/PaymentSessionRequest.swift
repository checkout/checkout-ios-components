//  Copyright © 2024 Checkout.com. All rights reserved.

import Foundation

struct PaymentSessionRequest: Encodable {
  let amount: Int
  let currency: String // Three letter ISO currency code
  let billing: Billing
  let successURL: String
  let failureURL: String
  let threeDS: ThreeDS
  let processingChannelID: String?
  
  enum CodingKeys: String, CodingKey {
    case threeDS = "3ds"
    case processingChannelID = "processing_channel_id"
    case amount, currency, billing, successURL, failureURL
  }
}

struct Billing: Encodable {
  let address: BillingAddress
}

struct BillingAddress: Encodable {
  let country: String
}

struct ThreeDS: Encodable {
  let enabled: Bool
  let attemptN3D: Bool
  enum CodingKeys: String, CodingKey {
    case attemptN3D = "attempt_n3d"
    case enabled
  }
}

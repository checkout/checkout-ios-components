//  Copyright © 2025 Checkout.com. All rights reserved.

import Foundation

struct PaymentRequest: Encodable {
  let currency: String
  let source: PaymentSource
  let threeDS: StandaloneThreeDS
}

struct PaymentSource: Encodable {
  let type: String = "id"
  let id: String
}

struct StandaloneThreeDS: Encodable {
  let enabled: Bool = true
  let authenticationId: String
}

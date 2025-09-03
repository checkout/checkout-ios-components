//  Copyright © 2025 Checkout.com. All rights reserved.

import Foundation

struct ThreeDSSessionResponse: Decodable {
  let id: String
  let sessionSecret: String
  let scheme: String
  let card: StandaloneThreeDSCard
}

struct StandaloneThreeDSCard: Decodable {
  let instrumentId: String
  let fingerprint: String
}

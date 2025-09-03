//  Copyright © 2025 Checkout.com. All rights reserved.

import Foundation

struct ThreeDSSessionRequest: Encodable {
  let currency: String
  let amount: Int
  let source: Source
  let completion: Completion
  let processingChannelId: String
}

struct Source: Encodable {
  let type: String = "token"
  let token: String
}

struct Completion: Encodable {
  let type: String = "non_hosted"
}

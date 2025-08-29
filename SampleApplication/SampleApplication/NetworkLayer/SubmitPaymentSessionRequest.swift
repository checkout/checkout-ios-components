//  Copyright © 2024 Checkout.com. All rights reserved.

import Foundation

struct SubmitPaymentSessionRequest: Encodable {
  let sessionData: String
  let amount: Int?
  let reference: String?
  let ipAddress: String?
  let items: [SubmitPaymentSessionRequestItem]?
  let threeDS: ThreeDS?
  
  enum CodingKeys: String, CodingKey {
    case amount, reference, items
    case sessionData = "session_data"
    case ipAddress = "ip_address"
    case threeDS = "3ds"
  }
  
  init(sessionData: String, amount: Int? = nil, reference: String? = nil, ipAddress: String? = nil, items: [SubmitPaymentSessionRequestItem]? = nil, threeDS: ThreeDS? = nil) {
    self.sessionData = sessionData
    self.amount = amount
    self.reference = reference
    self.ipAddress = ipAddress
    self.items = items
    self.threeDS = threeDS
  }
}

struct SubmitPaymentSessionRequestItem: Encodable {
  let name: String
  let quantity: Int
  let unitPrice: Int
  let reference: String?
  
  enum CodingKeys: String, CodingKey {
    case name, quantity, reference
    case unitPrice = "unit_price"
  }
}

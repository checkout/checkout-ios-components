//  Copyright © 2024 Checkout.com. All rights reserved.

import Foundation

struct PaymentSessionRequest: Encodable {
  let amount: Int
  let currency: String // Three letter ISO currency code
  let billing: BillingType
  let reference: String
  let description: String
  let billingDescriptor: BillingDescriptor
  let shipping: Shipping
  let metadata: Metadata
  let paymentType: String?
  let successURL: String
  let failureURL: String
  let threeDS: ThreeDS
  let processingChannelID: String?
  let paymentMethodConfiguration: PaymentMethodConfiguration
  let locale: String?
  let items: [Item]
  let customer: Customer?

  enum CodingKeys: String, CodingKey {
    case amount, currency, reference, description, locale
    case shipping, billing, metadata, items, customer
    case billingDescriptor = "billing_descriptor"
    case threeDS = "3ds"
    case successURL = "success_url"
    case failureURL = "failure_url"
    case paymentType = "payment_type"
    case processingChannelID = "processing_channel_id"
    case paymentMethodConfiguration = "payment_method_configuration"
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

struct PaymentMethodConfiguration: Encodable {
  let applepay: ApplePayConfiguration
}

struct ApplePayConfiguration: Encodable {
  let totalType: String
  
  enum CodingKeys: String, CodingKey {
    case totalType = "total_type"
  }
}

struct BillingDescriptor: Encodable {
  let name: String
  let city: String
}

struct Address: Encodable {
  let addressLine1: String
  let addressLine2: String
  let city: String
  let state: String
  let zip: String
  let country: String

  enum CodingKeys: String, CodingKey {
    case city, state, zip, country
    case addressLine1 = "address_line1"
    case addressLine2 = "address_line2"
  }

  /// Fills non-country fields with empty strings so only `country` needs to be collected in the UI.
  static func countryOnly(_ country: String) -> Address {
    Address(
      addressLine1: "Checkout.com",
      addressLine2: "Checkout.com",
      city: "Checkout.com",
      state: "Checkout.com",
      zip: "Checkout.com",
      country: country
    )
  }
}

struct Phone: Encodable {
  let countryCode: String?
  let number: String?

  enum CodingKeys: String, CodingKey {
    case number
    case countryCode = "country_code"
  }
}

struct Shipping: Encodable {
  let address: Address
  let phone: Phone
}

struct BillingType: Encodable {
  let address: Address
  let phone: Phone?
}

struct Metadata: Encodable {
  let couponCode: String
  let partnerId: Int

  enum CodingKeys: String, CodingKey {
    case couponCode = "coupon_code"
    case partnerId = "partner_id"
  }
}

struct Item: Encodable {
  let name: String
  let quantity: Int
  let unitPrice: Int
  let totalAmount: Int

  enum CodingKeys: String, CodingKey {
    case name, quantity
    case unitPrice = "unit_price"
    case totalAmount = "total_amount"
  }
}

struct Customer: Encodable {
  let email: String?
  let name: String
  let phone: Phone?
}

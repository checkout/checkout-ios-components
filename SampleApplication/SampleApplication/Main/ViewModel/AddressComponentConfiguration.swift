//  Copyright © 2025 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import Foundation

enum AddressComponentConfiguration: String, CaseIterable {
  case empty = "Empty"
  case prefillShipping = "Prefill shipping"
  case prefillBilling = "Prefill billing"
  case prefillCustomized = "Prefill customized"
  case noPrefill = "No prefill"
  case addressOnly = "Adress Only"
  case noPhone = "No phone"
  case noName = "No name"
  case noEmail = "No email"
  
  var addressConfiguration: CheckoutComponents.AddressConfiguration? {
    typealias ContactData = CheckoutComponents.ContactData
    typealias Address = CheckoutComponents.Address
    typealias Configuration = CheckoutComponents.AddressConfiguration
    typealias AddressField = CheckoutComponents.AddressField
    
    let fullAddress = ContactData(address: .init(country: .unitedKingdom,
                                                      addressLine1: "Wenlock Works",
                                                      addressLine2: "Shepherdess Walk",
                                                      city: "London",
                                                      zip: "N1 7BQ"),
                                       phone: .init(countryCode: "+44",
                                                    number: "1234567890"),
                                       name: .init(firstName: "John",
                                                   lastName: "Doe"),
                                       email: "john_doe@checkout.com")
    
    let completion: @MainActor @Sendable (CheckoutComponents.ContactData) -> Void = { debugPrint("Collected address: \($0)") }
    
    switch self {
    case .empty:
      return nil
    case .prefillShipping:
      return Configuration.init(data: fullAddress,
                                fields: AddressField.shipping,
                                onComplete: completion)
    case .prefillBilling:
      return Configuration.init(data: fullAddress,
                                fields: AddressField.billing,
                                onComplete: completion)
    case .prefillCustomized:
      return Configuration.init(data: fullAddress,
                                fields: [
                                  .addressLine1(isOptional: true),
                                  .addressLine2(isOptional: false),
                                  .phone(isOptional: false),
                                  .email(isOptional: true),
                                  .state(isOptional: true),
                                  .zip(isOptional: false)
                                ],
                                onComplete: completion)
    case .noPrefill:
      return Configuration.init(data: nil,
                                fields: AddressField.shipping,
                                onComplete: completion)
    case .addressOnly:
      return Configuration.init(data: .init(address: fullAddress.address),
                                fields: AddressField.shipping,
                                onComplete: completion)
    case .noPhone:
      return Configuration.init(data: .init(address: fullAddress.address,
                                            name: fullAddress.name,
                                            email: fullAddress.email),
                                fields: AddressField.shipping,
                                onComplete: completion)
    case .noName:
      return Configuration.init(data: .init(address: fullAddress.address,
                                            phone: fullAddress.phone,
                                            email: fullAddress.email),
                                fields: AddressField.shipping,
                                onComplete: completion)
    case .noEmail:
      return Configuration.init(data: .init(address: fullAddress.address,
                                            phone: fullAddress.phone,
                                            name: fullAddress.name),
                                fields: AddressField.shipping,
                                onComplete: completion)
    }
  }
  
  var accessibilityIdentifier: String {
    switch self {
    case .empty:
      "empty"
    case .prefillShipping:
      "prefill_shipping"
    case .prefillBilling:
      "prefill_billing"
    case .prefillCustomized:
      "prefill_customized"
    case .noPrefill:
      "no_prefill"
    case .addressOnly:
      "address_only"
    case .noPhone:
      "no_phone"
    case .noName:
      "no_name"
    case .noEmail:
      "no_email"
    }
  }
}

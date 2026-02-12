//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import Foundation

enum LocaleOption: Hashable {
  case none
  case customised
  case locale(CheckoutComponents.Locale)
  
  var displayName: String {
    switch self {
    case .none: return "None"
    case .customised: return "Customised"
    case .locale(let locale): return locale.rawValue
    }
  }
  
  var localeString: String? {
    switch self {
    case .none: return nil
    case .customised: return "Customised"
    case .locale(let locale): return locale.rawValue
    }
  }
  
  var accessibilityIdentifier: String {
    switch self {
    case .none: return "none"
    case .customised: return "custom_locale_option"
    case .locale(let locale): return locale.rawValue
    }
  }
  
  static var allOptions: [LocaleOption] {
    [.none, .customised] + CheckoutComponents.Locale.allCases.map { .locale($0) }
  }
  
  static var paymentSessionOptions: [LocaleOption] {
    [.none] + CheckoutComponents.Locale.allCases.map { .locale($0) }
  }
}

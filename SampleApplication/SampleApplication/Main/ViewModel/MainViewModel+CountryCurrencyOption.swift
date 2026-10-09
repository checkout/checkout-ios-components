//  Copyright © 2026 Checkout.com. All rights reserved.

import Foundation

enum CountryOption: String, CaseIterable, Hashable {
  case gb = "GB"
  case ae = "AE"
  case sa = "SA"
  case nl = "NL"
  case kw = "KW"

  var displayName: String { rawValue }

  var accessibilityIdentifier: String {
    "country_option_\(rawValue.lowercased())"
  }
}

enum CurrencyOption: String, CaseIterable, Hashable {
  case gbp = "GBP"
  case aed = "AED"
  case sar = "SAR"
  case eur = "EUR"
  case kwd = "KWD"

  var displayName: String { rawValue }

  var accessibilityIdentifier: String {
    "currency_option_\(rawValue.lowercased())"
  }
}

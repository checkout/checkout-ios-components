//  Copyright © 2026 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import Foundation

// MARK: - Value Mapping

/// Enum values match ignoring case and separators, so `collect_consent`, `collectConsent` and
/// `CollectConsent` agree.
enum ConfigName {
  static func normalised(_ value: String) -> String {
    value.lowercased().filter { $0.isLetter || $0.isNumber }
  }

  /// The case whose name matches `value`, checking `aliases` (keyed by normalised name) first.
  static func match<Option: CaseIterable>(
    _ value: String?,
    as type: Option.Type,
    aliases: [String: Option] = [:]
  ) -> Option? {
    guard let value, !normalised(value).isEmpty else {
      return nil
    }
    let key = normalised(value)
    return aliases[key] ?? Option.allCases.first { normalised(String(describing: $0)) == key }
  }
}

enum AppearancePreset: Equatable {
  case `default`
  case dark

  init?(configValue: String) {
    switch configValue.lowercased() {
    case "default":
      self = .default
    case "dark":
      self = .dark
    default:
      return nil
    }
  }
}

extension CheckoutComponents.Environment {
  /// Maps a launch-config string (`"sandbox"` / `"production"`) to an
  /// `Environment`, returning nil for unrecognised values.
  init?(configValue: String) {
    switch configValue.lowercased() {
    case "sandbox":
      self = .sandbox
    case "production", "prod", "live":
      self = .production
    default:
      return nil
    }
  }
}

extension CheckoutComponent {
  /// Matches the case name (`applePay`, `stored_card`), with `googlePay` standing in for Apple Pay.
  /// `rawValue` is the Settings picker label, so it is not used.
  init?(configValue: String) {
    let match = ConfigName.match(configValue, as: CheckoutComponent.self, aliases: ["googlepay": .applePay])
      ?? CheckoutComponent.allCases.first { $0.accessibilityIdentifier == configValue.lowercased() }
    guard let match else {
      return nil
    }
    self = match
  }
}

extension StoredCardSource {
  init?(configValue: String) {
    switch configValue.lowercased() {
    case "none":
      self = .none
    case "instrumentids":
      self = .instrumentIds
    case "customerid":
      self = .customerId
    default:
      return nil
    }
  }
}

extension CardScheme {
  /// Unknown names are dropped, so `[]` and an all-unknown list both accept every scheme.
  static func set(fromConfig values: [String]) -> Set<CardScheme> {
    Set(values.compactMap(CardScheme.init(configValue:)))
  }

  init?(configValue: String) {
    let normalised = Self.normalisedName(configValue)
    guard let match = CardScheme.selectableCases.first(where: { Self.normalisedName($0.rawValue) == normalised }) else {
      return nil
    }
    self = match
  }

  private static func normalisedName(_ value: String) -> String {
    value.lowercased().filter { $0.isLetter || $0.isNumber }
  }
}

extension CheckoutComponents.StoredCardDisplayMode {
  init?(configValue: String) {
    switch configValue.lowercased() {
    case "default":
      self = .defaultCard
    case "all":
      self = .all
    default:
      return nil
    }
  }
}

extension PaymentMethodType {
  /// Flow payment method wire names; `googlepay` stands in for Apple Pay.
  init?(configValue: String) {
    guard let match = ConfigName.match(configValue, as: PaymentMethodType.self, aliases: ["googlepay": .applePay])
    else {
      return nil
    }
    self = match
  }
}

extension CheckoutComponents.PaymentButtonAction {
  init?(configValue: String) {
    switch ConfigName.normalised(configValue) {
    case "payment":
      self = .payment
    case "tokenize", "tokenization":
      self = .tokenization
    default:
      return nil
    }
  }
}

extension CheckoutComponents.CardType {
  /// Matches the raw values ignoring case and separators, so `deferred_debit` reads as `deferredDebit`.
  static func set(fromConfig values: [String]) -> Set<CheckoutComponents.CardType> {
    Set(values.compactMap { CheckoutComponents.CardType(rawValue: ConfigName.normalised($0)) })
  }
}

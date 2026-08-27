//  Copyright © 2026 Checkout.com. All rights reserved.

import Foundation

/// Records every SDK callback fired, oldest first.
@MainActor
final class CallbackInfoStore: ObservableObject {
  @Published private(set) var entries: [String]

  private let defaults: UserDefaults
  private static let storageKey = "callback_info"

  private static let timestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    self.entries = defaults.stringArray(forKey: Self.storageKey) ?? []
  }

  func add(_ info: String) {
    entries.append("\(Self.timestampFormatter.string(from: Date())) - \(info)")
    defaults.set(entries, forKey: Self.storageKey)
  }

  func clear() {
    entries = []
    defaults.removeObject(forKey: Self.storageKey)
  }
}

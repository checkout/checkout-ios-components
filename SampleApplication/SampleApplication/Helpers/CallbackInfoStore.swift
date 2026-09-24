//  Copyright © 2026 Checkout.com. All rights reserved.

import Foundation

/// Records every SDK callback fired, oldest first.
@MainActor
final class CallbackInfoStore: ObservableObject {
  @Published private(set) var entries: [String]

  private var persistedEntries: [String]
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
    let stored = defaults.stringArray(forKey: Self.storageKey) ?? []
    self.entries = stored
    self.persistedEntries = stored
  }

  func add(_ info: String, persist: Bool = true) {
    let entry = "\(Self.timestampFormatter.string(from: Date())) - \(info)"
    entries.append(entry)
    guard persist else { return }
    persistedEntries.append(entry)
    defaults.set(persistedEntries, forKey: Self.storageKey)
  }

  func clear() {
    entries = []
    persistedEntries = []
    defaults.removeObject(forKey: Self.storageKey)
  }
}

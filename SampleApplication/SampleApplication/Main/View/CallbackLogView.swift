//  Copyright © 2026 Checkout.com. All rights reserved.

import SwiftUI

/// Lists every SDK callback fired, oldest first.
struct CallbackLogView: View {
  @ObservedObject var store: CallbackInfoStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        ForEach(Array(store.entries.enumerated()), id: \.offset) { index, entry in
          Text(entry)
            .font(.caption)
            .accessibilityIdentifier(AccessibilityIdentifier.CallbackLogView.entry(index: index + 1))
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifier.CallbackLogView.screen.rawValue)
      .navigationTitle("Callback Info")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Delete") { store.clear() }
            .accessibilityIdentifier(AccessibilityIdentifier.CallbackLogView.clearButton.rawValue)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("OK") { dismiss() }
            .accessibilityIdentifier(AccessibilityIdentifier.CallbackLogView.closeButton.rawValue)
        }
      }
    }
  }
}

#Preview {
  CallbackLogView(store: CallbackInfoStore())
}

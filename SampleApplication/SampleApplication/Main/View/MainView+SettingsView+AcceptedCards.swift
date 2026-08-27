//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

// MARK: - Accepted card schemes

extension MainView {
  private var allCardSchemes: [CardScheme] {
    [
      .americanExpress, .cartesBancaires,
      .chinaUnionPay, .dinersClub,
      .discover, .jcb,
      .mada, .jaywan, .mastercard,
      .visa, .maestro
    ]
  }

  func acceptedCardSchemesPicker(title: String,
                                 selectedSchemes: Binding<Set<CardScheme>>,
                                 accessibilityIdentifierSuffix: String) -> some View {
    DisclosureGroup {
      ForEach(allCardSchemes, id: \.self) { scheme in
        Button(action: {
          if selectedSchemes.wrappedValue.contains(scheme) {
            selectedSchemes.wrappedValue.remove(scheme)
          } else {
            selectedSchemes.wrappedValue.insert(scheme)
          }
        }) {
          HStack {
            Text(scheme.rawValue.capitalized)
            Spacer()
            if selectedSchemes.wrappedValue.contains(scheme) {
              Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    } label: {
      Text(title)
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
    }
    .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.acceptedCardSchemesPicker.rawValue + accessibilityIdentifierSuffix)
  }

  var cardAcceptedCardSchemesView: some View {
    acceptedCardSchemesPicker(title: "Card accepted card schemes:",
                              selectedSchemes: $viewModel.cardAcceptedCardSchemes,
                              accessibilityIdentifierSuffix: "_card")
  }

  var applePayAcceptedCardSchemesView: some View {
    acceptedCardSchemesPicker(title: "Apple Pay accepted card schemes:",
                              selectedSchemes: $viewModel.applePayAcceptedCardSchemes,
                              accessibilityIdentifierSuffix: "_apple_pay")
  }

  var rememberMeAcceptedCardSchemesView: some View {
    acceptedCardSchemesPicker(title: "Remember Me accepted card schemes:",
                              selectedSchemes: $viewModel.rememberMeAcceptedCardSchemes,
                              accessibilityIdentifierSuffix: "_remember_me")
  }

  var storedCardAcceptedCardSchemesView: some View {
    acceptedCardSchemesPicker(title: "Stored Card accepted card schemes:",
                              selectedSchemes: $viewModel.storedCardAcceptedCardSchemes,
                              accessibilityIdentifierSuffix: "_stored_card")
  }
}

// MARK: - Accepted card types

extension MainView {
  private var allCardTypes: [CheckoutComponents.CardType] {
    [
      .credit, .debit,
      .prepaid, .charge,
      .deferredDebit
    ]
  }

  func acceptedCardTypesPicker(title: String,
                               selectedTypes: Binding<Set<CheckoutComponents.CardType>>,
                               cardTypes: [CheckoutComponents.CardType],
                               accessibilityIdentifierSuffix: String) -> some View {
    DisclosureGroup {
      ForEach(cardTypes, id: \.self) { type in
        Button(action: {
          if selectedTypes.wrappedValue.contains(type) {
            selectedTypes.wrappedValue.remove(type)
          } else {
            selectedTypes.wrappedValue.insert(type)
          }
        }) {
          HStack {
            Text(type.rawValue.capitalized)
            Spacer()
            if selectedTypes.wrappedValue.contains(type) {
              Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    } label: {
      Text(title)
        .accessibilityIdentifier(title)
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier(AccessibilityIdentifier.SettingsView.acceptedCardTypesPicker.rawValue + accessibilityIdentifierSuffix)
  }

  var cardAcceptedCardTypesView: some View {
    acceptedCardTypesPicker(title: "Card accepted card types:",
                            selectedTypes: $viewModel.cardAcceptedCardTypes,
                            cardTypes: allCardTypes,
                            accessibilityIdentifierSuffix: "_card")
  }

  var applePayAcceptedCardTypesView: some View {
    acceptedCardTypesPicker(title: "Apple Pay accepted card types:",
                            selectedTypes: $viewModel.applePayAcceptedCardTypes,
                            cardTypes: [.credit, .debit],
                            accessibilityIdentifierSuffix: "_apple_pay")
  }

  var rememberMeAcceptedCardTypesView: some View {
    acceptedCardTypesPicker(title: "RememberMe accepted card types:",
                            selectedTypes: $viewModel.rememberMeAcceptedCardTypes,
                            cardTypes: allCardTypes,
                            accessibilityIdentifierSuffix: "_remember_me")
  }

  var storedCardAcceptedCardTypesView: some View {
    acceptedCardTypesPicker(title: "Stored Card accepted card types:",
                            selectedTypes: $viewModel.storedCardAcceptedCardTypes,
                            cardTypes: allCardTypes,
                            accessibilityIdentifierSuffix: "_stored_card")
  }
}

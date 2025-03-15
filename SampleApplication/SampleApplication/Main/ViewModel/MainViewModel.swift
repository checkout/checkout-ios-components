//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

@MainActor
final class MainViewModel: ObservableObject, Sendable {
  @Published var checkoutComponentsView: AnyView?

  @Published var showPaymentResult: Bool = false
  @Published var paymentSucceeded: Bool = true
  @Published var paymentID: String = ""
  @Published var errorMessage: String = ""

  @Published var isDefaultAppearance = true
  var showPayButton = true

  private var component: CheckoutComponents.Actionable?
  private let networkLayer = NetworkLayer()
}

extension MainViewModel {
  func makeComponent() async {
    do {
      let paymentSession = try await createPaymentSession()
      let checkoutComponentsSDK = try await initialiseCheckoutComponentsSDK(with: paymentSession)
      let component = try createComponent(with: checkoutComponentsSDK)
      self.component = component
      let renderedComponent = render(component: component)

      checkoutComponentsView = renderedComponent

    } catch let error as CheckoutComponents.Error {
      errorMessage = error.localizedDescription
      print(error.localizedDescription)

    } catch {
      errorMessage = error.localizedDescription
      print("Network error: \(error.localizedDescription).\nCheck if your keys are correct.")
    }
  }
}

extension MainViewModel {
  // Step 1: Create Payment Session
  func createPaymentSession() async throws -> PaymentSession {
    let request = PaymentSessionRequest(amount: 1,
                                        currency: "GBP",
                                        billing: .init(address: .init(country: "GB")),
                                        successURL: Constants.successURL,
                                        failureURL: Constants.failureURL,
                                        threeDS: .init(enabled: true, attemptN3D: true))

    let paymentSession = try await networkLayer.createPaymentSession(request: request)
    return paymentSession
  }

  // Step 2: Initialise an instance of Checkout Components SDK
  func initialiseCheckoutComponentsSDK(with paymentSession: PaymentSession) async throws (CheckoutComponents.Error) -> CheckoutComponents {
    let configuration = try await CheckoutComponents.Configuration(
      paymentSession: paymentSession,
      publicKey: EnvironmentVars.publicKey,
      environment: .sandbox,
      appearance: isDefaultAppearance ? .init() : DarkTheme().designToken,
      callbacks: initialiseCallbacks())

    return CheckoutComponents(configuration: configuration)
  }

  // Step 3: Create any component available
  func createComponent(with checkoutComponentsSDK: CheckoutComponents) throws (CheckoutComponents.Error) -> any CheckoutComponents.Actionable {
    return try checkoutComponentsSDK.create(
      .flow(options: [
        .card(showPayButton: showPayButton, paymentButtonAction: .payment),
        .applePay(merchantIdentifier: "merchant.com.flow.checkout.sandbox")
      ])
    )
  }

  // Step 4: Render the created component to get the view to be shown
  func render(component: any CheckoutComponents.Actionable) -> AnyView? {
    // Check if component is available first

    if component.isAvailable {
      return component.render()
    } else {
      return nil
    }
  }
}

extension MainViewModel {
  func merchantTokenizationTapped() {
    component?.tokenize()
  }
}

//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
  @Published var checkoutComponentsView: AnyView?

  @Published var showPaymentResult: Bool = false
  @Published var paymentSucceeded: Bool = true
  @Published var paymentResultText: String = ""
  @Published var errorMessage: String = ""

  @Published var isDefaultAppearance = true {
    didSet {
      NavigationHelper.navigationBarTitleTextColor(isDefaultAppearance ? .black : .white)
    }
  }
  var showPayButton = true

  private var component: Any?
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

    return try await networkLayer.createPaymentSession(request: request)
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
  func createComponent(with checkoutComponentsSDK: CheckoutComponents) throws (CheckoutComponents.Error) -> Any {
    return try checkoutComponentsSDK.create(
      .flow(options: [
        .card(showPayButton: showPayButton,
              paymentButtonAction: .payment,
              addressConfiguration: addressConfiguration
             ),
        .applePay(merchantIdentifier: "merchant.com.flow.checkout.sandbox")
      ])
    )
  }

  // Step 4: Render the created component to get the view to be shown
  func render(component: Any) -> AnyView? {
    // Check if component is available first

    guard let component = component as? any CheckoutComponents.Renderable else {
      return nil
    }

    if component.isAvailable {
      return component.render()
    } else {
      return nil
    }
  }
}

extension MainViewModel {
  var addressConfiguration: CheckoutComponents.AddressConfiguration {
    typealias ContactData = CheckoutComponents.ContactData
    typealias Address = CheckoutComponents.Address
    typealias Configuration = CheckoutComponents.AddressConfiguration
    
    let prefilledAddress = ContactData(address: .init(country: .unitedKingdom,
                                                      addressLine1: "Wenlock Works",
                                                      addressLine2: "Shepherdess Walk",
                                                      city: "London",
                                                      zip: "N1 7BQ"),
                                       phone: .init(countryCode: "+$4",
                                                    number: "1234567890"),
                                       name: .init(firstName: "John",
                                                   lastName: "Doe"),
                                       email: "john_doe@checkout.com")
    
    let addressConfiguration = Configuration.init(data: prefilledAddress,
                                                  fields: CheckoutComponents.AddressField.billing
                                                          + [.phone(isOptional: false)]) { collectedAddress in
      debugPrint("Collected address: \(collectedAddress)")
    }

    return addressConfiguration
  }
}

extension MainViewModel {
  func merchantTokenizationTapped() {
    guard let component = component as? any CheckoutComponents.Tokenizable else {
      debugPrint("Component does not conform to Tokenizable. e.g. It might be an Address Component or alike")
      return
    }
    component.tokenize()
  }
}

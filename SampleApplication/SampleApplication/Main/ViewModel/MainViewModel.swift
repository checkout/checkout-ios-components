//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

enum PaymentMethodType: CaseIterable {
  case card
  case applePay
}

@MainActor
final class MainViewModel: ObservableObject {
  @Published var checkoutComponentsView: AnyView?

  @Published var showPaymentResult: Bool = false
  @Published var paymentSucceeded: Bool = true
  @Published var paymentResultText: String = ""
  @Published var generatedToken: String = ""
  @Published var errorMessage: String = ""
  @Published var showPayButton: Bool = true
  @Published var paymentButtonAction: CheckoutComponents.PaymentButtonAction = .payment
  @Published var selectedModuleType: ModuleType = .flow
  @Published var selectedPaymentMethodTypes: Set<PaymentMethodType> = []
  @Published var selectedLocale: String = CheckoutComponents.Locale.en_GB.rawValue
  @Published var selectedEnvironment: CheckoutComponents.Environment = .sandbox
  @Published var selectedAddressConfiguration: AddressComponentConfiguration = .prefillCustomized

  @Published var isDefaultAppearance = true {
    didSet {
      NavigationHelper.navigationBarTitleTextColor(isDefaultAppearance ? .black : .white)
    }
  }
  
  private var component: Any?
  private let networkLayer = NetworkLayer()
  
  init() {
    selectedPaymentMethodTypes = [.card, .applePay]
  }
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
                                         threeDS: .init(enabled: true, attemptN3D: true),
                                         processingChannelID: nil)

     return try await networkLayer.createPaymentSession(request: request)
   }

  // Step 2: Initialise an instance of Checkout Components SDK
  func initialiseCheckoutComponentsSDK(with paymentSession: PaymentSession) async throws (CheckoutComponents.Error) -> CheckoutComponents {
    let configuration = try await CheckoutComponents.Configuration(
      paymentSession: paymentSession,
      publicKey: EnvironmentVars.publicKey,
      environment: selectedEnvironment,
      appearance: isDefaultAppearance ? .init() : DarkTheme().designToken,
      locale: selectedLocale,
      translations: getTranslation(),
      callbacks: initialiseCallbacks())

    return CheckoutComponents(configuration: configuration)
  }

  // Step 3: Create any component available
  func createComponent(with checkoutComponentsSDK: CheckoutComponents) throws (CheckoutComponents.Error) -> Any {
    switch selectedModuleType {
    case .flow:
      return try checkoutComponentsSDK.create(.flow(options: selectedPaymentMethods))
    case .card:
      return try checkoutComponentsSDK.create(getCardPaymentMethod())
    case .applePay:
      return try checkoutComponentsSDK.create(getApplePayPaymentMethod())
    }
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
  var isCardSelected: Bool {
    get { selectedPaymentMethodTypes.contains(.card) }
    set {
      if newValue {
        selectedPaymentMethodTypes.insert(.card)
      } else {
        selectedPaymentMethodTypes.remove(.card)
      }
    }
  }
  
  var isApplePaySelected: Bool {
    get { selectedPaymentMethodTypes.contains(.applePay) }
    set {
      if newValue {
        selectedPaymentMethodTypes.insert(.applePay)
      } else {
        selectedPaymentMethodTypes.remove(.applePay)
      }
    }
  }
  
  var selectedPaymentMethodsTitle: String {
    var selectedMethods: [String] = []
    
    if isCardSelected {
      selectedMethods.append("Card")
    }
    
    if isApplePaySelected {
      selectedMethods.append("Apple Pay")
    }
    
    if selectedMethods.isEmpty {
      return "Payment Methods"
    } else {
      return selectedMethods.joined(separator: ", ")
    }
  }

  // Computed property to get actual payment methods with current configuration
  var selectedPaymentMethods: Set<CheckoutComponents.PaymentMethod> {
    var methods: Set<CheckoutComponents.PaymentMethod> = []
    
    if selectedPaymentMethodTypes.contains(.card) {
      methods.insert(getCardPaymentMethod())
    }
    
    if selectedPaymentMethodTypes.contains(.applePay) {
      methods.insert(getApplePayPaymentMethod())
    }
    
    return methods
  }
  
  func getCardPaymentMethod() -> CheckoutComponents.PaymentMethod {
    .card(showPayButton: showPayButton,
          paymentButtonAction: paymentButtonAction,
          addressConfiguration: selectedAddressConfiguration.addressConfiguration)
  }
  
  func getApplePayPaymentMethod() -> CheckoutComponents.PaymentMethod {
    .applePay(merchantIdentifier: "merchant.com.flow.checkout.sandbox")
  }
  
  func resetToDefaultConfiguration() {
    checkoutComponentsView = nil
    selectedModuleType = .flow
    selectedPaymentMethodTypes = [.card, .applePay]
    showPayButton = true
    paymentButtonAction = .payment
    selectedLocale = CheckoutComponents.Locale.en_GB.rawValue
    selectedEnvironment = .sandbox
    selectedAddressConfiguration = .prefillCustomized
    isDefaultAppearance = true
  }
  
  func getLocales() -> [String] {
    CheckoutComponents.Locale.allCases.map(\.rawValue)
  }
  
  func getTranslation() -> [String: [CheckoutComponents.TranslationKey : String]] {
    guard selectedLocale == "Customised" else { return [:] }
    
    return [selectedLocale: [
      .card: "😂",
      .cardHolderName: "🤷🏻‍♂️",
      .cardNumber: "🔢"
    ]]
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

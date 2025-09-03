//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI
import Checkout3DS

enum PaymentMethodType: CaseIterable {
  case card
  case applePay
}

enum CustomButtonOperation: String, CaseIterable {
  case tokenization = "Tokenization"
  case submitPayment = "Submit Payment"
}

@MainActor
final class MainViewModel: ObservableObject {
  @Published var checkoutComponentsView: AnyView?

  @Published var showPaymentResult: Bool = false
  @Published var paymentSucceeded: Bool = true
  @Published var paymentResultText: String = ""
  @Published var generatedToken: String = ""
  @Published var errorMessage: String = ""
  @Published var showCardPayButton: Bool = true
  @Published var paymentButtonAction: CheckoutComponents.PaymentButtonAction = .tokenization
  @Published var selectedComponentType: CheckoutComponent = .flow
  @Published var selectedPaymentMethodTypes: Set<PaymentMethodType> = []
  @Published var selectedLocale: String = CheckoutComponents.Locale.en_GB.rawValue
  @Published var selectedEnvironment: CheckoutComponents.Environment = .sandbox
  @Published var selectedAddressConfiguration: AddressComponentConfiguration = .prefillCustomized
  @Published var handleSubmitManually = false
  @Published var updatedAmount = ""
  @Published var isShowUpdateView = false
  @Published var showApplePayButton: Bool = true
  @Published var isAdvancedFeaturesExpanded: Bool = false
  @Published var customButtonOperation: CustomButtonOperation = .submitPayment

  @Published var isDefaultAppearance = true {
    didSet {
      NavigationHelper.navigationBarTitleTextColor(isDefaultAppearance ? .black : .white)
    }
  }
  
  var paymentSessionId = ""
  var createdCheckoutComponentsSDK: CheckoutComponents?
  private var component: Any?
  let networkLayer = NetworkLayer()
  let amount: Int = 100
  let currency: String = "GBP"

  lazy var checkout3DSSDK: Checkout3DSService = { .init(environment: .sandbox) }()

  init() {
    selectedPaymentMethodTypes = [.card, .applePay]
  }
}

extension MainViewModel {
  func makeComponent() async {
    do {
      let paymentSession = try await createPaymentSession()
      paymentSessionId = paymentSession.id
      let checkoutComponentsSDK = try await initialiseCheckoutComponentsSDK(with: paymentSession)
      createdCheckoutComponentsSDK = checkoutComponentsSDK
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
     let request = PaymentSessionRequest(amount: amount,
                                         currency: currency,
                                         billing: .init(address: .init(country: "GB")),
                                         successURL: Constants.successURL,
                                         failureURL: Constants.failureURL,
                                         threeDS: .init(enabled: true, attemptN3D: true),
                                         processingChannelID: EnvironmentVars.processingChannelID)

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
    switch selectedComponentType {
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
    .card(showPayButton: showCardPayButton,
          paymentButtonAction: paymentButtonAction,
          addressConfiguration: selectedAddressConfiguration.addressConfiguration)
  }
  
  func getApplePayPaymentMethod() -> CheckoutComponents.PaymentMethod {
    .applePay(merchantIdentifier: "merchant.com.flow.checkout.sandbox",
              showPayButton: showApplePayButton)
  }
  
  func resetToDefaultConfiguration() {
    checkoutComponentsView = nil
    selectedComponentType = .flow
    selectedPaymentMethodTypes = [.card, .applePay]
    showCardPayButton = true
    paymentButtonAction = .payment
    selectedLocale = CheckoutComponents.Locale.en_GB.rawValue
    selectedEnvironment = .sandbox
    selectedAddressConfiguration = .prefillCustomized
    isDefaultAppearance = true
    updatedAmount = ""
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
  // Tokenization is only operational for the card component to tokenize the card details input by the user
  func merchantTokenizationTapped() {
    guard let component = component as? any CheckoutComponents.Tokenizable else {
      print("Component does not conform to Tokenizable. e.g. It might be an Address Component or alike")
      return
    }
    component.tokenize()
  }
}

extension MainViewModel {
  // `submit()` function is useful for the cases where you want a central control for payment submission, orchestrated by your own payment button
  func submit() {
    guard let component = component as? any CheckoutComponents.Submittable else {
      print("Component does not conform to Submittable. e.g. It might be an Address Component or alike")
      return
    }

    // Check the validity of the component before calling the submit function.
    guard component.isValid else {
      let debugString =
      """
      Component did not pass the validation checks. Input fields might be wrongly filled in.
      If you want to display the validation error texts, call `submit()` function without calling `component.isValid`.
      Components without any input fields are always marked isValid as true.
      """
      print(debugString)
      return
    }

    component.submit()
  }
}

extension MainViewModel {
  // Calling .update(with:) function just updates the UI,
  // for updating the payment session you have to provide handleSubmit callback.
  func updatePaymentAmount() {
    guard let amount = Int(updatedAmount) else { return }
    
    do {
      let updateDetails = CheckoutComponents.UpdateDetails(amount: amount)
      try createdCheckoutComponentsSDK?.update(with: updateDetails)
    } catch {
      errorMessage = error.localizedDescription
      print("Update amount error: \(error.localizedDescription).\nCheck if your input is correct.")
    }
  }
  
  func submitPaymentSession(with submitData: String) async throws -> CheckoutComponents.PaymentSessionSubmissionResult {
    let submitPaymentRequest = SubmitPaymentSessionRequest(sessionData: submitData,
                                                           amount: 100,
                                                           threeDS: ThreeDS(enabled: false,
                                                                            attemptN3D: false))
    
    return try await networkLayer.submitPaymentSession(paymentSessionId: paymentSessionId,
                                                       request: submitPaymentRequest)
  }
}

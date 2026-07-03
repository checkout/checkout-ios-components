//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
@_spi(CheckoutInternal) import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

#if canImport(CheckoutPaymentMethods)
import CheckoutPaymentMethods
#endif

enum PaymentMethodType: CaseIterable {
  case card
  case applePay
  case tabby
  case tamara
  case stcPay
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
  @Published var showAPMPayButton: Bool = true
  @Published var paymentButtonAction: CheckoutComponents.PaymentButtonAction = .payment
  @Published var selectedComponentType: CheckoutComponent = .flow
  @Published var selectedPaymentMethodTypes: Set<PaymentMethodType> = []
  @Published var selectedLocale: LocaleOption = .locale(.en_GB)
  @Published var paymentSessionSelectedLocale: LocaleOption = .locale(.en_GB)
  @Published var selectedCountry: CountryOption = .gb
  @Published var selectedCurrency: CurrencyOption = .gbp
  @Published var amount: Int = 10500
  @Published var selectedEnvironment: CheckoutComponents.Environment = .sandbox
  #if INTERNAL_SAMPLE_APP
  @Published var selectedMerchantKey: MerchantKeyPreset?
  #endif
  @Published var selectedAddressConfiguration: AddressComponentConfiguration = .prefillCustomized
  @Published var selectedApplePayType: ApplePayType = .final
  @Published var displayCardHolderName: CheckoutComponents.DisplayCardHolderName = .top
  @Published var cardAcceptedCardSchemes: Set<CardScheme> = []
  @Published var applePayAcceptedCardSchemes: Set<CardScheme> = []
  @Published var rememberMeAcceptedCardSchemes: Set<CardScheme> = []
  @Published var rememberMeAcceptedCardTypes: Set<CheckoutComponents.CardType> = []
  @Published var cardAcceptedCardTypes: Set<CheckoutComponents.CardType> = []
  @Published var applePayAcceptedCardTypes: Set<CheckoutComponents.CardType> = []
  @Published var handleSubmitManually = false
  @Published var updatedAmount = ""
  @Published var isShowUpdateView = false
  @Published var showApplePayButton: Bool = true
  @Published var applePayButtonStyle: CheckoutComponents.ApplePayButtonStyle = .black
  @Published var applePayButtonType: CheckoutComponents.ApplePayButtonType = .plain
  @Published var isAdvancedFeaturesExpanded: Bool = false
  @Published var customButtonOperation: CustomButtonOperation = .submitPayment
  // Reflects the active payment method's `isPayButtonRequired` from `onChange`.
  // Defaults to `true` to match the SDK default; staged methods like STC Pay
  // report `false` on their first stage so the custom pay button stays hidden.
  @Published var isPayButtonRequired: Bool = true

  @Published var isPaymentSessionConfigurationExpanded: Bool = false
  @Published var paymentSessionUsername: String = ""
  @Published var paymentSessionUserEmail: String = ""

  // RememberMe
  @Published var isRememberMeExpanded: Bool = false
  @Published var isRememberMeSDKSetupExpanded: Bool = true
  @Published var isRememberMePaymentSessionSetupExpanded: Bool = true
  @Published var showRememberMe: Bool = true
  @Published var showRememberMePayButton: Bool = true
  // RememberMe SDK
  @Published var userEmail: String = ""
  @Published var userPhoneNumber: String = ""
  @Published var userCountryCode: String = ""
  // RememberMe PaymentSession
  @Published var paymentSessionCountryCode: String = ""
  @Published var paymentSessionPhoneNumber: String = ""
  
  @Published var hideSecurityCode: Bool = false
  @Published var cardHolderNameMaxLength: UInt = 255

  @Published var isDefaultAppearance = true {
    didSet {
      NavigationHelper.navigationBarTitleTextColor(isDefaultAppearance ? .black : .white)
    }
  }
  
  @Published var isIgnoreRememberMeEmailFeatureFlagEnabled: Bool = false {
    didSet {
      UserDefaults.standard.set(
        isIgnoreRememberMeEmailFeatureFlagEnabled,
        forKey: "checkout_components_disable_forwarding_emails"
      )
    }
  }
  
  @Published var captureCvvEnabled: Bool = false {
    didSet {
      UserDefaults.standard.set(
        captureCvvEnabled,
        forKey: "checkout_components_capture_cvv"
      )
    }
  }

  var paymentSessionId = ""
  var createdCheckoutComponentsSDK: CheckoutComponents?
  private var component: Any?
  private let networkLayer = NetworkLayer()
  #if INTERNAL_SAMPLE_APP
  let merchantKeyPresetProvider: any MerchantKeyPresetProviding

  @Published var merchantKeysPreset: MerchantKeyPresets = [:]
  #endif

  var apmProviders: [any CheckoutComponents.PaymentMethodProvider] {
    #if canImport(CheckoutPaymentMethods)
    var providers: [any CheckoutComponents.PaymentMethodProvider] = []
    if selectedPaymentMethodTypes.contains(.tabby) {
      providers.append(CheckoutPaymentOptions.Provider.tabby)
    }
    if selectedPaymentMethodTypes.contains(.tamara) {
      providers.append(CheckoutPaymentOptions.Provider.tamara)
    }
    if selectedPaymentMethodTypes.contains(.stcPay) {
      providers.append(CheckoutPaymentOptions.Provider.stcPay)
    }
    return providers
    #else
    return []
    #endif
  }

  #if INTERNAL_SAMPLE_APP
  init(merchantKeyPresetProvider: any MerchantKeyPresetProviding = MerchantKeyPresetProvider()) {
    self.merchantKeyPresetProvider = merchantKeyPresetProvider
    selectedPaymentMethodTypes = [.card, .applePay, .tabby, .tamara]
    Task { await loadMerchantKeyPresets() }
  }
  #else
  init() {
    selectedPaymentMethodTypes = [.card, .applePay, .tabby, .tamara, .stcPay]
  }
  #endif
}

extension MainViewModel {
  func makeComponent() async throws {
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
      debugPrint(error.localizedDescription)
      
      throw error
    } catch {
      errorMessage = error.localizedDescription
      debugPrint("Network error: \(error.localizedDescription).\nCheck if your keys are correct.")
      throw error
    }
  }
}

extension MainViewModel {
  // Step 1: Create Payment Session
  func createPaymentSession() async throws -> PaymentSession {
    let address = Address(
      addressLine1: "11 New Burlington Street",
      addressLine2: "Apt 214",
      city: "London",
      state: "London",
      zip: "W1S 3BE",
      country: selectedCountry.rawValue
    )

    let phone = Phone(
      countryCode: "44", number: "7700123456"
    )

    let customer = Customer(
      email: !paymentSessionUserEmail.isEmpty ? paymentSessionUserEmail : "customer+test@checkout.com",
      name: !paymentSessionUsername.isEmpty ? paymentSessionUsername : "Test",
      phone: paymentSessionPhoneModel
    )

    let paymentSessionRequest = PaymentSessionRequest(
      amount: amount,
      currency: selectedCurrency.rawValue,
      billing: BillingType(address: address, phone: phone),
      reference: "cf72664f31984a7ab841d51b7305dc72",
      description: "Set of 3 masks",
      billingDescriptor: BillingDescriptor(name: "SUPERHEROES.COM",
                                           city: "GOTHAM"),
      shipping: Shipping(address: address, phone: phone),
      metadata: Metadata(couponCode: "NY2018",
                         partnerId: 123989),
      paymentType: nil,
      successURL: Constants.successURL,
      failureURL: Constants.failureURL,
      threeDS: .init(enabled: true, attemptN3D: true),
      processingChannelID: resolvedProcessingChannelID,
      paymentMethodConfiguration: PaymentMethodConfiguration(applepay: ApplePayConfiguration(totalType: selectedApplePayType.rawValue)),
      locale: paymentSessionSelectedLocale.localeString,
      items: [
        Item(name: "Guitar",
             quantity: 1,
             unitPrice: 3500,
             totalAmount: 3500),
        Item(name: "Amp",
             quantity: 2,
             unitPrice: 3500,
             totalAmount: 7000)
      ],
      customer: customer
    )

    return try await networkLayer.createPaymentSession(request: paymentSessionRequest,
                                                       environment: selectedEnvironment,
                                                       secretKey: resolvedSecretKey)
  }

  // Step 2: Initialise an instance of Checkout Components SDK
  func initialiseCheckoutComponentsSDK(with paymentSession: PaymentSession) async throws (CheckoutComponents.Error) -> CheckoutComponents {
    let configuration = try await CheckoutComponents.Configuration(
      paymentSession: paymentSession,
      publicKey: resolvedPublicKey,
      environment: selectedEnvironment,
      appearance: isDefaultAppearance ? .init() : DarkTheme().designToken,
      locale: selectedLocale.localeString,
      translations: getTranslation(),
      callbacks: initialiseCallbacks()
    )

    return CheckoutComponents(configuration: configuration)
  }

  // Step 3: Create any component available
  func createComponent(with checkoutComponentsSDK: CheckoutComponents) throws (CheckoutComponents.Error) -> Any {
    switch selectedComponentType {
    case .flow:
      return try checkoutComponentsSDK.create(.flow(options: selectedPaymentMethods, providers: .init(providers: apmProviders, showPayButton: showAPMPayButton)))
    case .card:
      return try checkoutComponentsSDK.create(getCardPaymentMethod())
    case .applePay:
      return try checkoutComponentsSDK.create(getApplePayPaymentMethod())
    #if canImport(CheckoutPaymentMethods)
    case .tabby:
      return try checkoutComponentsSDK.create(CheckoutPaymentOptions.Provider.tabby)
    case .tamara:
      return try checkoutComponentsSDK.create(CheckoutPaymentOptions.Provider.tamara)
    case .stcPay:
      return try checkoutComponentsSDK.create(CheckoutPaymentOptions.Provider.stcPay)
    #endif
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

  var isTabbySelected: Bool {
    get { selectedPaymentMethodTypes.contains(.tabby) }
    set {
      if newValue {
        selectedPaymentMethodTypes.insert(.tabby)
      } else {
        selectedPaymentMethodTypes.remove(.tabby)
      }
    }
  }

  var isTamaraSelected: Bool {
    get { selectedPaymentMethodTypes.contains(.tamara) }
    set {
      if newValue {
        selectedPaymentMethodTypes.insert(.tamara)
      } else {
        selectedPaymentMethodTypes.remove(.tamara)
      }
    }
  }

  var isSTCPaySelected: Bool {
    get { selectedPaymentMethodTypes.contains(.stcPay) }
    set {
      if newValue {
        selectedPaymentMethodTypes.insert(.stcPay)
      } else {
        selectedPaymentMethodTypes.remove(.stcPay)
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

    if isTabbySelected {
      selectedMethods.append("Tabby")
    }

    if isTamaraSelected {
      selectedMethods.append("Tamara")
    }

    if isSTCPaySelected {
      selectedMethods.append("STC Pay")
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
  
  var phoneModel: CheckoutComponents.Phone? {
    .init(countryCode: userCountryCode, number: userPhoneNumber)
  }
  
  func getCardPaymentMethod() -> CheckoutComponents.PaymentMethod {
    // Build Remember Me configuration conditionally
    let rememberMeConfig: CheckoutComponents.RememberMeConfiguration? = {
      guard showRememberMe else { return nil }
      let data = CheckoutComponents.RememberMeConfiguration.Data(
        email: userEmail.isEmpty ? nil : userEmail,
        phone: phoneModel
      )
      return .init(data: data,
                   showPayButton: showRememberMePayButton,
                   acceptedCardSchemes: rememberMeAcceptedCardSchemes,
                   acceptedCardTypes: rememberMeAcceptedCardTypes)
    }()

    return .card(showPayButton: showCardPayButton,
                 paymentButtonAction: paymentButtonAction,
                 cardConfiguration: .init(displayCardHolderName: displayCardHolderName,
                                          acceptedCardSchemes: cardAcceptedCardSchemes,
                                          acceptedCardTypes: cardAcceptedCardTypes,
                                          hideSecurityCode: hideSecurityCode,
                                          cardholderNameMaxLength: cardHolderNameMaxLength),
                 addressConfiguration: selectedAddressConfiguration.addressConfiguration,
                 rememberMeConfiguration: rememberMeConfig)
  }
  
  func getApplePayPaymentMethod() -> CheckoutComponents.PaymentMethod {
    .applePay(merchantIdentifier: "merchant.com.ios.mobile.flow.sandbox",
              showPayButton: showApplePayButton,
              applePayConfiguration: .init(acceptedCardSchemes: applePayAcceptedCardSchemes,
                                           acceptedCardTypes: applePayAcceptedCardTypes,
                                           buttonStyle: applePayButtonStyle,
                                           buttonType: applePayButtonType))
  }
  
  func resetToDefaultConfiguration() {
    checkoutComponentsView = nil
    selectedComponentType = .flow
    selectedPaymentMethodTypes = [.card, .applePay, .tabby, .tamara, .stcPay]
    showCardPayButton = true
    paymentButtonAction = .payment
    selectedLocale = .locale(.en_GB)
    selectedEnvironment = .sandbox
    #if INTERNAL_SAMPLE_APP
    selectedMerchantKey = availableMerchantKeys.first
    #endif
    selectedAddressConfiguration = .prefillCustomized
    isDefaultAppearance = true
    updatedAmount = ""
    amount = 10500
  }
  
  func getLocales() -> [String] {
    CheckoutComponents.Locale.allCases.map(\.rawValue)
  }
  
  func getTranslation() -> [String: [CheckoutComponents.TranslationKey : String]] {
    guard selectedLocale == .customised else { return [:] }
    
    return [selectedLocale.displayName: [
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
                                                           amount: 10500,
                                                           threeDS: ThreeDS(enabled: false,
                                                                            attemptN3D: false))
    
    return try await networkLayer.submitPaymentSession(paymentSessionId: paymentSessionId,
                                                       request: submitPaymentRequest,
                                                       environment: selectedEnvironment,
                                                       secretKey: resolvedSecretKey)
  }
}

// MARK: Private

extension MainViewModel {
  
  private var paymentSessionPhoneModel: Phone? {
    let countryCode = paymentSessionCountryCode.isEmpty ? nil : paymentSessionCountryCode
    let number = paymentSessionPhoneNumber.isEmpty ? nil : paymentSessionPhoneNumber

    guard countryCode != nil || number != nil else {
      return nil
    }

    return Phone(countryCode: countryCode, number: number)
  }

}

#if !INTERNAL_SAMPLE_APP
extension MainViewModel {
  var resolvedPublicKey: String {
    selectedEnvironment == .sandbox ? EnvironmentVars.sandboxPublicKey : EnvironmentVars.productionPublicKey
  }

  var resolvedSecretKey: String {
    selectedEnvironment == .sandbox ? EnvironmentVars.sandboxSecretKey : EnvironmentVars.productionSecretKey
  }

  var resolvedProcessingChannelID: String? {
    selectedEnvironment == .sandbox ? EnvironmentVars.sandboxProcessingChannelID : nil
  }
}
#endif

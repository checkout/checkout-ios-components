//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

// MARK: - Callback Handlers

extension MainViewModel {
  func initialiseCallbacks() -> CheckoutComponents.Callbacks {
    .init(
      onReady: { paymentMethod in
        debugPrint("onReady: Payment method: \(paymentMethod.name)")
      },

      handleTap: { paymentMethod async -> Bool in
        debugPrint("handleTap: Payment method: \(paymentMethod.name)")
        return true
      },

      onChange: { paymentMethod in
        debugPrint("onChange: Payment method: \(paymentMethod.name), isValid: \(paymentMethod.isValid)")
      },
      
      onCardBinChanged: onCardBinChanged(),

      onSubmit: { paymentMethod in
        debugPrint("onSubmit: Payment method: \(paymentMethod.name)")
      },

      onTokenized: onTokenized(),
      
      handleSubmit: handleSubmit(),
      
      onSuccess: onSuccess(),

      onError: onError()
    )
  }
  
  func onCardBinChanged() -> (@Sendable (CardMetadata) -> CheckoutComponents.CallbackResult)? {
    { cardMetadata -> CheckoutComponents.CallbackResult in
      debugPrint("onCardBinChange: Card bin: \(cardMetadata.bin), card scheme: \(cardMetadata.scheme)")
    
      // Apply custom logic based on card scheme
      switch cardMetadata.scheme {
      case "visa":
        break
      case "mastercard":
        break
      default:
        break
      }
      
      // Reject credit cards
      if cardMetadata.cardType == "credit" {
        // return .rejected(message: "Credit cards are not accepted.")
      }
      
      // Otherwise, allow the payment to proceed
      return .accepted
    }
  }
  
  func onTokenized() -> (@Sendable (CheckoutComponents.TokenizationResult) -> CheckoutComponents.CallbackResult)? {
    { [weak self] tokenizationResult in
      guard let self else { return .rejected(message: nil) }
      
      debugPrint("onTokenized: Token: \(tokenizationResult.data)")
      Task { @MainActor in
        self.generatedToken = tokenizationResult.data.token
        self.authenticate3DS(cardToken: tokenizationResult.data.token)
      }
      
      return .accepted
    }
  }
  
  func handleSubmit() -> (@Sendable (CheckoutComponents.SessionData) async -> CheckoutComponents.APICallResult)? {
    guard handleSubmitManually else { return nil }
    
    return { [weak self] submitData in
      guard let self else { return .failure }
      
      debugPrint("handleSubmit: Submit data: \(submitData)")
      
      do {
        let paymentSessionSubmissionResult = try await self.submitPaymentSession(with: submitData)
        return .success(paymentSessionSubmissionResult)
      } catch {
        return .failure
      }
    }
  }
  
  func onSuccess() -> (@Sendable (CheckoutComponents.Describable, CheckoutComponents.PaymentID) -> Void)? {
    { [weak self] paymentMethod, paymentID in
      guard let self else { return }
      
      Task { @MainActor in
        debugPrint("onSuccess: Payment method: \(paymentMethod.name) ....> Payment Id: \(paymentID)")
        self.paymentSucceeded = true
        self.paymentResultText = paymentID
        self.showPaymentResult = true
      }
    }
  }
  
  func onError() -> (@Sendable (CheckoutComponents.Error) -> Void)? {
    { [weak self] error in
      guard let self else { return }
      
      Task { @MainActor in
        debugPrint("onError:  \(error.errorCode.localizedDescription)")
        self.paymentSucceeded = false
        // to avoid dismiss current 3DS challenge and showing every error message on the screen, only showing 3DS challenge that has failed authentication
        guard case let .cardAuthenticationFailed(message) = error.errorCode,
        message == "Authentication failed." else {
          return
        }
        self.paymentSucceeded = false
        self.paymentResultText = error.errorCode.localizedDescription
        self.showPaymentResult = true
      }
    }
  }
}

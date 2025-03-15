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
      onSubmit: { paymentMethod in
        debugPrint("onSubmit: Payment method: \(paymentMethod.name)")
      },
      handleTap: { paymentMethod async -> Bool in
        debugPrint("handleTap: Payment method: \(paymentMethod.name)")
        return true
      },
      onTokenized: { tokenDetails in
        debugPrint("onTokenized: Token: \(tokenDetails.token)")
      },
      onSuccess: { [weak self] paymentMethod, paymentID in
        guard let self else { return }
        
        Task { @MainActor in
          self.handleOnSuccess(paymentMethod, paymentID)
        }
      },
      onError: { [weak self] error in
        guard let self else { return }
        
        Task { @MainActor in
          self.handleOnError(error)
        }
      }
    )
  }
  
  func handleOnSuccess(_ paymentMethod: CheckoutComponents.Actionable, _ paymentId: String) {
    debugPrint("onSuccess: Payment method: \(paymentMethod.name) ....> Payment Id: \(paymentId)")
    paymentSucceeded = true
    paymentID = paymentId
    showPaymentResult = true
  }
  
  func handleOnError(_ error: CheckoutComponents.Error) {
    debugPrint("onError:  \(error.errorCode.localizedDescription)")
    paymentSucceeded = false
    // to avoid dismiss current 3DS challenge and showing every error message on the screen, only showing 3DS challenge that has failed authentication
    guard case let .cardAuthenticationFailed(message) = error.errorCode,
    message == "Authentication failed." else {
      return
    }
    paymentSucceeded = false
    paymentID = error.errorCode.localizedDescription
    showPaymentResult = true
  }
}

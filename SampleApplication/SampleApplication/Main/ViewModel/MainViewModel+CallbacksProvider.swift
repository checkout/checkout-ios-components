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

      onSubmit: { paymentMethod in
        debugPrint("onSubmit: Payment method: \(paymentMethod.name)")
      },

      onTokenized: { tokenDetails in
        debugPrint("onTokenized: Token: \(tokenDetails.token)")
      },

      onSuccess: { [weak self] paymentMethod, paymentID in
        guard let self else { return }
        
        Task { @MainActor in
          debugPrint("onSuccess: Payment method: \(paymentMethod.name) ....> Payment Id: \(paymentID)")
          self.paymentSucceeded = true
          self.paymentResultText = paymentID
          self.showPaymentResult = true
        }
      },

      onError: { [weak self] error in
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
    )
  }
}

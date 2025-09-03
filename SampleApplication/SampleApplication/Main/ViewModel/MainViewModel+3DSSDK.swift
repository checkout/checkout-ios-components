//  Copyright © 2025 Checkout.com. All rights reserved.

import CheckoutComponentsSDK
import Checkout3DS

extension MainViewModel {
  func authenticate3DS(cardToken: String) {
    Task {
      do {
        let accessToken = try await createAccessToken()
        let sessionResponse = try await createSession(with: accessToken, cardToken: cardToken)
        try await authenticateWith3DSSDK(session: sessionResponse)
        try await pay(sessionID: sessionResponse.id, instrumentID: sessionResponse.card.instrumentId)

      } catch {
        print(error)
      }
    }

  }
}

extension MainViewModel {
  func createAccessToken() async throws -> String {
    let result = try await networkLayer.createAccessToken(request: .init())
    return result.accessToken
  }

  func createSession(with accessToken: String, cardToken: String) async throws -> ThreeDSSessionResponse {
    let result = try await networkLayer.createSession(request: .init(currency: currency,
                                                                     amount: amount,
                                                                     source: .init(token: cardToken),
                                                                     completion: .init(),
                                                                     processingChannelId: EnvironmentVars.processingChannelID),
                                                      accessToken: accessToken)

    return result
  }

  func authenticateWith3DSSDK(session: ThreeDSSessionResponse) async throws {

    try await withCheckedThrowingContinuation { continuation in
      checkout3DSSDK.authenticate(authenticationParameters: .init(sessionID: session.id,
                                                                  sessionSecret: session.sessionSecret,
                                                                  scheme: session.scheme)) { result in
        switch result {
        case .success(let authenticationResult):
          print(authenticationResult)
          continuation.resume()

        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func pay(sessionID: String, instrumentID: String) async throws {
    let result = try await networkLayer.pay(request: .init(currency: currency,
                                                           source: .init(id: instrumentID),
                                                           threeDS: .init(authenticationId: sessionID)))

    self.paymentSucceeded = true
    self.paymentResultText = result.id
    self.showPaymentResult = true
  }
}

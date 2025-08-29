//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import Foundation

struct NetworkLayer {
  func createPaymentSession(request: PaymentSessionRequest) async throws -> PaymentSession {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let requestBody = try encoder.encode(request)
    
    // Don't send requests to this API but have a wrapper on your backend to keep your private key safe.
    // Otherwise you would have your private key bundled in your application and get it leaked.
    let url = URL(string: "https://api.sandbox.checkout.com/payment-sessions")!
    
    var request = URLRequest(url: url)
    request.httpBody = requestBody
    request.httpMethod = "POST"
    request.addValue("Bearer " + EnvironmentVars.secretKey, forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    return try decoder.decode(PaymentSession.self, from: data)
  }
  
  func submitPaymentSession(paymentSessionId: String,
                            request: SubmitPaymentSessionRequest) async throws -> CheckoutComponents.PaymentSessionSubmissionResult {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let requestBody = try encoder.encode(request)
    
    // Don't send requests to this API but have a wrapper on your backend to keep your private key safe.
    // Otherwise you would have your private key bundled in your application and get it leaked.
    let url = URL(string: "https://api.sandbox.checkout.com/payment-sessions/\(paymentSessionId)/submit")!
    
    var request = URLRequest(url: url)
    request.httpBody = requestBody
    request.httpMethod = "POST"
    request.addValue("Bearer " + EnvironmentVars.secretKey, forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    if let response = response as? HTTPURLResponse {
      print(response.statusCode)
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    return try decoder.decode(CheckoutComponents.PaymentSessionSubmissionResult.self,
                              from: data)
  }
}

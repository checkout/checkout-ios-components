//  Copyright © 2025 Checkout.com. All rights reserved.

import Foundation

// MARK: Create an access token
extension NetworkLayer {
  func createAccessToken(request: AccessTokenRequest) async throws -> AccessTokenResponse {
    // API reference: https://api-reference.checkout.com/#operation/requestAnAccessToken
    let url = URL(string: "https://access.sandbox.checkout.com/connect/token")!

    let requestBody = request.urlEncodeBody(params: request.dictionary!)

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = requestBody
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: request)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return try decoder.decode(AccessTokenResponse.self, from: data)
  }
}

// MARK: Create a session with the received access token
extension NetworkLayer {
  func createSession(request: ThreeDSSessionRequest, accessToken: String) async throws -> ThreeDSSessionResponse {
    // Don't send requests to this API but have a wrapper on your backend to keep your secret key safe.
    // Otherwise you would have your secret key bundled in your application and get it leaked.
    // API reference: https://api-reference.checkout.com/#operation/createSession
    let url = URL(string: "https://api.sandbox.checkout.com/sessions")!

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let requestBody = try encoder.encode(request)

    var request = URLRequest(url: url)
    request.httpBody = requestBody
    request.httpMethod = "POST"

    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
    let (data, _) = try await URLSession.shared.data(for: request)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(ThreeDSSessionResponse.self, from: data)
  }
}

// MARK: Make the payment with the instrument ID and session ID
extension NetworkLayer {
  func pay(request: PaymentRequest) async throws -> PaymentResponse {
    // API reference: https://api-reference.checkout.com/#operation/requestAPaymentOrPayout
    let url = URL(string: "https://api.sandbox.checkout.com/payments")!

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let requestBody = try encoder.encode(request)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpBody = requestBody
    urlRequest.httpMethod = "POST"

    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.addValue("Bearer " + EnvironmentVars.secretKey, forHTTPHeaderField: "Authorization")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return try decoder.decode(PaymentResponse.self, from: data)
  }
}

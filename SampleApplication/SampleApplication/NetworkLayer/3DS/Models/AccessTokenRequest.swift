//  Copyright © 2025 Checkout.com. All rights reserved.

import Foundation

struct AccessTokenRequest: Encodable {
  let client_id: String = EnvironmentVars.clientID
  let client_secret: String = EnvironmentVars.clientSecret
  let grant_type: String = "client_credentials"

  func urlEncodeBody(params: [String: String]) -> Data? {
    // Just for examplary purposes. Please use your own solution.
    
    var queryParams = URLComponents()
    queryParams.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

    // `URLComponents.percentEncodedQuery` does not encode `+` signs as they are allowed characters. However, if they are not encoded they are interpreted as spaces.
    // Using solution described here https://stackoverflow.com/a/41562036/8331017
    return queryParams.percentEncodedQuery
      .map { $0.replacingOccurrences(of: "+", with: "%2B") }
      .map { Data($0.utf8) }
  }
}

extension Encodable {
  var dictionary: [String: String]? {
    guard let data = try? JSONEncoder().encode(self) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: String] }
  }
}

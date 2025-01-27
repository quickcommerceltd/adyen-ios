//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import Foundation

internal enum DemoServerEnvironment: APIEnvironment {
    
    case beta, test
    
    internal var baseURL: URL {
        switch self {
        case .beta:
            return URL(string: "https://checkout-beta.adyen.com/v66")!
        case .test:
            return URL(string: "https://checkout-test.adyen.com/v66")!
        }
    }
    
    internal var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "X-API-Key": Configuration.demoServerAPIKey
        ]
    }

    /// :nodoc:
    internal var queryParameters: [URLQueryItem] { [] }
}

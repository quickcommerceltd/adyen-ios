//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// A MB Way paymeny method.
public struct MBWayPaymentMethod: PaymentMethod {
    
    /// :nodoc:
    public let type: String
    
    /// :nodoc:
    public let name: String
    
    /// Initializes the MB Way Wallet payment method.
    ///
    /// - Parameter type: The payment method type.
    /// - Parameter name: The payment method name.
    internal init(type: String, name: String) {
        self.type = type
        self.name = name
    }
    
    /// :nodoc:
    public func buildComponent(using builder: PaymentComponentBuilder) -> PaymentComponent? {
        builder.build(paymentMethod: self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case name
    }
}

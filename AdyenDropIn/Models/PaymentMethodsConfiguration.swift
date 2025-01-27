//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
#if canImport(AdyenCard)
    import AdyenCard
#endif
import Foundation
import PassKit

public extension DropInComponent {
    
    /// Contains the configuration for the drop in component and the embedded payment method components.
    final class PaymentMethodsConfiguration {
        
        /// Card component related configuration.
        public var card = CardConfiguration()
        
        /// The Apple Pay configuration.
        public var applePay = ApplePayConfiguration()
        
        /// The client key that corresponds to the webservice user you will use for initiating the payment.
        /// See https://docs.adyen.com/user-management/client-side-authentication for more information.
        public var clientKey: String?
        
        /// The environment to use.
        public var environment: Environment = .live
        
        /// Indicates the localization parameters, leave it nil to use the default parameters.
        public var localizationParameters: LocalizationParameters?
        
        /// Initializes the drop in configuration.
        public init() {}
        
        /// Card component related configuration.
        public final class CardConfiguration {
            
            /// The public key used for encrypting card details.
            @available(*, deprecated, message: "Use PaymentMethodsConfiguration.clientKey instead.")
            public var publicKey: String? {
                get {
                    deprecatedPublicKey
                }
                
                set {
                    deprecatedPublicKey = newValue
                }
            }
            
            /// :nodoc:
            internal var deprecatedPublicKey: String?
            
            /// Indicates if the field for entering the holder name should be displayed in the form. Defaults to false.
            public var showsHolderNameField = false
            
            /// Indicates if the field for storing the card payment method should be displayed in the form. Defaults to true.
            public var showsStorePaymentMethodField = true
            
            /// Indicates whether to show the security code field in the form.
            public var showsSecurityCodeField = true

            /// Indicates if the field for entering the postal code should be displayed in the form. Defaults to false.
            public var showsPostalCodeField = false

            /// Stored card configuration.
            public var stored = StoredCardConfiguration()
            
        }
        
        public final class ApplePayConfiguration {
            
            /// The public key used for encrypting card details.
            public var summaryItems: [PKPaymentSummaryItem]?
            
            /// The merchant identifier for apple pay.
            public var merchantIdentifier: String?
            
            /// A list of fields that you need for a billing contact in order to process the transaction.
            /// Ignored on iOS 10.*.
            public var requiredBillingContactFields: Set<PKContactField> = []
            
            /// A list of fields that you need for a shipping contact in order to process the transaction.
            /// Ignored on iOS 10.*.
            public var requiredShippingContactFields: Set<PKContactField> = []
            
            /// The excluded card brands.
            public var excludedCardNetworks: [PKPaymentNetwork] = []
            
        }
    }
}

public extension DropInComponent.PaymentMethodsConfiguration.CardConfiguration {
    
    /// :nodoc:
    @available(*, deprecated, renamed: "showsHolderNameField")
    var showsHolderName: Bool {
        set {
            showsHolderNameField = newValue
        }
        get {
            showsHolderNameField
        }
    }
}

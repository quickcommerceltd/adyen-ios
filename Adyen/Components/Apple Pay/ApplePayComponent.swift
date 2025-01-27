//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PassKit

/// A component that handles Apple Pay payments.
public class ApplePayComponent: NSObject, PaymentComponent, PresentableComponent, Localizable {
    
    /// Describes the error that can occur during Apple Pay payment.
    public enum Error: Swift.Error, LocalizedError {
        /// Indicates that the user can't make payments on any of the payment request’s supported networks.
        case userCannotMakePayment
        
        /// Indicates that the current device's hardware doesn't support ApplePay.
        case deviceDoesNotSupportApplyPay
        
        /// Indicates that the summaryItems array is empty.
        case emptySummaryItems
        
        /// Indicates that the grand total summary item is a negative value.
        case negativeGrandTotal
        
        /// Indicates that at least one of the summary items has an invalid amount.
        case invalidSummaryItem
        
        /// Indicates that the country code is invalid.
        case invalidCountryCode
        
        /// Indicates that the currency code is invalid.
        case invalidCurrencyCode
        
        /// :nodoc:
        public var errorDescription: String? {
            switch self {
            case .userCannotMakePayment:
                return "The user can’t make payments on any of the payment request’s supported networks."
            case .deviceDoesNotSupportApplyPay:
                return "The current device's hardware doesn't support ApplePay."
            case .emptySummaryItems:
                return "The summaryItems array is empty."
            case .negativeGrandTotal:
                return "The grand total summary item should be greater than or equal to zero."
            case .invalidSummaryItem:
                return "At least one of the summary items has an invalid amount."
            case .invalidCountryCode:
                return "The country code is invalid."
            case .invalidCurrencyCode:
                return "The currency code is invalid."
            }
        }
    }
    
    /// The delegate of the component.
    public weak var delegate: PaymentComponentDelegate?
    
    /// The Apple Pay payment method.
    public let paymentMethod: PaymentMethod
    
    /// The line items for this payment.
    public var summaryItems: [PKPaymentSummaryItem] {
        configuration.summaryItems
    }
    
    /// A list of fields that you need for a billing contact in order to process the transaction.
    /// Ignored on iOS 10.*.
    public var requiredBillingContactFields: Set<PKContactField> {
        configuration.requiredBillingContactFields
    }
    
    /// A list of fields that you need for a shipping contact in order to process the transaction.
    /// Ignored on iOS 10.*.
    public var requiredShippingContactFields: Set<PKContactField> {
        configuration.requiredShippingContactFields
    }
    
    /// The merchant identifier for apple pay.
    private var merchantIdentifier: String {
        configuration.merchantIdentifier
    }
    
    /// Apple Pay component configuration.
    private let configuration: Configuration

    /// Flag to indicate that component wasn't stopped by the merchant's code.
    /// By default all cancelations assumed to be initiated by the user.
    /// :nodoc:
    internal var isUserCancel = true
    
    /// Initializes the component.
    ///
    /// - Warning: `stopLoading()` must be called before dismissing this component.
    ///
    /// - Parameter paymentMethod: The Apple Pay payment method.
    /// - Parameter payment: A description of the payment. Must include an amount and country code.
    /// - Parameter configuration: Apple Pay component configuration.
    /// - Parameter cancelHandler: Being called on cancel, e.g. when the user taps "cancel".
    /// - Throws: `ApplePayComponent.Error.userCannotMakePayment`.
    /// if user can't make payments on any of the payment request’s supported networks.
    /// - Throws: `ApplePayComponent.Error.deviceDoesNotSupportApplyPay` if the current device's hardware doesn't support ApplePay.
    /// - Throws: `ApplePayComponent.Error.emptySummaryItems` if the summaryItems array is empty.
    /// - Throws: `ApplePayComponent.Error.negativeGrandTotal` if the grand total is negative.
    /// - Throws: `ApplePayComponent.Error.invalidSummaryItem` if at least one of the summary items has an invalid amount.
    /// - Throws: `ApplePayComponent.Error.invalidCountryCode` if the `payment.countryCode` is not a valid ISO country code.
    /// - Throws: `ApplePayComponent.Error.invalidCurrencyCode` if the `payment.amount.currencyCode` is not a valid ISO currency code.
    public init(paymentMethod: ApplePayPaymentMethod,
                payment: Payment,
                configuration: Configuration,
                cancelHandler: (() -> Void)? = nil) throws {
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            throw Error.deviceDoesNotSupportApplyPay
        }
        guard PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: configuration.supportedNetworks) else {
            throw Error.userCannotMakePayment
        }
        guard let countryCode = payment.countryCode, CountryCodeValidator().isValid(countryCode) else {
            throw Error.invalidCountryCode
        }
        guard CurrencyCodeValidator().isValid(payment.amount.currencyCode) else {
            throw Error.invalidCurrencyCode
        }
        guard configuration.summaryItems.count > 0 else {
            throw Error.emptySummaryItems
        }
        guard let lastItem = configuration.summaryItems.last, lastItem.amount.doubleValue >= 0 else {
            throw Error.negativeGrandTotal
        }
        guard configuration.summaryItems.filter({ $0.amount.isEqual(to: NSDecimalNumber.notANumber) }).count == 0 else {
            throw Error.invalidSummaryItem
        }
        
        self.paymentMethod = paymentMethod
        self.applePayPaymentMethod = paymentMethod
        self.configuration = configuration
        self.dismissCompletion = cancelHandler
        
        super.init()
        
        self.payment = payment
    }
    
    /// Initializes the component.
    ///
    /// - Warning: `stopLoading()` must be called before dismissing this component.
    ///
    /// - Parameter paymentMethod: The Apple Pay payment method.
    /// - Parameter payment: A description of the payment. Must include an amount and country code.
    /// - Parameter merchantIdentifier: The merchant identifier.
    /// - Parameter summaryItems: The line items for this payment.
    /// - Parameter requiredBillingContactFields:
    /// A list of fields that you need for a billing contact in order to process the transaction. Ignored on iOS 10.*.
    /// - Parameter requiredShippingContactFields:
    /// A list of fields that you need for a shipping contact in order to process the transaction. Ignored on iOS 10.*.
    /// - Parameter cancelHandler: Being called on cancel, e.g. when the user taps "cancel".
    /// - Throws: `ApplePayComponent.Error.userCannotMakePayment`.
    /// if user can't make payments on any of the payment request’s supported networks.
    /// - Throws: `ApplePayComponent.Error.deviceDoesNotSupportApplyPay` if the current device's hardware doesn't support ApplePay.
    /// - Throws: `ApplePayComponent.Error.emptySummaryItems` if the summaryItems array is empty.
    /// - Throws: `ApplePayComponent.Error.negativeGrandTotal` if the grand total is negative.
    /// - Throws: `ApplePayComponent.Error.invalidSummaryItem` if at least one of the summary items has an invalid amount.
    /// - Throws: `ApplePayComponent.Error.invalidCountryCode` if the `payment.countryCode` is not a valid ISO country code.
    /// - Throws: `ApplePayComponent.Error.invalidCurrencyCode` if the `payment.amount.currencyCode` is not a valid ISO currency code.
    @available(*, deprecated, message: "Use init(paymentMethod:payment:configuration:) instead.")
    public convenience init(paymentMethod: ApplePayPaymentMethod,
                            payment: Payment,
                            merchantIdentifier: String,
                            summaryItems: [PKPaymentSummaryItem],
                            requiredBillingContactFields: Set<PKContactField> = [],
                            requiredShippingContactFields: Set<PKContactField> = [],
                            cancelHandler: (() -> Void)? = nil) throws {
        let configuration = Configuration(summaryItems: summaryItems,
                                          merchantIdentifier: merchantIdentifier,
                                          requiredBillingContactFields: requiredBillingContactFields,
                                          requiredShippingContactFields: requiredShippingContactFields)
        try self.init(paymentMethod: paymentMethod, payment: payment, configuration: configuration)
    }
    
    /// Initializes the component.
    ///
    /// - Parameter paymentMethod: The Apple Pay payment method.
    /// - Parameter merchantIdentifier: The merchant identifier.
    /// - Parameter summaryItems: The line items for this payment.
    /// - Parameter cancelHandler: Being called on cancel, e.g. when the user taps "cancel".
    @available(*, deprecated, message: "Use init(paymentMethod:payment:merchantIdentifier:summaryItems:) instead.")
    public init?(paymentMethod: ApplePayPaymentMethod, merchantIdentifier: String, summaryItems: [PKPaymentSummaryItem], cancelHandler: (() -> Void)? = nil) {
        let configuration = Configuration(summaryItems: summaryItems,
                                          merchantIdentifier: merchantIdentifier,
                                          requiredBillingContactFields: [],
                                          requiredShippingContactFields: [])
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            adyenPrint("Failed to instantiate ApplePayComponent. PKPaymentAuthorizationViewController.canMakePayments returned false.")
            return nil
        }
        guard PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: configuration.supportedNetworks) else {
            // swiftlint:disable:next line_length
            adyenPrint("Failed to instantiate ApplePayComponent. PKPaymentAuthorizationViewController.canMakePayments(usingNetworks:) returned false.")
            return nil
        }
        
        self.paymentMethod = paymentMethod
        self.applePayPaymentMethod = paymentMethod
        self.configuration = configuration
        self.dismissCompletion = cancelHandler
    }
    
    internal let applePayPaymentMethod: ApplePayPaymentMethod
    
    // MARK: - Presentable Component Protocol
    
    /// :nodoc:
    public var viewController: UIViewController {
        getPaymentAuthorizationViewController() ?? errorAlertController
    }
    
    /// :nodoc:
    public var localizationParameters: LocalizationParameters?
    
    /// :nodoc:
    public func stopLoading(withSuccess success: Bool, completion: (() -> Void)?) {
        isUserCancel = false
        paymentAuthorizationCompletion?(success ? .success : .failure)
        dismiss(callback: completion)
    }
    
    // MARK: - Private
    
    internal var paymentAuthorizationCompletion: ((PKPaymentAuthorizationStatus) -> Void)?
    
    internal var dismissCompletion: (() -> Void)?
    
    private lazy var errorAlertController: UIAlertController = {
        let alertController = UIAlertController(title: ADYLocalizedString("adyen.error.title", localizationParameters),
                                                message: ADYLocalizedString("adyen.error.unknown", localizationParameters),
                                                preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: ADYLocalizedString("adyen.dismissButton", localizationParameters),
                                          style: .default) { [weak self] _ in
            self?.handle(
                UnknownError(
                    errorDescription: "Failed to instantiate PKPaymentAuthorizationViewController because of unknown error"
                )
            )
        }
        alertController.addAction(dismissAction)
        return alertController
    }()
    
    internal var paymentAuthorizationViewController: PKPaymentAuthorizationViewController?
    
    private func getPaymentAuthorizationViewController() -> PKPaymentAuthorizationViewController? {
        if paymentAuthorizationViewController == nil {
            paymentAuthorizationViewController = newPaymentAuthorizationViewController()
            isUserCancel = true
        }
        return paymentAuthorizationViewController
    }
    
    private func newPaymentAuthorizationViewController() -> PKPaymentAuthorizationViewController? {
        guard let paymentAuthorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: createPaymentRequest()) else {
            adyenPrint("Failed to instantiate PKPaymentAuthorizationViewController.")
            return nil
        }
        paymentAuthorizationViewController.delegate = self
        
        return paymentAuthorizationViewController
    }
    
    internal func createPaymentRequest() -> PKPaymentRequest {
        let paymentRequest = PKPaymentRequest()
        
        paymentRequest.countryCode = payment?.countryCode ?? ""
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.currencyCode = payment?.amount.currencyCode ?? ""
        paymentRequest.supportedNetworks = configuration.supportedNetworks
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.paymentSummaryItems = summaryItems
        
        if #available(iOS 11.0, *) {
            paymentRequest.requiredBillingContactFields = requiredBillingContactFields
            paymentRequest.requiredShippingContactFields = requiredShippingContactFields
        }
        
        return paymentRequest
    }
    
    private func handle(_ error: Swift.Error) {
        delegate?.didFail(with: error, from: self)
    }

    internal func dismiss(callback: (() -> Void)? = nil) {
        func dismiss(_ callback: (() -> Void)? = nil) {
            callback?()
            self.dismissCompletion?()
            self.dismissCompletion = nil
        }

        guard let viewController = paymentAuthorizationViewController else {
            return dismiss(callback)
        }

        viewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.paymentAuthorizationViewController = nil
            dismiss(callback)
        }
    }
}

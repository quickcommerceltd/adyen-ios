//
// Copyright (c) 2019 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import Adyen
import PassKit
import XCTest

class ApplePayComponentTest: XCTestCase {

    var mockDelegate: PaymentComponentDelegateMock!
    var sut: ApplePayComponent!

    override func setUp() {
        let paymentMethod = ApplePayPaymentMethod(type: "test_type", name: "test_name")
        let amount = Payment.Amount(value: 2, currencyCode: getRandomCurrencyCode())
        let payment = Payment(amount: amount, countryCode: getRandomCountryCode())
        let configuration = ApplePayComponent.Configuration(summaryItems: createTestSummaryItems(), merchantIdentifier: "test_id")
        sut = try? ApplePayComponent(paymentMethod: paymentMethod, payment: payment, configuration: configuration)
        mockDelegate = PaymentComponentDelegateMock()
        sut.delegate = mockDelegate
    }

    override func tearDown() {
        sut = nil
        mockDelegate = nil
    }
    
    func testApplePayViewControllerIsResetAfterComponentStopsLoading() {
        let onDidFailExpectation = expectation(description: "Wait for delegate call")

        let viewController = sut!.viewController
        UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: UIViewController())
        UIApplication.shared.keyWindow?.rootViewController?.present(viewController, animated: true) {
            self.sut?.stopLoading(withSuccess: false) {
                onDidFailExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
        XCTAssertTrue(viewController !== sut?.viewController)
    }

    func testApplePayViewControllerRemainsInMemoryIfViewControlerDismissed() {
        let onDidFailExpectation = expectation(description: "Wait for delegate call")

        let viewController = sut!.viewController
        UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: UIViewController())
        UIApplication.shared.keyWindow?.rootViewController?.present(viewController, animated: true) {
            viewController.dismiss(animated: true) {
                onDidFailExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
        XCTAssertTrue(viewController === sut?.viewController)
    }

    func testApplePayViewControllerCallsDelgateDidFail() {
        let viewController = sut?.viewController
        let onDidFailExpectation = expectation(description: "Wait for delegate call")
        mockDelegate.onDidFail = { error, component in
            XCTAssertEqual(error as! ComponentError, ComponentError.cancelled)
            onDidFailExpectation.fulfill()
        }
        sut.paymentAuthorizationViewControllerDidFinish(viewController as! PKPaymentAuthorizationViewController)
        waitForExpectations(timeout: 2)
    }

    func testApplePayViewControllerDoNotCallsDelgateDidFailWhenStopLoadingComponent() {
        let viewController = sut!.viewController
        let onDidFailExpectation = expectation(description: "Wait for delegate call")
        mockDelegate.onDidFail = { error, component in
            XCTFail("Should not call delegate")
        }

        UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: UIViewController())
        UIApplication.shared.keyWindow?.rootViewController?.present(viewController, animated: true)

        sut.stopLoading(withSuccess: true) { onDidFailExpectation.fulfill() }
        sut.paymentAuthorizationViewControllerDidFinish(viewController as! PKPaymentAuthorizationViewController)

        waitForExpectations(timeout: 5)
    }
    
    func testApplePayViewControllerIsResetAfterAuthorization() {
        let viewController = sut!.viewController

        let stopLoadingExpectation = expectation(description: "Expect the applePayComponent to be dimissed.")

        UIApplication.shared.keyWindow?.rootViewController?.adyen.topPresenter.present(viewController, animated: true) {
            XCTAssertNotNil(viewController as? PKPaymentAuthorizationViewController)
            self.sut!.paymentAuthorizationViewController(viewController as! PKPaymentAuthorizationViewController, didAuthorizePayment: PKPayment(), completion: { _ in })
            self.sut!.stopLoading(withSuccess: true) {
                XCTAssertTrue(viewController !== self.sut?.viewController)
                stopLoadingExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testInvalidCurrencyCode() {
        let paymentMethod = ApplePayPaymentMethod(type: "test_type", name: "test_name")
        let amount = Payment.Amount(value: 2, currencyCode: "wqedf")
        let payment = Payment(amount: amount, countryCode: getRandomCountryCode())
        let configuration = ApplePayComponent.Configuration(summaryItems: createTestSummaryItems(), merchantIdentifier: "test_id")
        XCTAssertThrowsError(try ApplePayComponent(paymentMethod: paymentMethod, payment: payment, configuration: configuration)) { error in
            XCTAssertTrue(error is ApplePayComponent.Error)
            XCTAssertEqual(error as! ApplePayComponent.Error, ApplePayComponent.Error.invalidCurrencyCode)
            XCTAssertEqual((error as! ApplePayComponent.Error).localizedDescription, "The currency code is invalid.")
        }
    }
    
    func testInvalidCountryCode() {
        let paymentMethod = ApplePayPaymentMethod(type: "test_type", name: "test_name")
        let amount = Payment.Amount(value: 2, currencyCode: getRandomCurrencyCode())
        let payment = Payment(amount: amount, countryCode: "asda")
        let configuration = ApplePayComponent.Configuration(summaryItems: createTestSummaryItems(), merchantIdentifier: "test_id")
        XCTAssertThrowsError(try ApplePayComponent(paymentMethod: paymentMethod, payment: payment, configuration: configuration)) { error in
            XCTAssertTrue(error is ApplePayComponent.Error)
            XCTAssertEqual(error as! ApplePayComponent.Error, ApplePayComponent.Error.invalidCountryCode)
            XCTAssertEqual((error as! ApplePayComponent.Error).localizedDescription, "The country code is invalid.")
        }
    }
    
    func testEmptySummaryItems() {
        let paymentMethod = ApplePayPaymentMethod(type: "test_type", name: "test_name")
        let amount = Payment.Amount(value: 2, currencyCode: getRandomCurrencyCode())
        let payment = Payment(amount: amount, countryCode: getRandomCountryCode())
        let configuration = ApplePayComponent.Configuration(summaryItems: [], merchantIdentifier: "test_id")
        XCTAssertThrowsError(try ApplePayComponent(paymentMethod: paymentMethod, payment: payment, configuration: configuration)) { error in
            XCTAssertTrue(error is ApplePayComponent.Error)
            XCTAssertEqual(error as! ApplePayComponent.Error, ApplePayComponent.Error.emptySummaryItems)
            XCTAssertEqual((error as! ApplePayComponent.Error).localizedDescription, "The summaryItems array is empty.")
        }
    }
    
    func testGrandTotalIsNegative() {
        let paymentMethod = ApplePayPaymentMethod(type: "test_type", name: "test_name")
        let amount = Payment.Amount(value: 2, currencyCode: getRandomCurrencyCode())
        let payment = Payment(amount: amount, countryCode: getRandomCountryCode())
        let configuration = ApplePayComponent.Configuration(summaryItems: createInvalidGrandTotalTestSummaryItems(), merchantIdentifier: "test_id")
        XCTAssertThrowsError(try ApplePayComponent(paymentMethod: paymentMethod, payment: payment, configuration: configuration)) { error in
            XCTAssertTrue(error is ApplePayComponent.Error)
            XCTAssertEqual(error as! ApplePayComponent.Error, ApplePayComponent.Error.negativeGrandTotal)
            XCTAssertEqual((error as! ApplePayComponent.Error).localizedDescription, "The grand total summary item should be greater than or equal to zero.")
        }
    }
    
    func testOneItemWithZeroAmount() {
        let paymentMethod = ApplePayPaymentMethod(type: "test_type", name: "test_name")
        let amount = Payment.Amount(value: 2, currencyCode: getRandomCurrencyCode())
        let payment = Payment(amount: amount, countryCode: getRandomCountryCode())
        let configuration = ApplePayComponent.Configuration(summaryItems: createTestSummaryItemsWithZeroAmount(), merchantIdentifier: "test_id")
        XCTAssertThrowsError(try ApplePayComponent(paymentMethod: paymentMethod, payment: payment, configuration: configuration)) { error in
            XCTAssertTrue(error is ApplePayComponent.Error)
            XCTAssertEqual(error as! ApplePayComponent.Error, ApplePayComponent.Error.invalidSummaryItem)
            XCTAssertEqual((error as! ApplePayComponent.Error).localizedDescription, "At least one of the summary items has an invalid amount.")
        }
    }
    
    func testRequiresModalPresentation() {
        XCTAssertEqual(sut?.requiresModalPresentation, false)
    }
    
    func testPresentationViewControllerValidPayment() {
        XCTAssertTrue(sut?.viewController is PKPaymentAuthorizationViewController)
    }
    
    func testPaymentRequest() {
        let paymentMethod = ApplePayPaymentMethod(type: "test_type", name: "test_name")
        let countryCode = getRandomCountryCode()
        let amount = Payment.Amount(value: 2, currencyCode: getRandomCurrencyCode())
        let payment = Payment(amount: amount, countryCode: countryCode)
        let expectedSummaryItems = createTestSummaryItems()
        let expectedRequiredBillingFields = getRandomContactFieldSet()
        let expectedRequiredShippingFields = getRandomContactFieldSet()
        let configuration = ApplePayComponent.Configuration(summaryItems: expectedSummaryItems,
                                                            merchantIdentifier: "test_id",
                                                            requiredBillingContactFields: expectedRequiredBillingFields,
                                                            requiredShippingContactFields: expectedRequiredShippingFields,
                                                            excludedCardNetworks: [.visa])
        let sut = try? ApplePayComponent(paymentMethod: paymentMethod,
                                         payment: payment,
                                         configuration: configuration)
        let paymentRequest = sut!.createPaymentRequest()
        XCTAssertEqual(paymentRequest.paymentSummaryItems, expectedSummaryItems)
        XCTAssertEqual(paymentRequest.merchantCapabilities, PKMerchantCapability.capability3DS)
        XCTAssertEqual(paymentRequest.supportedNetworks, self.supportedNetworks.filter { $0 != .visa })
        XCTAssertEqual(paymentRequest.currencyCode, amount.currencyCode)
        XCTAssertEqual(paymentRequest.merchantIdentifier, "test_id")
        XCTAssertEqual(paymentRequest.countryCode, countryCode)
        if #available(iOS 11.0, *) {
            XCTAssertEqual(paymentRequest.requiredBillingContactFields, expectedRequiredBillingFields)
            XCTAssertEqual(paymentRequest.requiredShippingContactFields, expectedRequiredShippingFields)
        }
    }
    
    private func getRandomCurrencyCode() -> String {
        NSLocale.isoCurrencyCodes.randomElement() ?? "EUR"
    }
    
    private func getRandomCountryCode() -> String {
        NSLocale.isoCountryCodes.randomElement() ?? "DE"
    }
    
    private func getRandomContactFieldSet() -> Set<PKContactField> {
        if #available(iOS 11.0, *) {
            let contactFieldsPool: [PKContactField] = [.emailAddress, .name, .phoneNumber, .postalAddress, .phoneticName]
            return contactFieldsPool.randomElement().map { [$0] } ?? []
        } else {
            return []
        }
    }
    
    private func createTestSummaryItems() -> [PKPaymentSummaryItem] {
        var amounts = (0...3).map { _ in
            NSDecimalNumber(mantissa: UInt64.random(in: 1...20), exponent: 1, isNegative: Bool.random())
        }
        // Positive Grand total
        amounts.append(NSDecimalNumber(mantissa: 20, exponent: 1, isNegative: false))
        return amounts.enumerated().map {
            PKPaymentSummaryItem(label: "summary_\($0)", amount: $1)
        }
    }
    
    private func createInvalidGrandTotalTestSummaryItems() -> [PKPaymentSummaryItem] {
        var amounts = (0...3).map { _ in
            NSDecimalNumber(mantissa: UInt64.random(in: 1...20), exponent: 1, isNegative: Bool.random())
        }
        // Negative Grand total
        amounts.append(NSDecimalNumber(mantissa: 20, exponent: 1, isNegative: true))
        return amounts.enumerated().map {
            PKPaymentSummaryItem(label: "summary_\($0)", amount: $1)
        }
    }
    
    private func createTestSummaryItemsWithZeroAmount() -> [PKPaymentSummaryItem] {
        var items = createTestSummaryItems()
        let amount = NSDecimalNumber(mantissa: 0, exponent: 1, isNegative: true)
        let item = PKPaymentSummaryItem(label: "summary_zero_value", amount: amount)
        items.insert(item, at: 0)
        return items
    }
    
    private var supportedNetworks: [PKPaymentNetwork] {
        var networks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .discover, .interac]
        
        if #available(iOS 12.0, *) {
            networks.append(.maestro)
        }

        if #available(iOS 10.1, *) {
            networks.append(.JCB)
        }
        
        return networks
    }
}

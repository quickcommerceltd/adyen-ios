//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import UIKit

/// Describes any entity that is UI localizable.
public protocol Localizable {
    
    /// Indicates the localization parameters, leave it nil to use the default parameters.
    var localizationParameters: LocalizationParameters? { get set }
}

/// :nodoc:
/// Represents any object than can handle a cancel event.
public protocol Cancellable {
    
    /// :nodoc:
    /// Called when the user cancels the component.
    func didCancel()
}

/// A component that provides a view controller for the shopper to fill payment details.
public protocol PresentableComponent: Component, Cancellable {
    
    /// The payment information.
    var payment: Payment? { get set }
    
    /// Indicates whether `viewController` expected to be presented modally,
    /// hence it can not handle it's own presentation and dismissal.
    var requiresModalPresentation: Bool { get }
    
    /// Returns a view controller that presents the payment details for the shopper to fill.
    var viewController: UIViewController { get }
    
    /// Stops any processing animation that the view controller is running.
    ///
    /// - Parameters:
    ///   - success: Boolean indicating the component should go to a success or failure state.
    ///   - completion: Completion block to be called when animations are finished.
    func stopLoading(withSuccess success: Bool, completion: (() -> Void)?)
}

public extension PresentableComponent {

    /// :nodoc:
    var payment: Payment? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.payment) as? Payment
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.payment, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY)
        }
    }
    
    /// :nodoc:
    var requiresModalPresentation: Bool { false }
    
    /// Stops any processing animation that the view controller is running.
    func stopLoading() {
        stopLoading(withSuccess: true, completion: nil)
    }
    
    /// Stops any processing animation that the view controller is running.
    ///
    /// - Parameters:
    ///   - success: Boolean indicating the component should go to a success or failure state.
    func stopLoading(withSuccess success: Bool) {
        stopLoading(withSuccess: success, completion: nil)
    }
    
    /// Stops any processing animation that the view controller is running.
    ///
    /// - Parameters:
    ///   - success: Boolean indicating the component should go to a success or failure state.
    ///   - completion: Completion block to be called when animations are finished.
    func stopLoading(withSuccess success: Bool, completion: (() -> Void)?) {
        completion?()
    }
    
    /// Notifies the component that the user has dismissed it.
    func didCancel() {}
    
}

private enum AssociatedKeys {

    internal static var payment = "paymentObject"
}

//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import UIKit

/// An error that occured during the use of QRCodeComponent
internal enum QRCodeComponentError: LocalizedError {
    /// Indicates the QR code is not longer valid
    case qrCodeExpired
    
    public var errorDescription: String? {
        "QR code is no longer valid"
    }
}

/// A component that presents a QR code.
internal final class QRCodeComponent: ActionComponent, Localizable, Cancellable {
    
    /// Delegates `ViewController`'s presentation.
    public weak var presentationDelegate: PresentationDelegate?
    
    /// The component UI style.
    public let style: QRCodeComponentStyle

    /// :nodoc:
    public weak var delegate: ActionComponentDelegate?
    
    /// :nodoc:
    public var action: QRCodeAction?
    
    /// :nodoc:
    public var localizationParameters: LocalizationParameters?
    
    /// Initializes the `QRCodeComponent`.
    ///
    /// - Parameter style: The component UI style.
    public convenience init(style: QRCodeComponentStyle?) {
        self.init(
            style: style ?? QRCodeComponentStyle(),
            pollingComponentBuilder: nil,
            timeoutInterval: 60 * 15
        )
    }
    
    /// Initializes the `QRCodeComponent`.
    ///
    /// - Parameter style: The component UI style.
    /// - Parameter pollingComponentBuilder: The payment method specific await action handler provider.
    /// - Parameter timeoutInterval: QR Code expiration timeout
    internal init(style: QRCodeComponentStyle = QRCodeComponentStyle(),
                  pollingComponentBuilder: AnyPollingHandlerProvider?,
                  timeoutInterval: TimeInterval) {
        self.style = style
        self.pollingComponentBuilder = pollingComponentBuilder
        self.expirationTimeout = timeoutInterval
        
        updateExpiration(timeoutInterval)
    }
    
    /// Handles QR code action.
    ///
    /// - Parameter action: The QR code action.
    public func handle(_ action: QRCodeAction) {
        self.action = action
        
        let pollingComponentBuilder = self.pollingComponentBuilder ?? PollingHandlerProvider(environment: environment, apiClient: nil)
        
        let pollingComponent = pollingComponentBuilder.handler(for: action.paymentMethodType)
        pollingComponent.delegate = self
        
        assert(presentationDelegate != nil)
        
        presentationDelegate?.present(
            component: PresentableComponentWrapper(
                component: self, viewController: createViewController(with: action))
        )
        
        startTimer()
        
        pollingComponent.handle(action)
    }
    
    /// :nodoc:
    private var pollingComponentBuilder: AnyPollingHandlerProvider?
    
    /// :nodoc:
    private var pollingComponent: AnyPollingHandler?
    
    /// :nodoc:
    private var timeoutTimer: ExpirationTimer?
    
    /// :nodoc
    private let progress: Progress = Progress()
    
    /// :nodoc:
    @Observable(nil) private var expirationText: String?
    
    /// :nodoc:
    private let expirationTimeout: TimeInterval
    
    /// :nodoc
    private func startTimer() {
        let unitCount = Int64(expirationTimeout)
        progress.totalUnitCount = unitCount
        progress.completedUnitCount = unitCount
        
        timeoutTimer = ExpirationTimer(
            expirationTimeout: self.expirationTimeout,
            onTick: { [weak self] in self?.updateExpiration($0) },
            onExpiration: { [weak self] in self?.onTimerTimeout() })
        timeoutTimer?.startTimer()
    }
    
    /// :nodoc:
    private func updateExpiration(_ timeLeft: TimeInterval) {
        progress.completedUnitCount = Int64(timeLeft)
        let timeLeftString = timeLeft.adyen.timeLeftString() ?? ""
        expirationText = ADYLocalizedString("adyen.pix.expirationLabel", localizationParameters, timeLeftString)
    }
    
    /// :nodoc:
    private func onTimerTimeout() {
        cleanup()
        
        delegate?.didFail(with: QRCodeComponentError.qrCodeExpired, from: self)
    }
    
    /// :nodoc:
    private func createViewController(with action: QRCodeAction) -> UIViewController {
        let view = QRCodeView(model: createModel(with: action))
        view.delegate = self
        return QRCodeViewController(qrCodeView: view)
    }
    
    /// :nodoc:
    private func createModel(with action: QRCodeAction) -> QRCodeView.Model {
        let url = LogoURLProvider.logoURL(withName: "pix", environment: .test)
        return QRCodeView.Model(
            instruction: ADYLocalizedString("adyen.pix.instructions", localizationParameters),
            logoUrl: url,
            observedProgress: progress,
            expiration: $expirationText,
            style: QRCodeView.Model.Style(
                copyButton: style.copyButton,
                instructionLabel: style.instructionLabel,
                progressView: style.progressView,
                expirationLabel: style.expirationLabel,
                backgroundColor: style.backgroundColor
            )
        )
    }
    
    /// :nodoc:
    public func didCancel() {
        cleanup()
    }
    
    /// :nodoc:
    fileprivate func cleanup() {
        timeoutTimer?.stopTimer()
        pollingComponent?.didCancel()
    }
}

extension QRCodeComponent: ActionComponentDelegate {
    
    func didProvide(_ data: ActionComponentData, from component: ActionComponent) {
        cleanup()
        delegate?.didProvide(data, from: self)
    }
    
    func didComplete(from component: ActionComponent) { }
    
    func didFail(with error: Error, from component: ActionComponent) {
        cleanup()
        delegate?.didFail(with: error, from: self)
    }
    
}

extension QRCodeComponent: QRCodeViewDelegate {
    
    func copyToPasteboard() {
        UIPasteboard.general.string = action.map(\.qrCodeData)
    }
    
}
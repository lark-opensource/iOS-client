//
//  DefaultInterceptor.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/12.
//

import UIKit
import Foundation
import LKCommonsLogging

final class DefaultInterceptor: LarkMagicInterceptor {
    static let logger = Logger.log(DefaultInterceptor.self, category: "LarkMagic")

    private var isForeground = UIApplication.shared.applicationState == .active
    private var isKeyboardShowing = false

    init() {
        registerObservers()
    }

    func canShowMagic() -> Bool {
        return isForeground && !isKeyboardShowing
    }

    func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onKeyboardShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onKeyboardHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterForeground),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc
    private func onKeyboardShow() {
        isKeyboardShowing = true
        DefaultInterceptor.logger.info("keyboard show")
    }

    @objc
    private func onKeyboardHide() {
        isKeyboardShowing = false
        DefaultInterceptor.logger.info("keyboard hide")
    }

    @objc
    private func appDidEnterForeground() {
        isForeground = true
        DefaultInterceptor.logger.info("app did enter foreground")
    }

    @objc
    private func appDidEnterBackground() {
        isForeground = false
        DefaultInterceptor.logger.info("app did enter background")
    }
}

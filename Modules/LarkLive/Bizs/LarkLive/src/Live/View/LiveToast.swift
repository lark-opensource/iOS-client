//
//  LarkLiveToast.swift
//  LarkLive
//
//  Created by lvdaqian on 2021/6/10.
//

import Foundation
import UniverseDesignToast
import LarkSceneManager

public struct LiveToast {

    let view: UIView

    init(_ base: UIView) {
        self.view = base
    }

    ///获取当前的window
    static var currentWindow: UIWindow? {
        var current: UIWindow?
        let windows = UIApplication.shared.windows
        for window: UIWindow in windows {
            let windowOnMainScreen: Bool = window.screen == UIScreen.main
            let windowIsVisible: Bool = !window.isHidden && window.alpha > 0
            let windowLevelNormal: Bool = window.windowLevel == .normal
            if windowOnMainScreen && windowIsVisible && windowLevelNormal {
                current = window
                break
            }
        }
        return current
    }

    /// common text toast shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    public func showTips(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) -> UniverseDesignToast.UDToast {
        return UDToast.showTips(with: text, operationText: operationText, on: view, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    public static func showTips(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) -> UniverseDesignToast.UDToast? {
        guard let view = currentWindow else { return nil }
        return UDToast.showTips(with: text, operationText: operationText, on: view, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    /// failure toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    public func showFailure(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) -> UniverseDesignToast.UDToast {
        return UDToast.showFailure(with: text, operationText: operationText, on: view, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    public static func showFailure(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) -> UniverseDesignToast.UDToast? {
        guard let view = currentWindow else { return nil }
        return UDToast.showFailure(with: text, operationText: operationText, on: view, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    /// success toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    public func showSuccess(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) -> UniverseDesignToast.UDToast {
        view.rx
        return UDToast.showSuccess(with: text, operationText: operationText, on: view, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    public static func showSuccess(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) -> UniverseDesignToast.UDToast? {
        guard let view = currentWindow else { return nil }
        return UDToast.showSuccess(with: text, operationText: operationText, on: view, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

}

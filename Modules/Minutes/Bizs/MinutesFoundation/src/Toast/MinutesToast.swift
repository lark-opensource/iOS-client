//
//  MinutesToast.swift
//  Minutes
//
//  Created by lvdaqian on 2021/6/10.
//

import Foundation
import UniverseDesignToast
import LarkSceneManager
import EENavigator

// TODO Navigator
public struct MinutesToast {
    /// common text toast shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    public static func showTips(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, targetView: UIView?, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) {
        guard let targetView = targetView else { return }
        
        UDToast.showTips(with: text, operationText: operationText, on: targetView, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    /// failure toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    public static func showFailure(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, targetView: UIView?, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) {
        guard let targetView = targetView else { return }
        
        UDToast.showFailure(with: text, operationText: operationText, on: targetView, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    /// success toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    public static func showSuccess(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, targetView: UIView?, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) {
        guard let targetView = targetView else { return }
        
        UDToast.showSuccess(with: text, operationText: operationText, on: targetView, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }

    /// warn toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    public static func showWarning(with text: String, operationText: String? = nil, delay: TimeInterval = 3.0, targetView: UIView?, operationCallBack: ((String?) -> Void)? = nil, dismissCallBack: (() -> Void)? = nil) {
        guard let targetView = targetView else { return }
        
        UDToast.showWarning(with: text, operationText: operationText, on: targetView, delay: delay, operationCallBack: operationCallBack, dismissCallBack: dismissCallBack)
    }
}

//
//  UDToast+Extension.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/18.
//

import UIKit
import Foundation
import LarkSDKInterface
import UniverseDesignToast

extension UDToast {

    class func autoDismissSuccess(_ text: String, on view: UIView) {
        let toast = showSuccess(with: text, on: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            toast.remove()
        }
    }

    class func autoDismissFailure(_ text: String, error: Error? = nil, on view: UIView) {
        var toast: UDToast
        if let error = error?.transformToAPIError() {
            toast = showFailure(with: text, on: view, error: error)
        } else {
            toast = showFailure(with: text, on: view)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            toast.remove()
        }
    }

    class func autoDismissWarning(_ text: String, on view: UIView) {
        let toast = showWarning(with: text, on: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            toast.remove()
        }
    }

    class func autoDismissTips(_ text: String, on view: UIView) {
        let toast = showTips(with: text, on: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            toast.remove()
        }
    }

    class func loading(_ text: String?, on view: UIView) -> UDToast {
        if let text = text {
            return showLoading(with: text, on: view)
        } else {
            return showDefaultLoading(on: view)
        }
    }

    class func showSavingLoading(on view: UIView, disableUserInteraction: Bool = true) -> UDToast {
        return showLoading(with: BundleI18n.LarkFocus.Lark_Profile_Saving, on: view, disableUserInteraction: disableUserInteraction)
    }
}

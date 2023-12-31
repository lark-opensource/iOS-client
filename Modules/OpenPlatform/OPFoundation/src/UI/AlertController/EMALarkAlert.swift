//
//  EMALarkAlert.swift
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2020/4/8.
//

import UIKit
import LarkAlertController
import EENavigator
import OPFoundation
import LKCommonsLogging

// 对LarkAlertController的封装，支持在OC下使用

private let logger = Logger.log(EMALarkAlert.self, category: "EMALarkAlert")

@objcMembers
public final class EMALarkAlert: NSObject {
    /// 展示弹窗
    /// - Parameters:
    ///   - title: 标题
    ///   - content: 内容
    ///   - confirm: 确定按钮文案
    ///   - confirmCallback: 确定按钮回调
    ///   - showCancel: 是否展示取消按钮
    public class func showAlert(
        title: String,
        content: String? = nil,
        confirm: String,
        fromController: UIViewController?,
        confirmCallback:(() -> Void)? = nil,
        showCancel: Bool = true
    ) -> LarkAlertController {
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.addPrimaryButton(text: confirm, dismissCompletion: confirmCallback)
        if let c = content {
            alertController.setContent(
                text: c,
                color: UIColor.ud.N900,
                font: UIFont.systemFont(ofSize: 16),
                alignment: .center,
                lineSpacing: 0,
                numberOfLines: 0
            )
        }
        if showCancel {
            alertController.addCancelButton()
        }
        if let from = fromController ?? OPNavigatorHelper.topMostVC(window: fromController?.view.window) {
            Navigator.shared.present(alertController, from: from) // Global
        } else {
            logger.error("showAlert but from is nil")
        }
        return alertController
    }

    public class func showAlert(
        title: String,
        content: String? = nil,
        confirm: String,
        fromController: UIViewController?,
        numberOfLines: Int = 1,
        confirmCallback:(() -> Void)? = nil,
        cancelCallback:(() -> Void)? = nil
    ) -> LarkAlertController {
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        if let cancelCallback = cancelCallback {
            // 跟随EMAAlertController的样式 cancel在左，confirm在右
            alertController.addCancelButton(dismissCompletion: cancelCallback)
        }
        alertController.addPrimaryButton(text: confirm, dismissCompletion: confirmCallback)
        if let c = content {
            alertController.setContent(
                text: c,
                color: UIColor.ud.N900,
                font: UIFont.systemFont(ofSize: 16),
                alignment: .center,
                lineSpacing: 0,
                numberOfLines: numberOfLines
            )
        }
        if let from = fromController ?? OPNavigatorHelper.topMostVC(window: fromController?.view.window) {
            Navigator.shared.present(alertController, from: from) // Global
        } else {
            logger.error("showAlert but from is nil")
        }
        return alertController
    }

}

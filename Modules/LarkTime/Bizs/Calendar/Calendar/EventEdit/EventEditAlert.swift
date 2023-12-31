//
//  EventEditAlert.swift
//  Calendar
//
//  Created by 张威 on 2020/4/25.
//

import UIKit
import Foundation
import UniverseDesignDialog

// Texts for Confirm Alert Controller
struct EventEditConfirmAlertTexts {
    var title: String?
    var message: String?
    var confirmText: String = BundleI18n.Calendar.Calendar_Common_Confirm
    var cancelText: String? = BundleI18n.Calendar.Calendar_Common_Cancel
}

// Texts and Handlers for Confirm Alert Controller
struct EventEditConfirmAlert {

    typealias ActionHandler = () -> Void

    var texts: EventEditConfirmAlertTexts
    var confirmHandler: ActionHandler
    var cancelHandler: ActionHandler?
}

protocol EventEditConfirmAlertSupport: UIViewController {  }

extension EventEditConfirmAlertSupport {

    typealias AlertActionHandler = () -> Void

    /// 展示 Alert 弹窗
    ///
    /// - Parameters:
    ///   - title: title
    ///   - message: message
    ///   - confirmText: title for confirm action
    ///   - cancelText: 取消标题，可为空（不展示 cancel 按钮）
    ///   - confirmHandler: confirm handler
    ///   - cancelHandler: cancel handler
    func showConfirmAlertController(
        title: String? = nil,
        message: String? = nil,
        confirmText: String = BundleI18n.Calendar.Calendar_Common_Confirm,
        cancelText: String? = BundleI18n.Calendar.Calendar_Common_Cancel,
        confirmHandler: AlertActionHandler?,
        cancelHandler: AlertActionHandler?
    ) {
        let alertVC = UDDialog(config: UDDialogUIConfig())
        if let title = title {
            alertVC.setTitle(text: title)
        }
        if let message = message {
            alertVC.setContent(text: message)
        }
        if let cancelText = cancelText, !cancelText.isEmpty {
            alertVC.addSecondaryButton(text: cancelText) {
                cancelHandler?()
            }
        }
        alertVC.addPrimaryButton(text: confirmText) {
            confirmHandler?()
        }
        present(alertVC, animated: true, completion: nil)
    }

    /// 展示 Alert 弹窗
    ///
    /// - Parameters:
    ///   - texts: alert 文案
    ///   - confirmHandler: 确认点击响应 handler
    ///   - cancelHandler: 取消点击响应 handler
    func showConfirmAlertController(
        texts: EventEditConfirmAlertTexts,
        confirmHandler: AlertActionHandler? = nil,
        cancelHandler: AlertActionHandler? = nil
    ) {
        showConfirmAlertController(
            title: texts.title,
            message: texts.message,
            confirmText: texts.confirmText,
            cancelText: texts.cancelText,
            confirmHandler: confirmHandler,
            cancelHandler: cancelHandler
        )
    }

    /// 展示 Alert 弹窗
    ///
    /// - Parameter alert: 为 alert 弹窗提供的 context 信息
    func showConfirmAlertController(_ alert: EventEditConfirmAlert) {
        showConfirmAlertController(
            texts: alert.texts,
            confirmHandler: alert.confirmHandler,
            cancelHandler: alert.cancelHandler
        )
    }

    func showConfirmAlertScrollView(
        title: String,
        subtitle: String? = nil,
        contents: [ScrollableAlertMessage],
        confirmText: String? = nil,
        cancelText: String? = nil,
        confirmHandler: AlertActionHandler? = nil,
        cancelHandler: AlertActionHandler? = nil
    ) {
        let alertVC = EventAlertScrollViewController(
            title: title,
            subtitle: subtitle,
            with: contents,
            confirmText: confirmText,
            cancelText: cancelText,
            confirmHandler: confirmHandler,
            cancelHandler: cancelHandler
        )
        alertVC.modalPresentationStyle = .overCurrentContext
        present(alertVC, animated: false, completion: nil)
    }
}

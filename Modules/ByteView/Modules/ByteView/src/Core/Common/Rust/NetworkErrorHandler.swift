//
//  NetworkErrorHandler.swift
//  ByteView
//
//  Created by kiri on 2021/8/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewUI
import UniverseDesignToast

protocol CommonErrorHandlerListener: AnyObject {
    func errorPopupWillShow(_ msgInfo: MsgInfo)
    func errorPopupDidClickLeftButton(_ msgInfo: MsgInfo)
}

final class NetworkErrorHandlerImpl: NetworkErrorHandler {
    static let shared = NetworkErrorHandlerImpl()

    private var router: LarkRouter?
    private let listeners = Listeners<CommonErrorHandlerListener>()

    func addListener(_ listener: CommonErrorHandlerListener) {
        listeners.addListener(listener)
    }

    func setupRouter(_ router: LarkRouter) {
        self.router = router
    }

    func handleBizError(httpClient: HttpClient, error: RustBizError) -> Bool {
        guard let msgInfo = error.msgInfo, msgInfo.isShow else {
            return false
        }

        switch msgInfo.type {
        case .toast:
            if msgInfo.isOverride {
                showToast(content: error.content, msgInfo: msgInfo)
                return true
            } else {
                let content = error.toVCError().description
                if content.isEmpty {
                    return false
                } else {
                    showToast(content: content, msgInfo: msgInfo)
                    return true
                }
            }
        case .popup:
            showPopup(client: httpClient, error: error, msgInfo: msgInfo)
            return true
        case .alert:
            return showAlert(i18nValues: error.i18nValues, msgInfo: msgInfo)
        default:
            return false
        }
    }

    private func showToast(content: String, msgInfo: MsgInfo) {
        let duration = msgInfo.expire > 0 ? TimeInterval(msgInfo.expire) / 1000.0 : nil
        switch msgInfo.toastIcon {
        case .info:
            Toast.show(content, duration: duration)
        case .success:
            Toast.show(content, type: .success, duration: duration)
        case .warning:
            Toast.show(content, type: .warning, duration: duration)
        case .error:
            Toast.show(content, type: .error, duration: duration)
        case .loading:
            Toast.showLoading(content, duration: duration)
        default:
            Toast.show(content, duration: duration)
        }
    }

    private func showPopup(client: HttpClient, error: RustBizError, msgInfo: MsgInfo) {
        if error.toVCError() == VCError.newHitRiskControl {
            // 暂时只对新需求应用新的 popup 弹框
            _showNewPopup(client: client, content: error.content, msgInfo: msgInfo)
        } else {
            _showOldPopup(content: error.content, msgInfo: msgInfo)
        }
    }

    private func _showNewPopup(client: HttpClient, content: String, msgInfo: MsgInfo) {
        let msgKey = msgInfo.msgI18NKey
        let titleKey = msgInfo.msgTitleI18NKey
        let buttonKey = msgInfo.msgButtonI18NKey
        let keys = [msgKey?.key, titleKey?.key, buttonKey?.key].compactMap { $0 }
        client.i18n.get(keys) { [weak self] res in
            guard case .success(let pairs) = res else { return }
            var title: String?
            var message: String?
            var leftTitle: String?
            if let titleKey = titleKey {
                title = pairs[titleKey.key]
            }
            if let msgKey = msgKey {
                message = pairs[msgKey.key]
            }
            if let buttonKey = buttonKey {
                leftTitle = pairs[buttonKey.key]
            }
            Util.runInMainThread {
                self?.listeners.forEach { $0.errorPopupWillShow(msgInfo) }
                ByteViewDialog.Builder().id(.netBusinessError)
                    .title(title)
                    .message(message)
                    .colorTheme(leftTitle != nil ? .firstButtonBlue : .defaultTheme)
                    .leftTitle(leftTitle)
                    .leftHandler { _ in
                        if let jumpScheme = buttonKey?.jumpScheme, let router = self?.router {
                            self?.listeners.forEach { $0.errorPopupDidClickLeftButton(msgInfo) }
                            router.goto(scheme: jumpScheme)
                        }
                    }
                    .rightTitle(I18n.View_G_ApplicationPhoneCallTimeButtonKnow)
                    .show()
            }
        }
    }

    private func _showOldPopup(content: String, msgInfo: MsgInfo) {
        Util.runInMainThread {
            ByteViewDialog.Builder()
                .id(.netBusinessError)
                .title("")
                .message(content)
                .rightTitle(I18n.View_G_ApplicationPhoneCallTimeButtonKnow)
                .show()
        }
    }

    private func showAlert(i18nValues: [String: String], msgInfo: MsgInfo) -> Bool {
        guard !i18nValues.isEmpty, let alert = msgInfo.alert, let footer = alert.footer else { return false }
        let title: String? = i18nValues[alert.title.i18NKey]
        let content: String? = i18nValues[alert.body.i18NKey]
        let buttonTitle: String? = i18nValues[footer.text.i18NKey]
        Util.runInMainThread {
            ByteViewDialog.Builder()
                .id(.netBusinessError)
                .title(title)
                .message(content)
                .rightTitle(buttonTitle)
                .rightType(footer.waitTime > 0 ? .countDown(time: TimeInterval(footer.waitTime)) : nil)
                .needAutoDismiss(true)
                .show()
        }
        return true
    }
}

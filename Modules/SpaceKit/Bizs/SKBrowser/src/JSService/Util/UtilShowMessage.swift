//
//  UtilShowMessage.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/4/9.
//  

import Foundation
import SKCommon
import SKUIKit
import UniverseDesignNotice
import SKInfra

public final class UtilShowMessage: BaseJSService {
    private weak var tipsView: BannerItem?
    private var callback: String?
    private var leadingButtonAction: String?
}

extension UtilShowMessage: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilShowMessage, .utilHiddenMessage]
    }
    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilShowMessage.rawValue:
            showMessage(params: params)
        case DocsJSService.utilHiddenMessage.rawValue:
            hiddenMessage(params: params)
        default:
            return
        }

    }

    private func showMessage(params: [String: Any]) {
        guard let type = params["type"] as? String,
            let tiptype = tipsType(with: type),
            let text = params["text"] as? String
            else { return }

        let tipsView = NetInterruptTipView.defaultView()
        if let canShowClose = params["canClose"] as? Bool {
            tipsView.setTitle(text, type: tiptype, canClose: canShowClose)
        } else {
            tipsView.setTitle(text, type: tiptype)
        }

        if let linkText = params["linkText"] as? String,
           let linkedUrl = params["linkUrl"] as? String {
            if linkedUrl.lengthOfBytes(using: .utf8) > 0 {
                if let canShowClose = params["canClose"] as? Bool {
                    tipsView.setLinkText(linkText, linkUrl: linkedUrl, canClose: canShowClose)
                } else {
                    tipsView.setLinkText(linkText, linkUrl: linkedUrl)
                }
            }
        }

        if let linkText = params["linkText"] as? String,
           let action = params["actionName"] as? String {
            let linkedUrl = appealLink(with: action)
            if linkedUrl.lengthOfBytes(using: .utf8) > 0 {
                tipsView.addLinkText(linkText, linkUrl: linkedUrl, showUnderline: false)
            }
        }

        if let linkText = params["extraText"] as? String,
           let action = params["extraAction"] as? String {
            let linkedUrl = appealLink(with: action)
            if linkedUrl.lengthOfBytes(using: .utf8) > 0 {
                tipsView.addLinkText(linkText, linkUrl: linkedUrl, showUnderline: false)
            }
        }
    
        if let textBtnParam = params["textBtn"] as? [String: String], let action = textBtnParam["action"], let text = textBtnParam["text"] {
            tipsView.setLeadingButtonText(text)
            self.leadingButtonAction = action
        }
    
        if let callback = params["callback"] as? String {
            self.callback = callback
        }

        tipsView.actionDelegate = self
        ui?.bannerAgent.requestShowItem(tipsView)
        tipsView.delegate = self
        self.tipsView = tipsView
    }

    private func hiddenMessage(params: [String: Any]) {
        guard let tipsView = tipsView else {
            return
        }
        ui?.bannerAgent.requestHideItem(tipsView)
    }
    
    private func tipsType(with typeString: String) -> TipType? {
        switch typeString {
        case "error":
            return TipType.custom(TipType.ShowStyle.levelStyleError)
        case "warning":
            return TipType.custom(TipType.ShowStyle.levelStyleWarning)
        case "normal":
            return TipType.custom(TipType.ShowStyle.levelStyleNormal)
        default:
            return nil
        }
    }

    private func appealLink(with action: String? = nil) -> String {
        var link: String
        let domain = DomainConfig.larkReportDomain
        let feishuDomain = DomainConfig.tnsReportDomain
        let reportPath = SettingConfig.tnsReportConfig?.reportPath ?? TnsReportConfig.default.reportPath
        if DomainConfig.envInfo.isFeishuBrand {
            link = "https://" + feishuDomain + reportPath
        } else {
            link = "https://" + domain + reportPath
        }
        if let action {
            link = link + "/?action=\(action)"
        }
        return link
    }
}
extension UtilShowMessage: ActionDeleagete, UDNoticeDelegate {
    public func handleLeadingButtonEvent(_ button: UIButton) {
        guard let callback = callback, let leadingButtonAction = leadingButtonAction else {
            return
        }
        model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: ["action": leadingButtonAction], completion: nil)
    }

    public func handleTrailingButtonEvent(_ button: UIButton) {
        didClose()
    }

    public func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        var params: [String: Any]?
        let reportPath = SettingConfig.tnsReportConfig?.reportPath ?? TnsReportConfig.default.reportPath
        if let callback, URL.path == reportPath {
            let action = URL.docs.queryParams?["action"] ?? ""
            let urlPath = appealLink() + "/appeal"
            params = [
                "urlPath": urlPath,
                "action": action
            ]
            self.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: params, completion: nil)
        } else {
            self.model?.jsEngine.callFunction(DocsJSCallBack.appealClick, params: nil, completion: nil)
        }
    }

    public func didClose() {
        if let item = tipsView {
            ui?.bannerAgent.requestHideItem(item)
        }
        guard let callback = callback else {
            return
        }
        model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: ["action": "close"], completion: nil)
    }
}

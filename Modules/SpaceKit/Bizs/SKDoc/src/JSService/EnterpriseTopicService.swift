//
//  EnterpriseTopicService.swift
//  SKDoc
//
//  Created by lizechuang on 2021/8/4.
//

import SKCommon
import SKFoundation
import SKBrowser
import EENavigator

class EnterpriseTopicService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension EnterpriseTopicService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.showEnterpriseTopic, .dismissEnterpriseTopic]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.showEnterpriseTopic.rawValue:
            showEnterpriseTopic(params: params)
        case DocsJSService.dismissEnterpriseTopic.rawValue:
            dismissEnterpriseTopic(params: params)
        default:
            return
        }
    }

    private func showEnterpriseTopic(params: [String: Any]) {
        guard let query = params["query"] as? String,
              let abbrId = params["abbrId"] as? String,
              let triggerInfo = params["triggerInfo"] as? [String: Any],
              let x = triggerInfo["x"] as? Double,
              let y = triggerInfo["y"] as? Double,
              let clientArgs = params["clientArgs"] as? String,
              let callback = params["callback"] as? String else {
            DocsLogger.error("ShowEnterpriseTopic params deficiency")
            return
        }
        guard let triggerView = ui?.editorView, let targetVC = navigator?.currentBrowserVC else {
            return
        }
        var didTapApplink: EnterpriseTopicTapApplinkHandle?
        if self.isInVideoConference || self.isDocComponent {
            // MS模式下将URL转发给MS
            didTapApplink = { [weak self] applink in
                guard let self = self, let fromVC = self.registeredVC else {
                    return
                }
                // 需要先将当前卡片关闭
                self.dismissEnterpriseTopic(params: [:])
                
                if !OperationInterceptor.interceptUrlIfNeed(applink.absoluteString,
                                                            from: self.navigator?.currentBrowserVC,
                                                            followDelegate: self.model?.vcFollowDelegate) {
                    self.model?.userResolver.navigator.push(applink, from: fromVC)
                }
            }
        }
        navigator?.showEnterpriseTopic(query: query,
                                       addrId: abbrId,
                                       triggerView: triggerView,
                                       triggerPoint: CGPoint(x: x, y: y),
                                       clientArgs: clientArgs,
                                       clickAction: { [weak self] string in
            guard let self = self else {
                return
            }
            if let data = string.data(using: .utf8) {
                do {
                    let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
                } catch {
                    DocsLogger.error("ShowEnterpriseTopic clickAction deficiency")
                }
            }
        },
                                       didTapApplink: didTapApplink,
                                       targetVC: targetVC)
    }

    private func dismissEnterpriseTopic(params: [String: Any]) {
        navigator?.dismissEnterpriseTopic()
    }
}

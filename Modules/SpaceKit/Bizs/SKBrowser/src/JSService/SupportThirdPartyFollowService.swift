//
//  SupportThirdPartService.swift
//  SpaceKit
//
//  Created by 吴珂 on 2020/4/10.
//  


import Foundation
import SpaceInterface
import SKCommon
import SKFoundation

class SupportThirdPartyFollowService {
    private var rnToWebCallbackScript: String?
    private weak var browserView: SupportThirdPartyFollowBrowserView?
    
    init(browserView: SupportThirdPartyFollowBrowserView) {
        self.browserView = browserView
        RNManager.manager.registerRnEvent(eventNames: [.sendMessageToWebview], handler: self)
    }
    
    func evaluateFunction(function: String, params: [String: Any]?) {
        browserView?.callFunction(DocsJSCallBack(function), params: params, completion: nil)
    }
    
    func handle(params: [String: Any], serviceName: String) {
        switch DocsJSService(serviceName) {
        case .rnSendMsg:
            RNManager.manager.sendSyncData(data: params, responseId: params["callback"] as? String)
        case .rnHandleMsg:
            guard let jsMethod = callbackMethod(from: params) else { return }
            rnToWebCallbackScript = jsMethod
        case .rnReload:
            DocsLogger.info("SupportThirdPartyFollowService will reloadRNBundle")
            RNManager.manager.reloadBundle { (result) in
                guard let jsMethod = self.callbackMethod(from: params) else { return }
                let code = result ? 1 : 0
                self.evaluateFunction(function: jsMethod, params: ["result": code])
            }
        case .vcFollowOn:
            handVCFollowOn(params: params, serviceName: serviceName)
        case .followReady:
            browserView?.spaceFollowAPIDelegate?.followDidReady(nil)
        case .reportReportEvent:
            guard let eventName = params["event_name"] as? String,
            let data = params["data"] as? [String: Any] else {
                return
            }
            DocsTracker.log(event: eventName, parameters: data)
        default:
            DocsLogger.info("不支持的事件类型 \(serviceName)\(params)")
        }
    }
    
    func callbackMethod(from params: [String: Any]) -> String? {
        return (params["callback"] as? String)
    }
}

 extension SupportThirdPartyFollowService {
    func handVCFollowOn(params: [String: Any], serviceName: String) {
        //第三方webview onFollow走rnSendMsg，Native不再单独处理
//        guard let actionJSONs = params["actions"] as? [[String: Any]] else { DocsLogger.error("vcFollow前端缺少actions参数"); return }
//        guard let eventStr = params["event"] as? String, let event = FollowEvent(rawValue: eventStr) else { DocsLogger.error("vcFollow前端缺少event参数"); return }
//        var followActions = [SpaceInterface.FollowState]()
//        for item in actionJSONs {
//            guard JSONSerialization.isValidJSONObject(item) else {
//                assertionFailure("非法json \(item)")
//                DocsLogger.error("【vcFollow】前端传入非法json \(item)")
//                continue
//            }
//            if let json = item.jsonString {
//                followActions.append(DocsVCFollowState(rawJson: json))
//            }
//        }
//        browserView?.spaceFollowAPIDelegate?.follow(on: event, with: followActions)
    }
}

extension SupportThirdPartyFollowService: RNMessageDelegate {
    func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard let webData = data["data"] as? [String: Any] else { return }
        guard let callback = rnToWebCallbackScript else { return }
        evaluateFunction(function: callback, params: webData)
    }
}

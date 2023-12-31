//
//  ClippingDocService.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/27.
//  


import LarkWebViewContainer
import SKFoundation
import SwiftyJSON
import UniverseDesignToast
import EENavigator
import SKResource
import Foundation
import SKInfra

final class ClippingDocService: DocMenuPluginService {
    
    let secretKey: String
    
    var fileService: ClippingDocFileSubPlugin?
    
    var traceId: String?
    
    weak var tracker: ClippingDocReport?
    
    init(secretKey: String, traceId: String?, tracker: ClippingDocReport?) {
        self.secretKey = secretKey
        self.traceId = traceId
        self.tracker = tracker
        fileService = try? ClippingDocFileSubPlugin(secretKey: secretKey)
        fileService?.tracker = tracker
    }
    
    var handleServices: [DocsJSService] {
        return [.saveFile,
                .nativeFetch,
                .showToast,
                .openUrl,
                .reportEvent,
                .getLang,
                .notifyJsReady,
                .printLog,
                .getBlackList]
    }

    
    
    lazy var netSubPlugin: ClippingNetSubPlugin = {
        let plugin = ClippingNetSubPlugin(secretKey: self.secretKey, traceId: traceId)
        plugin.fileService = self.fileService
        plugin.tracker = self.tracker
        return plugin
    }()
    
    weak var loadingToast: UDToast?
    
    func handle(params: [String: Any], serviceName: DocsJSService, callback: APICallbackProtocol?, api: DocMenuPluginWebAPI) {
        switch serviceName {
        case .saveFile:
            handleSaveFile(params: params, callback: callback, api: api)
        case .nativeFetch:
            handleFetch(params: params, callback: callback, api: api)
        case .showToast:
            handleshowToast(params: params, callback: callback, api: api)
        case .openUrl:
            handleOpenUrl(params: params, api: api)
        case .reportEvent:
            handleReportTea(params: params, api: api)
        case .getLang:
            handleGetLang(params: params, callback: callback)
        case .notifyJsReady:
            handleNotifyJsReady(params: params, callback: callback)
        case .printLog:
            handleLog(params: params)
        case .getBlackList:
            handleGetBlackList(params: params, callback: callback)
        default:
            break
        }
    }

    deinit {
        loadingToast?.remove()
    }
}

extension ClippingDocService {

    func handleLog(params: [String: Any]) {
        guard let model: ClippingLogModel = params.mapModel() else {
            return
        }
        switch model.level {
        case .info:
            DocsLogger.info(model.msg, component: model.tag)
        case .error:
            DocsLogger.error(model.msg, component: model.tag)
        case .warning:
            DocsLogger.warning(model.msg, component: model.tag)
        case .debug:
            DocsLogger.debug(model.msg, component: model.tag)
        }
    }
    
    func handleGetLang(params: [String: Any], callback: APICallbackProtocol?) {
        let lang = DocsSDK.currentLanguage.languageIdentifier
        DocsLogger.info("callback lang:\(lang)", component: LogComponents.clippingDoc, traceId: traceId)
        callback?.callbackSuccess(param: ["lang": lang])
    }
    
    func handleNotifyJsReady(params: [String: Any], callback: APICallbackProtocol?) {
        DocsLogger.info("callback notifyJsReady", component: LogComponents.clippingDoc, traceId: traceId)
        callback?.callbackSuccess(param: ["operation": "start_clip",
                                          "networkStatus": DocsNetStateMonitor.shared.isReachable ? 0 : 1])
    }
    
    func handleshowToast(params: [String: Any], callback: APICallbackProtocol?, api: DocMenuPluginWebAPI) {

        guard let model: ClippingToastModel = params.mapModel() else {
            return
        }
        switch model.status {
        case .success:
            loadingToast = nil
            UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_Clip_Clipped, on: api.currentWindow)
        case .fail:
            loadingToast = nil
            let msg = model.failReason?.failMsg ?? BundleI18n.SKResource.LarkCCM_Clip_Failed
            if model.showRetry == true {
                UDToast.showFailure(with: msg,
                                    operationText: BundleI18n.SKResource.LarkCCM_Clip_FailedRetry,
                                    on: api.currentWindow,
                                    delay: 5) { [weak self] _ in
                    callback?.callbackSuccess(param: ["operation": "click_retry"])
                    DocsLogger.info("click retry", component: LogComponents.clippingDoc, traceId: self?.traceId)
                }
            } else {
                UDToast.showFailure(with: msg, on: api.currentWindow)
            }
        case .loading:
            let progress = model.progress ?? 0
            let text = "\(BundleI18n.SKResource.LarkCCM_Clip_Clipping)\(progress)%"
            if loadingToast == nil {
                loadingToast = UDToast.showLoading(with: text, on: api.currentWindow)
            } else {
                loadingToast?.updateToast(with: text, superView: api.currentWindow)
            }
        }
    }
    
    func handleOpenUrl(params: [String: Any], api: DocMenuPluginWebAPI) {
        let json = JSON(params)
        let urlString = json["url"].stringValue
        if let url = URL(string: urlString), let nav = api.webBrowser?.navigationController {
            Navigator.shared.push(url, from: nav)
        } else {
            DocsLogger.error("can not push params: \(params)", component: LogComponents.clippingDoc, traceId: traceId)
        }
    }
    
    func handleFetch(params: [String: Any], callback: APICallbackProtocol?, api: DocMenuPluginWebAPI) {
        netSubPlugin.handleFetch(params: params, callback: callback)
    }
    
    func handleSaveFile(params: [String: Any], callback: APICallbackProtocol?, api: DocMenuPluginWebAPI) {
        fileService?.saveFile(params: params, result: { [weak self] res in
            DispatchQueue.main.async {
                DocsLogger.info("callback saveFile res:\(res)", component: LogComponents.clippingDoc, traceId: self?.traceId)
                callback?.callbackSuccess(param: ["res": res])
            }
        })
    }
    
    func handleReportTea(params: [String: Any], api: DocMenuPluginWebAPI) {
        guard let eventName = params["eventName"] as? String,
           let data = params["data"] as? [String: Any] else {
            DocsLogger.error("tea params invalid", component: LogComponents.clippingDoc, traceId: traceId)
            return
        }
        DocsLogger.debug("tea eventName:\(eventName) data:\(data)", component: LogComponents.clippingDoc, traceId: traceId)
        DocsTracker.newLog(event: eventName, parameters: data)
    }
    
    func handleGetBlackList(params: [String: Any], callback: APICallbackProtocol?) {
        let blackList = SettingConfig.clipBlackList?.blackList ?? []
        DocsLogger.info("blackList:\(blackList)", component: LogComponents.clippingDoc, traceId: traceId)
        callback?.callbackSuccess(param: ["blackList": blackList])
    }
}

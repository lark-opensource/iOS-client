//
//  OpenPluginWebViewComponent.swift
//  OPPlugin
//
//  Created by yi on 2021/5/12.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import TTMicroApp
import ECOProbe
import LarkContainer
import SnapKit

enum OpenPluginWebViewURLCheckResultType: UInt {
    case webViewURLValid = 0
    case webViewURLAuthorizeFailed = 1
    case webViewURLNotInMP = 2
    case webViewURLInvalidHtmlId = 3
}

final class OpenPluginWebViewComponent: OpenBasePlugin, BDPWebViewInjectProtocol {

    var apiContext: OpenAPIContext?
    
    let layoutFixSetting = OPSettings(key: .make(userKeyLiteral: "webviewLayouSetting"), tag: "layoutFix", defaultValue: false)

    // 逻辑层API
    func insertHTMLWebView(
        params: OpenAPIInsertHTMLWebViewParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: (OpenAPIBaseResponse<OpenAPIInsertHTMLWebViewResult>) -> Void
    ) {
        apiContext = context
        guard let page = context.enginePageForComponent else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Please execute under H5 or Native App running environment")
                .setMonitorMessage("can not get current engine as webview, fail insertHTMLWebView")
            callback(.failure(error: error))
            return
        }
       
        guard let gadgetController = context.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("gadgetController is nil")
            callback(.failure(error: error))
            return
        }

        guard let componentManager = BDPComponentManager.shared() else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("componentManager is nil")
            callback(.failure(error: error))
            return
        }

        let componentID = componentManager.generateComponentID()
        let uniqueID = gadgetContext.uniqueID

        let layoutFixEnable = layoutFixSetting.getValue(appID: uniqueID.appID)
        var frame = params.frame
        if let appPage = page as? BDPAppPage {
            appPage.isHasWebView = true
            if layoutFixEnable {
                frame = appPage.frame
            } else {
                if (frame.height > appPage.frame.height) {
                    frame.size.height = appPage.frame.height
                }
            }
        }

        let task = BDPTaskManager.shared()?.getTaskWith(uniqueID)
        let config = WKWebViewConfiguration()
        if let processPool = task?.processPool {
            config.processPool = processPool
        }
        config.allowsInlineMediaPlayback = true

        let view = BDPWebViewComponent(frame: frame, config: config, componentID: componentID, uniqueID: uniqueID, progressBarColorString: params.progressBarColor, delegate: self)
        componentManager.insertComponentView(view, to: page)
        
        if layoutFixEnable {
            // 和小程序容器始终对齐
            view.snp.makeConstraints { make in
                make.edges.equalTo(page)
            }
        }

        // 添加通信通道到channel manager，表示当前jsworker 与 创建的webview之间的映射，该映射在 removeHTMLWebView 中删除，channel生命周期跟随BDPWebViewComponent
        if let task = task, let jsRuntimeId = task.context?.uniqueID {
            let channel = BDPWebComponentChannel(jsRuntimeId: jsRuntimeId, webviewComponentId: view.componentID)
            task.channelManager.addChannel(channel: channel)
        } else {
            context.apiTrace.error("add message channel failed, taskID: \(task?.uniqueID), jsRuntimeId: \(task?.context?.uniqueID)")
        }

        if let controller = BDPAppController.currentAppPageController(gadgetController, fixForPopover: false) as? BDPAppPageController, let block = controller.canGoBackChangedBlock {
            view.bwc_canGoBackChangedBlock = block
        }
        context.apiTrace.info("insertHTMLWebView success with uniqueID: \(uniqueID), componentID: \(componentID), position: \(params.position), progressBarColorString: \(params.progressBarColor)")
        callback(.success(data: OpenAPIInsertHTMLWebViewResult(htmlId: componentID)))
    }

    func updateHTMLWebView(
        params: OpenAPIUpdateHTMLWebViewParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let page = context.enginePageForComponent else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Please execute under H5 or Native App running environment")
                .setMonitorMessage("can not get current engine as webview, fail insertHTMLWebView")
            callback(.failure(error: error))
            return
        }
      
        let uniqueID = gadgetContext.uniqueID

        guard let url = params.srcURL else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Format of src parameter is error")
                .setMonitorMessage("Format of src parameter is error")
            callback(.failure(error: error))
            return
        }
        var srcURL = url
        let openInOuterBrowserURL = url // 用于在safari打开原始的url


        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID), let auth = common.auth else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("auth is nil")
            callback(.failure(error: error))
            return
        }
        var callbackMsg = ""
        let checkResult = BDPWebViewComponent.bwc_check(srcURL, withAuth: auth, uniqueID: uniqueID)
        srcURL = BDPWebViewComponent.bwc_redirectedURL(srcURL, with: checkResult)
        var urlCheckResult: OpenPluginWebViewURLCheckResultType = .webViewURLValid
        if checkResult != .validURL && checkResult != .validSchema {
            urlCheckResult = .webViewURLAuthorizeFailed
            callbackMsg = "url permission verification failed"
            if checkResult == .invalidDomain {
                BDPTracker.event("mp_webview_invalid_domain", attributes: ["host": srcURL.host], uniqueID: uniqueID)
            }
        }
        if urlCheckResult == .webViewURLValid {
            apiContext = context
        }

        if let webview = BDPComponentManager.shared()?.findComponentView(byID: params.htmlId) as? BDPWebViewComponent {
            webview.bwc_openInOuterBrowserURL = openInOuterBrowserURL
            var request = URLRequest(url: srcURL)
            if let webviewPlugin = BDPTimorClient.shared().webviewPlugin.sharedPlugin() as? BDPWebviewPluginDelegate, let req = webviewPlugin.bdp_synchronizeCookie?(forWebview: webview, request: request, uniqueID: uniqueID) {
                request = req
            }
            webview.load(request)
        } else {
            urlCheckResult = .webViewURLInvalidHtmlId
            callbackMsg = "htmlId error"
        }
        if urlCheckResult != .webViewURLValid {
            context.apiTrace.error("updateHTMLWebView uniqueID: \(uniqueID), callbackMsg:\(callbackMsg), urlCheckResult: \(urlCheckResult), checkResult: \(checkResult), componentID: \(params.htmlId), src: \(NSString.safeURLString(params.src))")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage(callbackMsg)
                .setMonitorMessage(callbackMsg)
            callback(.failure(error: error))

            return
        }
        context.apiTrace.info("updateHTMLWebView success with uniqueID: \(uniqueID), componentID: \(params.htmlId), src: \(NSString.safeURLString(params.src))")
        callback(.success(data: nil))
    }

    func removeHTMLWebView(
        params: OpenAPIHTMLWebViewParams,
        context: OpenAPIContext,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        let componentId = params.htmlId
        let channelId = BDPWebComponentChannel.generateChannelId(webviewComponentId: componentId)
        if let uniqueID = context.gadgetContext?.uniqueID, let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) {
            // 删除channel manager中的通信通道
            task.channelManager.removeChannel(channelId: channelId)
            context.apiTrace.info("removeHTMLWebView: remove channel SUCCESS [channelId: \(channelId)] in channelManager [uniqueID: \(String(describing: context.uniqueID))] , componentID: \(componentId)")
        } else {
            context.apiTrace.error("removeHTMLWebView: remove channel FAILED [channelId: \(channelId)] in channelManager [uniqueID: \(String(describing: context.uniqueID))] , componentID: \(componentId)")
        }
        BDPComponentManager.shared()?.removeComponentView(byID: componentId)
        context.apiTrace.info("removeHTMLWebView success with uniqueID: \(String(describing: context.uniqueID)) componentID: \(componentId)")
        callback(.success(data: nil))
    }

    func operateHTMLWebView(
        params: OpenAPIOperateHTMLWebViewParams,
        context: OpenAPIContext,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        if let view = BDPComponentManager.shared()?.findComponentView(byID: params.htmlId) as? BDPWebViewComponent {
            view.isHidden = params.hide
            context.apiTrace.info("operateHTMLWebView success with uniqueID: \(context.uniqueID), componentID: \(params.htmlId), hide: \(params.hide)")
            callback(.success(data: nil))
            return
        }
        let errorMessage = "htmlid is invalid"
        context.apiTrace.error("operateHTMLWebView success with uniqueID: \(context.uniqueID), errorMessage: \(errorMessage), componentID: \(params.htmlId), hide: \(params.hide)")
        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage(errorMessage).setOuterMessage(errorMessage)
        callback(.failure(error: error))
    }

    func resizeHTMLWebView(
        params: OpenAPIResizeHTMLWebViewParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        var frame = params.frame
        if let page = context.enginePageForComponent, let appPage = page as? BDPAppPage {
            let layoutFixEnable = layoutFixSetting.getValue(appID: gadgetContext.uniqueID.appID)
            if layoutFixEnable {
                frame = appPage.frame
            } else {
                if (frame.height > appPage.frame.height) {
                    frame.size.height = appPage.frame.height
                }
            }
        }

        if let view = BDPComponentManager.shared()?.findComponentView(byID: params.htmlId) as? BDPWebViewComponent {
            view.frame = frame;
            context.apiTrace.info("resizeHTMLWebView success with uniqueID: \(context.uniqueID), componentID: \(params.htmlId), frame: \(frame)")
            callback(.success(data: nil))
            return
        }
        let errorMessage = "htmlid is invalid"
        context.apiTrace.error("operateHTMLWebView success with uniqueID: \(context.uniqueID), errorMessage: \(errorMessage), componentID: \(params.htmlId), frame: \(frame)")
        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage(errorMessage).setOuterMessage(errorMessage)
        callback(.failure(error: error))
    }

    // 逻辑层 + 渲染层API
    func transferMessage(
        params: OpenPluginTransferMessageParams,
        context: OpenAPIContext,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        context.apiTrace.info("transferMessage api invoked!")
        guard let uniqueID = context.gadgetContext?.uniqueID else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext.uniqueID is nil")
            callback(.failure(error: error))
            return
        }
        guard let task = BDPTaskManager.shared().getTaskWith(uniqueID) else {
            context.apiTrace.error("task is nil!")
            let error = OpenAPIError(code: BDPWebComponentTrasferMsgErrorCode.taskNotFound)
                .setMonitorMessage("UniqueID: \(uniqueID)")
            callback(.failure(error: error))
            return
        }
        let messageFormateFG = EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyTransferMessageFormateConsistent)
        if params.from == "worker" {
            guard let channelID = params.channel else {
                context.apiTrace.error("channelID is nil!")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("channelID is nil!")
                callback(.failure(error: error))
                return
            }
            // 获取channel的地方收敛在task的channelManager中（私有属性）
            guard let channel = task.channelManager.getChannelById(channelId: channelID) else {
                context.apiTrace.error("channel is nil!")
                let error = OpenAPIError(code: BDPWebComponentTrasferMsgErrorCode.channelNotFound)
                    .setMonitorMessage("channelId: \(channelID)")
                callback(.failure(error: error))
                return
            }
            
            guard let render = BDPComponentManager.shared().findComponentView(byID: channel.webViewComponentId) as? BDPWebViewComponent else {
                context.apiTrace.error("Didn't find render!")
                let error = OpenAPIError(code: BDPWebComponentTrasferMsgErrorCode.renderNotFound)
                    .setMonitorMessage("componentId: \(channel.webViewComponentId)")
                callback(.failure(error: error))
                return
            }
            context.apiTrace.info("transfer message to web-view on channel: [\(channelID)]")
            var data: [String: Any] = [
                "data": params.data
            ]
            if messageFormateFG {
                data["channel"] = channelID
            }
            guard let paramsStr: String = NSDictionary(dictionary: data).jsonRepresentation() else {
                context.apiTrace.error("params string is empty!")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                callback(.failure(error: error))
                return
            }
            render.publishMsg(
                withApiName: "onTransferMessage",
                paramsStr: paramsStr,
                webViewId: channel.webViewComponentId
            )
        } else if params.from == "webview" {
            // 这里暂时用这种方式取worker，多worker的场景需要结合channel获取worker
            guard let worker = BDPTaskManager.shared().getTaskWith(uniqueID)?.context else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("Didn't find worker! UniqueID: \(uniqueID)")
                callback(.failure(error: error))
                return
            }
            context.apiTrace.info("transfer message to worker, workerId: [\(worker.uniqueID)]")
            var dataDict: [AnyHashable: Any] = params.data
            if messageFormateFG {
                dataDict = ["data": params.data]
            }
            guard JSONSerialization.isValidJSONObject(dataDict) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("data is not invalid json!")
                callback(.failure(error: error))
                return
            }
            worker.bdp_fireEventV2("onTransferMessage", data: dataDict)
        } else {
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)))
            context.apiTrace.error("[from_param] is undefine: " + params.from)
        }
        context.apiTrace.info("transfer message success!")
        callback(.success(data: nil))
    }

    func webViewPublishMessage(_ event: String, param: [AnyHashable : Any]) {
        if let context = apiContext {
            do {
                let eventParams = try OpenAPIFireEventParams(
                    event: event,
                    sourceID: NSNotFound,
                    data: param,
                    preCheckType: .none,
                    sceneType: .worker,
                    sourceType: .webViewComponent
                )
                let _ = context.syncCall(
                    apiName: "fireEvent",
                    params: eventParams,
                    context: context
                )
            } catch {
                context.apiTrace.error("input fireEvent error: \(error)")
            }

        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "insertHTMLWebView", pluginType: Self.self, paramsType: OpenAPIInsertHTMLWebViewParams.self, resultType: OpenAPIInsertHTMLWebViewResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.insertHTMLWebView(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "updateHTMLWebView", pluginType: Self.self, paramsType: OpenAPIUpdateHTMLWebViewParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.updateHTMLWebView(params: params, context: context,  gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandler(for: "removeHTMLWebView", pluginType: Self.self, paramsType: OpenAPIHTMLWebViewParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.removeHTMLWebView(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "operateHTMLWebView", pluginType: Self.self, paramsType: OpenAPIOperateHTMLWebViewParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.operateHTMLWebView(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "resizeHTMLWebView", pluginType: Self.self, paramsType: OpenAPIResizeHTMLWebViewParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.resizeHTMLWebView(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandler(for: "transferMessage", pluginType: Self.self, paramsType: OpenPluginTransferMessageParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.transferMessage(params: params, context: context, callback: callback)
        }
    }
}

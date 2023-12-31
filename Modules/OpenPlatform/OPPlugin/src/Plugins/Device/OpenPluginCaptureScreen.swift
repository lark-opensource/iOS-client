//
//  OpenPluginCaptureScreen.swift
//  OPPlugin
//
//  Created by yi on 2021/3/9.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import ECOProbe
import LKCommonsLogging
import LarkContainer

class OpenPluginCaptureScreen: OpenBasePlugin {
    static let logger = Logger.log(OpenPluginCaptureScreen.self, category: "OpenAPI")
    var currentContext: OpenAPIContext?

    public func onUserCaptureScreen(params: OpenAPIBaseParams, context: OpenAPIContext, callback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)) {
        currentContext = context

        NotificationCenter.default.addObserver(self, selector: #selector(userDidTakeScreenshot(notification:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        callback(.success(data: nil))
    }

    public func offUserCaptureScreen(params: OpenAPIBaseParams, context: OpenAPIContext, callback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)) {

        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        currentContext = nil
        callback(.success(data: nil))
    }

    @objc func userDidTakeScreenshot(notification: Notification) {
        guard let captureScreenContext = currentContext else {
            Self.logger.error("Plugin: OpenAPIContext not exist in userDidTakeScreenshot")
            return
        }
        // TODO: FireEvent直接接入continue
        do {
            let firEventInfo = try OpenAPIFireEventParams(event: "userCaptureScreenObserved", preCheckType: .isVCActive)
            let response = captureScreenContext.syncCall(apiName: "fireEvent", params: firEventInfo, context: captureScreenContext)
            switch response {
            case .success(data: _):
                captureScreenContext.apiTrace.info("fire event screenshot success")
            case let .failure(error: error):
                captureScreenContext.apiTrace.error("fire event screenshot error \(error)")
            case .continue(event: _, data: _):
                captureScreenContext.apiTrace.info("fire event screenshot continue")
            }
        } catch {
            captureScreenContext.apiTrace.error("generate fire event params error \(error), can not fire screenshot")
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "onUserCaptureScreen", pluginType: Self.self) { (this, params, context, callback) in
            
            this.onUserCaptureScreen(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "offUserCaptureScreen", pluginType: Self.self) { (this, params, context, callback) in
            
            this.offUserCaptureScreen(params: params, context: context, callback: callback)
        }
    }
}

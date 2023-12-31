//
//  OpenPluginWebNavigationBar.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/10/21.
//

import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkUIKit
import LarkWebViewContainer
import OPSDK
import RxCocoa
import RxSwift
import WebBrowser
import LKCommonsLogging
import OPFoundation
import LarkSetting
import LarkContainer

private let logger = Logger.ecosystemWebLog(OpenPluginWebNavigationBar.self, category: NSStringFromClass(OpenPluginWebNavigationBar.self))

//  https://bytedance.feishu.cn/docx/doxcnxrkIn5PZLINemFwcLcR9Df#doxcn4EiUa6e0Qo464DUb9sku36
final class OpenPluginWebNavigationBar: OpenBasePlugin {
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAsyncHandler(for: "setNavigationBar", paramsType: SetTitleBarParams.self) { (params, context, callback) in
            // 来自 API 框架 @lixiaorui 要求：获取 OPAPIContextProtocol 只能通过该方式
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                context.apiTrace.error("gadgetContext is nil")
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                callback(.failure(error: error))
                return
            }
            do {
                try OpenPluginWebNavigationBar.setNavigationBar(params: params, browser: browser, from: "setNavigationBar")
            } catch {
                let err = error as? OpenAPIError ?? OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                callback(.failure(error: err))
                return
            }
            callback(.success(data: nil))
        }
    }
    
    /// 定制导航栏
    /// - Parameters:
    ///   - params: SetTitleBarParams
    ///   - browser: WebBrowser
    ///   - from: 设置来源途径，用于日志追踪
    /// - Throws: 抛出异常，请抛出 OpenAPIError 异常
    static func setNavigationBar(params: SetTitleBarParams, browser: WebBrowser, from: String) throws {
        logger.info("setNavigationBar from:\(from)")
        func generateBarButtonItem(it: SetTitleBarParams.SetTitleBarItemParams, callbackID: String) throws -> UIBarButtonItem {
            var b: RxLKBarButtonItem
            if Self.imageBase64PrefixCompatEnable(),
               let base64 = it.imageBase64,
               let dataStr = Self.base64ImageDataString(base64),
               let data = Data(base64Encoded: dataStr),
               let image = UIImage(data: data) {
                logger.info("make BarButtonItem with remove base64 prefix image. id:\(it.id) callbackID:\(callbackID)")
                b = RxLKBarButtonItem(image: image)
            } else if let base64 = it.imageBase64,
                      let data = Data(base64Encoded: base64),
                      let image = UIImage(data: data) {
                logger.info("make BarButtonItem with image. id:\(it.id) callbackID:\(callbackID)")
                b = RxLKBarButtonItem(image: image)
            } else if let text = it.text {
                logger.info("make BarButtonItem with text. id:\(it.id) callbackID:\(callbackID)")
                b = RxLKBarButtonItem(title: text)
            } else {
                logger.error("invalid button config. id:\(it.id) callbackID:\(callbackID)")
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("invalid parameter")
            }
            let i = it.id
            b.button.rx.tap.subscribe(onNext: { [weak browser] in
                logger.info("BarButtonItem clicked. id:\(i) callbackID:\(callbackID)")
                do {
                    let str = try LarkWebViewBridge.buildCallBackJavaScriptString(callbackID: callbackID, params: ["id": i], extra: nil, type: .continued)
                    browser?.webview.evaluateJavaScript(str)
                } catch {
                    logger.error("buildCallBackJavaScriptString failed. id:\(i) callbackID:\(callbackID)")
                }
            }).disposed(by: b.disposeBag)
            return b
        }
        do {
            if let lefts = params.left {
                // 由于API框架层的参数校验bug，不能支持array嵌套类型的参数校验，需要把参数校验逻辑写在这里
                guard lefts.items.count < 3 else {
                    throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                        .setMonitorMessage("invalid parameter")
                }
                let leftBarButtonItems = try lefts.items.map { (it) throws -> UIBarButtonItem in
                    try generateBarButtonItem(it: it, callbackID: "onLeftNavigationBarClick")
                }
                browser.navigationItem.setLeftBarButtonItems(leftBarButtonItems, animated: false)
            } else {
                logger.info("params.left is nil")
            }
            if let rights = params.right {
                // 由于API框架层的参数校验bug，不能支持array嵌套类型的参数校验，需要把参数校验逻辑写在这里
                guard rights.items.count < 3 else {
                    throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                        .setMonitorMessage("invalid parameter")
                }
                let rightBarButtonItems = try rights.items.map { (it) throws -> UIBarButtonItem in
                    try generateBarButtonItem(it: it, callbackID: "onRightNavigationBarClick")
                }
                if browser.isNavigationRightBarExtensionDisable {
                    browser.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: false)
                } else {
                    if let navigationExtension = browser.resolve(NavigationBarRightExtensionItem.self) {
                        navigationExtension.customItems = rightBarButtonItems
                        navigationExtension.resetAndUpdateRightItems(browser: browser)
                    }
                }
            } else {
                logger.info("params.right is nil")
            }
            if let autoResetNavigationBar = params.autoResetNavigationBar {
                browser.configuration.autoResetNavigationBar = autoResetNavigationBar
            }
        } catch {
            throw error
        }
    }
    
    static func imageBase64PrefixCompatEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.api_setnavigationbar_base64_compat.enable"))// user:global
    }
    
    static private func base64ImageDataString(_ base64Str: String) -> String? {
        if base64Str.isEmpty {
            return nil
        }
        if base64Str.hasPrefix("data:image/png;base64,") ||
            base64Str.hasPrefix("data:image/jpg;base64,") ||
            base64Str.hasPrefix("data:image/x-icon;base64,") {
            // data:[<mediatype>][;base64],<data>
            let base64Arr = base64Str.components(separatedBy: ",")
            if base64Arr.count > 1 {
                return base64Arr[1]
            }
        }
        return base64Str
    }
}
public final class SetTitleBarParams: OpenAPIBaseParams {
    public final class SetTitleBarItemParams: OpenAPIBaseParams {
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "id")
        public var id: String
        @OpenAPIOptionalParam(jsonKey: "text")
        public var text: String?
        @OpenAPIOptionalParam(jsonKey: "imageBase64", validChecker: {
            if $0.count > 10240 {
                return false
            }
            if OpenPluginWebNavigationBar.imageBase64PrefixCompatEnable() {
                return true
            }
            if let data = Data(base64Encoded: $0) {
                if let image = UIImage(data: data) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        })
        public var imageBase64: String?
        public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            [_id, _text, _imageBase64]
        }
    }
    public final class SetTitleBarConfigParams: OpenAPIBaseParams {
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "items")
        public var items: [SetTitleBarItemParams]
        public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            [_items]
        }
    }
    @OpenAPIOptionalParam(jsonKey: "left")
    public var left: SetTitleBarConfigParams?
    @OpenAPIOptionalParam(jsonKey: "right")
    public var right: SetTitleBarConfigParams?
    @OpenAPIOptionalParam(jsonKey: "autoResetNavigationBar")
    public var autoResetNavigationBar: Bool?
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_left, _right, _autoResetNavigationBar]
    }
}

private class RxLKBarButtonItem: LKBarButtonItem {
    // 需要注意：按钮的回调事件生命周期跟随按钮而不是其他什么东西，否则可能会出现点击无响应
    let disposeBag = DisposeBag()
}

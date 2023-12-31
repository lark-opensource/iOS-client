//
//  SmartComposeService.swift
//  SKBrowser
//
//  Created by zoujie on 2020/11/9.
//  


import SKFoundation
import SKCommon
import LarkAccountInterface
import SKInfra

public final class SmartComposeService: BaseJSService {

    private var smartComposeSDK: SmartComposeSDK?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        self.smartComposeSDK = DocsContainer.shared.resolve(SmartComposeSDK.self)
        super.init(ui: ui, model: model, navigator: navigator)
    }

    ///获取setting配置效率选项中的智能补全开关的状态
    private func getDocsSmartComposeSetting() -> Bool {
        guard let sdk = smartComposeSDK else { return false }
        return sdk.smartComposeSetting()
    }
}

extension SmartComposeService: JSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.getAppSetting]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.getAppSetting.rawValue:
            notifySetting(params: params)
        default:
            return
        }
    }

    private func notifySetting(params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        let smartComposeEnabled = ["smart_compose_enabled": getDocsSmartComposeSetting()]
        DocsLogger.info("SmartComposeService callback: \(callback) smartComposeEnabled: \(getDocsSmartComposeSetting())")
        self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: smartComposeEnabled, completion: nil)
    }
}

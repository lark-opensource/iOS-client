//
//  GetInfoService.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2020/5/6.
//

import Foundation
import SKCommon
import SKFoundation
import SKInfra

class GetInfoService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension GetInfoService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.getInfo]
    }
    func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.getInfo.rawValue {
            handleGetDeviceInfo(params: params)
        }
    }
}

fileprivate extension GetInfoService {
    func handleGetDeviceInfo(params: [String: Any]) {
        guard let callback = params["callback"] as? String else {
            DocsLogger.info("获取设备信息缺少callback")
            return
        }
        guard let deviceID = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID) else {
            DocsLogger.info("获取设备信息缺少deviceID")
            return
        }
        var hasSafeArea = 0
        if let bottom = UIApplication.shared.delegate?.window??.safeAreaInsets.bottom,
           bottom > 0 {
            hasSafeArea = 1
        }
        self.model?.jsEngine.callFunction(DocsJSCallBack(callback),
                                          params: ["brand": "apple",
                                                   "model": UIDevice.modelName,
                                                   "deviceId": deviceID,
                                                   "hasSafeArea": hasSafeArea],
                                          completion: nil)
    }
//    browserVC.topContainer.frame.maxY - browserVC.statusBar.frame.maxY
}

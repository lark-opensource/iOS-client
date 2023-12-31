//
//  GetSDKConfigHandler.swift
//  LarkWeb
//
//  Created by chenyingguang on 2019/1/4.
//

import Foundation
import Alamofire
import WebBrowser
import EEMicroAppSDK
import OPFoundation

class GetSDKConfigHandler: JsAPIHandler {
    static let settingsConfigKey = "h5sdk_dynamic_api"
    static let jsSettingParamsCdn = "{\"build\":\"cdn\"}"
    static let jsSettingParamsNpm = "{\"build\":\"npm\"}"
    let reqUrlStr: String?
    let tenantId: String?
    let userId: String?
    let deviceId: String?
    init(reqUrlStr: String?, tenantId: String?, userId: String?, deviceId: String?) {
        self.reqUrlStr = reqUrlStr
        self.tenantId = tenantId
        self.userId = userId
        self.deviceId = deviceId
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        BDPLogInfo(tag: .gadget, "start GetSDKConfig")
        guard let urlString = api.webView.url?.absoluteString else {
            callback.callbackFailure(param: NewJsSDKErrorAPI.badUrl(extraMsg: "url is nil"))
            BDPLogError(tag: .gadget, "GetSDKConfig: url is nil")
            return
        }
        guard let newConfigDict = EMAAppEngine.current()?.configManager?.minaConfig.getDictionaryValue(for: GetSDKConfigHandler.settingsConfigKey) else {
            BDPLogError(tag: .gadget, "GetSDKConfig: Settings white list is not contain")
            callback.callbackFailure(param: NewJsSDKErrorAPI.requestError)
            return
        }
        guard var newConfig = newConfigDict["data"] as? [String:Any] else {
            BDPLogError(tag: .gadget, "GetSDKConfig: Settings config error")
            callback.callbackFailure(param: NewJsSDKErrorAPI.wrongDataFormat)
            return
        }
        //js那边为了适配一些问题，新增了一个code字段，默认值为0
        /*
         返回的数据结构从{ apiInfoList: [], apiNameList: [] }
         改为
         { code: 0, data: { apiInfoList: [], apiNameList: [] } }
         */
        let code:Int
        if let codeConfig = newConfigDict["code"] as? Int {
            code = codeConfig
        } else {
            code = 0 //默认值0
        }
        var isMergeApiList = false
        if let domainList = newConfig["domainList"] as? [String] {
            let inDomainList =  domainList.first { (item) -> Bool in
                urlString.contains(item)
            }
            if inDomainList != nil {
                isMergeApiList = true
                BDPLogInfo(tag: .gadget, "GetSDKConfig: inDomainList is not nil")
            }
        }
        let urlConditionApiList = newConfig["urlConditionApiList"] as? [Any] ?? []
        let apiInfoList = newConfig["apiInfoList"] as? [Any] ?? []
        if let param = args["param"] as? String {
            if param == GetSDKConfigHandler.jsSettingParamsCdn {
                isMergeApiList = false
                BDPLogInfo(tag: .gadget, "GetSDKConfig: param is Cdn")
            }
            if param == GetSDKConfigHandler.jsSettingParamsNpm {
                isMergeApiList = true
                BDPLogInfo(tag: .gadget, "GetSDKConfig: param is Npm")
            }
        }
        if isMergeApiList {
            let newList = apiInfoList + urlConditionApiList
            newConfig["apiInfoList"] = newList
            BDPLogInfo(tag: .gadget, "GetSDKConfig: merge urlCondition")
        }
        newConfig.removeValue(forKey: "domainList")
        newConfig.removeValue(forKey: "urlConditionApiList")
        let result = ["code": code, "data": newConfig] as [String : Any]
        callback.callbackSuccess(param: result)
        BDPLogInfo(tag: .gadget, "end GetSDKConfig count:\(String(describing: (newConfig["apiInfoList"] as? [Any])?.count))")
    }

    func getSystemVersion() -> String {
        guard let info = Bundle.main.infoDictionary, let appVersion: String = info["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }
        return appVersion
    }
}

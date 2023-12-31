//
//  NativeAppManager.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/5/16.
//

import UIKit
import Swinject
import RxSwift
import LarkContainer
import LKCommonsLogging
import EENavigator
import LarkOpenPluginManager
import ECOProbe
import NativeAppPublicKit
import LarkOPInterface
import WebBrowser
import OPSDK

@objc
class NativeAppManager: NSObject, NativeAppManagerProtocol, NativeAppManagerInternalProtocol {
    
    var appIDArray: [String] = []
    var nativeAppGuideInfoDic: [String: NativeGuideInfo] = [:]
    lazy var nativeAppApiGateway: NativeAppApiGateway = {
        return NativeAppApiGateway()
    }()
    
    private var httpClient: OpenPlatformHttpClient?
    static let logger = Logger.oplog(NativeAppManager.self, category: "NativeApp")
    private let disposeBag = DisposeBag()
    
    private let resolver: UserResolver
    
    
    init(resolver: UserResolver) {
        self.resolver = resolver
        self.httpClient = try? resolver.resolve(assert: OpenPlatformHttpClient.self)
        super.init()
    }
    
    func getNativeAppGuideInfo() {
        self.appIDArray = NativeAppConnectManager.shared.appIDArray()
        Self.logger.info("NativeAppManager: check appIds:\(self.appIDArray)")
        let supportAppListApi = OpenPlatformAPI.getNativeAppGuideInfoAPI(app_ids: appIDArray, resolver: resolver)
        
        self.httpClient?.request(api: supportAppListApi).subscribe(onNext: { [weak self] result in
            Self.logger.info("request_get_native_app_guide_done,logid:\(result.lobLogID)")
            guard let self = self else {
                return
            }
            if let resultCode = result.code, resultCode == 0 {
                if let dataModel = result.buildDataModel(type: NativeAppGuideInfoListModel.self) {
                    Self.logger.info("native_app_guide_data_parse_success")
                    for appInfo in dataModel.guideInfos {
                        self.nativeAppGuideInfoDic[appInfo.key] = appInfo.value
                        Self.logger.info("NativeAppManager: check guide appId:\(appInfo.key), code:\(appInfo.value.code), tip is empty:\(appInfo.value.tip.isEmpty), tip:\(appInfo.value.tip == [:])")
                    }
                } else {
                    Self.logger.info("native_app_guide_data_parse_fail")
                }
            } else {
                Self.logger.info("get_native_app_guide_api_fail,code\(result.code)")
            }
        }, onError: { error in
            let logID = (error as NSError).userInfo[OpenPlatformHttpClient.ttLogIDKey] as? String
            Self.logger.error("request group bot list failed with backEnd-Error: \(error.localizedDescription),logid:\(logID)")
        }).disposed(by: self.disposeBag)
    }
    
    func setupContainer() {
        for appID in appIDArray {
            let uniqueID = OPAppUniqueID.init(appID: appID, identifier: nil, versionType: .current, appType: .thirdNativeApp)
            let config = NativeAppContainerConfig()
            let application = OPApplicationService.current.getApplication(appID: appID) ?? OPApplicationService.current.createApplication(appID: appID)
            if application.getContainer(uniqueID: uniqueID) == nil {
                application.createContainer(uniqueID: uniqueID, containerConfig: config)
            }
        }
    }
    
    func setupNativeAppManager() {
        NativeAppConnectManager.shared.setupNativeAppManager(manager: self)
    }
    
    func pushNativeAppViewController(from: UIViewController, to: UIViewController) {
        self.resolver.navigator.push(to, from: from)
    }

    func popNativeAppViewController(from: UIViewController) {
        self.resolver.navigator.pop(from: from)
    }
    
    func invokeOpenApi(appID: String, apiName: String, params: [String : Any], callback: @escaping (NativeAppOpenApiModel) -> Void) {
        self.setupContainerIfNeeded(appID: appID)
        self.nativeAppApiGateway.invokeOpenApi(appID:appID, apiName: apiName, params: params, callback:callback)
    }
    
    private func setupContainerIfNeeded(appID: String) {
        let uniqueID = OPAppUniqueID.init(appID: appID, identifier: nil, versionType: .current, appType: .thirdNativeApp)
        let config = NativeAppContainerConfig()
        let application = OPApplicationService.current.getApplication(appID: appID) ?? OPApplicationService.current.createApplication(appID: appID)
        if application.getContainer(uniqueID: uniqueID) == nil {
            application.createContainer(uniqueID: uniqueID, containerConfig: config)
        }
    }
    
    func setCookie(cookie: HTTPCookie) {
        HTTPCookieStorage.shared.setCookie(cookie)
        let padding = max(1, (Int(cookie.value.count/4)))
        let clipValue = cookie.value.cookie_mask(padding: padding)
        Self.logger.info("NativeAppManager sync cookie to Native, doamin:\(cookie.domain), path:\(cookie.path), name:\(cookie.name),value:\(clipValue),secure:\(cookie.isSecure),isHTTPOnly:\(cookie.isHTTPOnly),expires:\(cookie.expiresDate as Any)")
    }
    
    func appendUserAgent(customUA: String) {
        if let appendUA = WebBrowser.nativeAppendUA {
            Self.logger.info("NativeAppManager read appendUserAgent string at present: \(appendUA)")
        } else {
            Self.logger.info("NativeAppManager read appendUserAgent string at present: nil")
        }
        WebBrowser.nativeAppendUA = customUA
        Self.logger.info("NativeAppManager set appendUserAgent string to: \(customUA)")
    }

}

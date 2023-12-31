//
//  WebAppAPINetworkInterface.swift
//  LarkOpenPlatform
//
//  Created by jiangzhongping on 2023/12/1.
//

import LarkContainer
import LKCommonsLogging
import ECOInfra
import OPFoundation
import LarkAccountInterface
import SwiftyJSON
import LarkLocalizations
import LarkSetting

public final class WebAppAPINetworkInterface {
        
    static let logger = Logger.oplog(WebAppAPINetworkInterface.self, category: "ECONetwork")
        
    public static func getH5AppInfo(larkVer: String,
                                    appId: String,
                                    downgrade: Bool = false,
                                    resolver: UserResolver,
                                    trace: OPTrace,
                                    completionHandler: @escaping (String?, String?, String?, String?, Bool, H5OfflineType, Error?) -> Void) {
        logger.info("exec getH5AppInfo api, downgrade:\(downgrade)")
        let urlPath: APIUrlPath = downgrade ? APIUrlPath.appLinkH5AppInfo : APIUrlPath.appLinkH5AppInfoWithOffline
        let alias: DomainKey = downgrade ? .open : .internalApi
        let url = WebAppAPINetworkUtil.getRequestURLString(alias, path: urlPath.rawValue) ?? ""
        
        let params = ["locale" : LanguageManager.currentLanguage.rawValue.lowercased(),
                      "larkVersion": larkVer,
                      "appId": appId]
        
        var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
        if let session = sessionKey(resolver) {
            header[APIHeaderKey.Session.rawValue] = session
            header[APIHeaderKey.Cookie.rawValue] = "\(APICookieKey.session.rawValue)=\(session)"
        } else {
            logger.error("session is null")
        }
        
        let networkContext = OpenECONetworkContext(trace: trace, source: .web)
        let requestCompletionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { response, error in
            
            let logID = (response?.response.allHeaderFields[APIHeaderKey.LogID.rawValue]) ?? "empty logid"
            let path: String = response?.request.url?.path ?? ""
            let statusCode = response?.response.statusCode ?? OpenPlatform.errorUndefinedCode
        
            logger.info("request \(path), response status code:\(statusCode), logid:\(logID)")
            
            if let error = error {
                logger.error("request \(path) failed, error:\(error.localizedDescription)")
                completionHandler(nil, nil, nil, nil, false, H5OfflineType.all, error)
                return
            }
            
            guard let response = response,
                  let result = response.result else {
                logger.error("request \(path) failed response or result is nil")
                let error = NSError(domain: OpenPlatform.errorDomain,
                                    code: statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "getH5AppInfo error"])
                completionHandler(nil, nil, nil, nil, false, H5OfflineType.all, error)
                return
            }
            
            logger.debug("getAppInfo success response \(result)")
            guard let resultCode = result["code"] as? Int, let resultData = result["data"] as? [String: Any] else {
                let error = NSError(domain: OpenPlatform.errorDomain,
                                  code: statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "getH5AppInfo response data error"])
                completionHandler(nil, nil, nil, nil, false, H5OfflineType.all, error)
                return
            }
        
            let appInfoJson = JSON(resultData["appInfo"] ?? [:])
            if resultCode == 0, appInfoJson != JSON.null, AppInfo(json: appInfoJson).offlineEnable {
                //开启离线包能力，先走离线包逻辑
                let inf = AppInfo(json: appInfoJson)
                completionHandler(inf.getH5AppUrl(), inf.getName(), inf.getIconKey(), inf.getIconURL(), inf.offlineEnable, inf.h5OfflineType, nil)
            } else if resultCode == 0, appInfoJson != JSON.null,
                      let h5AppUrl = AppInfo(json: appInfoJson).getH5AppUrl() {
                let inf = AppInfo(json: appInfoJson)
                completionHandler(h5AppUrl, inf.getName(), inf.getIconKey(), inf.getIconURL(), false, inf.h5OfflineType, nil)
            } else if resultCode == 0,
                      let guideUrl = resultData["guideUrl"] as? String {
                completionHandler(guideUrl, nil, nil, nil, false, H5OfflineType.all, nil)
            } else {
                let msg = result["msg"] as? String ?? ""
                let error = NSError(domain: OpenPlatform.errorDomain,
                                  code: resultCode,
                                  userInfo: [NSLocalizedDescriptionKey: "getH5AppInfo \(msg)"])
                completionHandler(nil, nil, nil, nil, false, H5OfflineType.all, error)
            }
        }
        
        let serviceTask = service.post(url: url, header: header, params: params, context: networkContext, requestCompletionHandler: requestCompletionHandler)
        if let task = serviceTask {
            service.resume(task: task)
        } else {
            logger.error("create task fail")
            let error = NSError(domain: OpenPlatform.errorDomain,
                                code: OpenPlatform.errorUndefinedCode,
                                userInfo: [NSLocalizedDescriptionKey: "create task fail"])
            completionHandler(nil, nil, nil, nil, false, H5OfflineType.all, error)
        }
    }
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    private static func sessionKey(_ resolver: UserResolver) -> String? {
        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            logger.error("PassportUserService impl is nil")
            return nil
        }
        return userService.user.sessionKey
    }
}



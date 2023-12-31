//
//  AppLinkHttp.swift
//  LarkAppLinkSDK
//
//  Created by 李论 on 2020/4/24.
//

import UIKit
import Alamofire
import Swinject
import LarkSetting
import LKCommonsLogging
import ECOInfra
import LarkContainer

@objc final class OpenECONetworkAppLinkContext: NSObject, ECONetworkServiceContext {
    private let trace: OPTrace
    private let source: ECONetworkRequestSource
    
    @objc init(trace: OPTrace, source: ECONetworkRequestSource) {
        self.trace = trace
        self.source = source
    }
    
    func getTrace() -> OPTrace {
        return trace
    }
    
    func getSource() -> ECONetworkRequestSourceWapper? {
        return ECONetworkRequestSourceWapper(source: source)
    }
}

class AppLinkHttp: NSObject {
    private let resolver: Resolver
    private static let logger = Logger.oplog(AppLinkHttp.self, category: "AppLinkSDK")
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    private static func basicUseECONetworkEnabled() -> Bool {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.basic.use.econetwork.enable"))
    }

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private func domain(_ alias: DomainKey) -> String {
        DomainSettingManager.shared.currentSetting[alias]?.first ?? ""
    }
}

extension AppLinkHttp {
    private func delayRelease() {
    }

    private func parseAppLinkPath() -> String {
        return "/open-apis/applink/longlink/v1/get"
    }

    /// AppLink短链生成长链接口
    /// - Method: GET
    private func parseAppLinkUrl(shortLink: String,
                                 businessTag: String) -> URL? {
        var urlComponets = URLComponents()
        urlComponets.scheme = "https"
        urlComponets.host = domain(.open)
        urlComponets.path = parseAppLinkPath()
        return urlComponets.url
    }

    public func parseShortLink(link: String,
                               from: String,
                               onComplete: @escaping (String, [String: Any], Error?) -> Void) {
        guard let reqUrl = parseAppLinkUrl(shortLink: link, businessTag: from) else {
            AppLinkHttp.logger.error(logId: "compose url error \(link) \(from)")
            return
        }
        
        let parameters: [String: String] = [
            "businessTag": from,
            "shortLink": link
        ]
        let onError: (Error) -> Void = { [weak self] error in
            AppLinkHttp.logger.error("parse result error \(error)")
            self?.delayRelease()
            var dataDic: [String: Any] = ["networkErr": true]
            onComplete(link, dataDic, nil)
        }
        let onSuccess: ([String: Any]?) -> Void = { [weak self] result in
            AppLinkHttp.logger.info(logId: "parse result \(String(describing: result))")
            self?.delayRelease()
            var dataDic: [String: Any] = [:]
            dataDic["networkErr"] = false
            guard let result = result,
                  let code = result["code"] as? Int, code == 0,
                  let data = result["data"] as? [String: Any],
                  let longLink = data["link"] as? String,
                  !longLink.isEmpty else {
                AppLinkHttp.logger.error("parse result to json failed")
                dataDic["code"] = result?["code"]
                dataDic["msg"] = result?["msg"]
                onComplete(link, dataDic, nil)
                return
            }
            onComplete(longLink, dataDic, nil)
        }
        
        if Self.basicUseECONetworkEnabled() {
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { response, error in
                if let error = error {
                    onError(error)
                    return
                }
                onSuccess(response?.result)
            }
            let context = OpenECONetworkAppLinkContext(trace: OPTraceService.default().generateTrace(), source: .other)
            let task = Self.service.get(url: reqUrl.absoluteString, header: [:], params: parameters, context: context, requestCompletionHandler: completionHandler)
            if let task = task {
                Self.service.resume(task: task)
            } else {
                AppLinkHttp.logger.error("url econetwork task failed")
            }
            return
        }
        
        Alamofire.request(reqUrl, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success:
                onSuccess(response.result.value as? [String: Any])
            case .failure(let error):
                onError(error)

            @unknown default:
                break
            }
        }
    }
}

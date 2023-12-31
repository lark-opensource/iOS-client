//
//  OpenPlatformHttpClient.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2019/9/17.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON
import Swinject
import LarkRustHTTP
import LarkAccountInterface
import RustPB
import LarkAppConfig
import LarkEnv
import LKCommonsLogging
import LarkFeatureGating
import ECOInfra
import LarkContainer

final class OpenPlatformHttpClient {
    public static let lobLogIDKey = "lob-logid"
    public static let ttLogIDKey = "x-tt-logid"
    public let disposeBag = DisposeBag()
    
    private static let sharedSessionManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30    // 超时时间不要太小，否则低端机型在Lark启动后一端时间容易超时
        configuration.protocolClasses = [ECOMonitorRustHttpURLProtocol.self]
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    private let resolver: UserResolver
    private static let logger = Logger.oplog(OpenPlatformHttpClient.self,
                                    category: "OpenPlatformHttpClient")

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func request<R>(api: OpenPlatformAPI) -> Observable<R> where R: APIResponse {
        var urlComponets = URLComponents()
        urlComponets.scheme = "https"
        urlComponets.host = hostForCurrentEnv(scope: api.scope)
        urlComponets.path = pathForCurrentEnv(scope: api.scope, path: api.path)
        if api.session {
            injectSessionHeader(api)
        }
        let cookieKey = APIHeaderKey.Cookie.rawValue
        var cookieHeader: String = api.headers[cookieKey] ?? ""
        if !api.cookies.isEmpty {
            api.cookies.forEach { (arg0) in
                let (key, value) = arg0
                if !cookieHeader.contains("\(key)=") {
                    if cookieHeader.isEmpty {
                        cookieHeader += "\(key)=\(value)"
                    } else {
                        cookieHeader += ";\(key)=\(value)"
                    }
                }
            }
            api.appendHeader(key: .Cookie, value: cookieHeader)
        }
        return Observable<R>.create({ (observer) -> Disposable in
            if let url = urlComponets.url {
                OpenPlatformHttpClient.sharedSessionManager.request(url,
                             method: api.method,
                             parameters: api.getParameters(),
                             encoding: api.parameterEncode,
                             headers: api.headers
                    ).responseJSON { (response) in
                    var logid = response.response?.allHeaderFields[OpenPlatformHttpClient.ttLogIDKey] as? String
                    if logid.isEmpty {
                        logid = response.response?.allHeaderFields[OpenPlatformHttpClient.lobLogIDKey] as? String
                    }
                    OpenPlatformHttpClient.logger.info("request \(url.path) response status code:\(response.response?.statusCode),logid:\(logid)")

                    switch response.result {
                    case .success(let value):
                        let jsonValue = JSON(value)
                        var result = R(json: jsonValue, api: api)
                        result.lobLogID = logid
                        observer.onNext(result)
                        observer.onCompleted()
                    case .failure(let error):
                        OpenPlatformHttpClient.logger.error("request \(url.path) failed error: \(error.localizedDescription)")
                        let nsError = error as NSError
                        var userInfo: [String: Any] = nsError.userInfo
                        if let logId = logid {
                            userInfo[OpenPlatformHttpClient.lobLogIDKey] = logId
                        }
                        observer.onError(NSError(domain: nsError.domain,
                                                    code: nsError.code,
                                                    userInfo: userInfo))
                        @unknown default: break
                        }
                    }
            } else {
                observer.onError(RxError.unknown)
            }
            return Disposables.create {}
        })
    }

    private func injectSessionHeader(_ api: OpenPlatformAPI) {
        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            OpenPlatformHttpClient.logger.error("OpenPlatformHttpClient: PassportUserService impl is nil")
            return
        }
        let session = userService.user.sessionKey
        _ = api.appendHeader(key: api.sessionHeaderKey, value: session)
    }

    private func hostForCurrentEnv(scope: OpenPlatformAPI.Scope) -> String {
        switch scope {
        case .microapp,
             .parseApplink,
             .generateShortAppLink,
             .messageActionContent:
            return domain(DomainSettings.open)
        case .uploadInfo:
            return domain(DomainSettings.open)
        case .messageCard:
            return domain(DomainSettings.openMsgCard)
        case .appcenter,
             .appplus,
             .plusExplorer,
             .configPlusMenuUserDisplay,
             .msgActionExplorer,
             .appInterface,
             .personalizedAvatar:
            return domain(DomainSettings.openAppcenter3)
        case .shareApp:
            return domain(DomainSettings.internalApi)
        case .groupBot,
            .menuPanel,
            .applyForUse,
            .appSetting,
            .nativeApp:
            return domain(DomainSettings.openAppInterface)
        case .groupBotManage:
            return domain(DomainSettings.open)
        case .messageCardStyle, .messageCardTransform:
            return domain(.openMsgCard)
        case .clockIn:
            return domain(.emsOA)
        case .customURL(let host, _):
            return host
        }
    }

    private func domain(_ alias: DomainSettings) -> String {
        guard let appConfig = try? resolver.resolve(assert: AppConfiguration.self) else {
            return ""
        }
        return appConfig.settings[alias]?.first ?? ""
    }

    private func pathForCurrentEnv(scope: OpenPlatformAPI.Scope, path: APIUrlPath) -> String {
        switch scope {
        case .microapp,
             .messageCard,
             .appcenter,
             .parseApplink,
             .generateShortAppLink,
             .plusExplorer,
             .configPlusMenuUserDisplay,
             .msgActionExplorer,
             .messageActionContent,
             .shareApp,
             .groupBot,
             .groupBotManage,
             .appSetting,
             .menuPanel,
             .applyForUse,
             .personalizedAvatar,
             .appInterface,
             .messageCardStyle,
             .messageCardTransform,
             .clockIn,
             .nativeApp:
            return path.rawValue
        case .uploadInfo:
            return uploadInfoPathPrefixForCurrentEnv().rawValue + path.rawValue
        case .appplus:
            return appplusPathPrefixForCurrentEnv().rawValue + path.rawValue
        case .customURL(_, let path):
            return path
        }
    }

    private func appplusPathPrefixForCurrentEnv() -> MinaAPIUrlPrefix {
        let envType = EnvManager.env.type
        switch envType {
        case .release:
            return .appplus_release
        case .preRelease:
            return .appplus_prelease
        case .staging:
            return .appplus_staging
        default:
            return .appplus_release
        }
    }

    private func uploadInfoPathPrefixForCurrentEnv() -> MinaAPIUrlPrefix {
        return .online
    }

}

typealias DomainSettings = InitSettingKey

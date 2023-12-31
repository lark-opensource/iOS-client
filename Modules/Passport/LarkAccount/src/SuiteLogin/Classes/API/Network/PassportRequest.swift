//
//  PassportRequest.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation
import LKCommonsLogging

enum MiddlewareType: Int {
    case fetchDeviceId
    case captcha
    case checkNetwork
    case requestCommonHeader
    case saveToken
    case costTimeRecord
    case saveEnv
    case crossUnit
    case injectParams
    case pwdRetry
    case toastMessage
    case checkSession
    case updateDomain
    case checkLocalSecEnv
    case fetchUniDeviceId
}

class RequestContext {
    var error: V3LoginError?
    var token: String?
    var needRetry: Bool = false
    var extra: [String: Any] = [:]
    var state: Request.State = .noTriger

    var extraHeaders: [String: String] = [:]
    var extraParams: [String: Any] = [:]
    var uniContext: UniContextProtocol?
}

enum HTTPMiddlewareAspect {
    case request
    case response
    case error
}

typealias HTTPMiddlewarePriority = CGFloat

extension HTTPMiddlewarePriority {
    static let highest: CGFloat = 1000.0
    static let high: CGFloat = 750.0
    static let medium: CGFloat = 500.0
    static let low: CGFloat = 250.0
    static let lowest: CGFloat = 0.0
}

typealias HTTPMiddlewareConfig = [HTTPMiddlewareAspect: HTTPMiddlewarePriority]

protocol HTTPMiddlewareProtocol {
    func config() -> HTTPMiddlewareConfig
    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    )
}

class Request {
    enum Method: String {
        case get
        case post
        case patch
        case delete
    }

    enum Domain: CustomStringConvertible {
        // 旧版本 api 域名
        case api(usingPackageDomain: Bool = false)
        // 新帐号模型下 passportAccount 域名
        case passportAccounts(usingPackageDomain: Bool = false)
        // open 域名（目前在和开平授权的场景中使用）
        case open
        // 自定义域名，不包含 https://
        case custom(domain: String)

        var description: String {
            switch self {
            case .api(let usingPackageDomain):
                return "[api] usingPackageDomain: \(usingPackageDomain)"
            case .passportAccounts(let usingPackageDomain):
                return "[accounts] usingPackageDomain: \(usingPackageDomain)"
            case .open:
                return "[open]"
            case .custom(let domain):
                return "[custom] domain: \(domain)"
            }
        }
    }

    enum Header {
        case passportToken
        case pwdToken
        case suiteSessionKey
        case verifyToken
        case flowKey
        case sessionKeys
        case proxyUnit
        case authFlowKey
    }

    enum State {
        case noTriger
        case running
        case finish
    }
}

protocol RequestBody {
    func getParams() -> [String: Any]
}

extension Dictionary: RequestBody where Key == String {
    func getParams() -> [String: Any] { self }
}

class PassportRequest<ResponseData: ResponseV3> {
    let logger = {
        Logger.plog(HTTPClient.self, category: "SuiteLogin.PassportRequest")
    }()

    var path: String { "\(pathPrefix)/\(pathSuffix)" }

    var host: String = ""
    var url: String { "\(host)\(path)" }

    var pathPrefix: String
    var pathSuffix: String

    var domain: Request.Domain = .api(usingPackageDomain: false)
    var headers: [String: String] = [:]
    var reserveHeaders: [String: String] = [:]
    var body: RequestBody = [String: Any]()
    var method: Request.Method = .post
    var timeout: TimeInterval?

    var requiredHeader: Set<Request.Header> = Set()

    private(set) var commonMiddlewareTypes: Set<MiddlewareType>
    var middlewareTypes: Set<MiddlewareType>

    var appId: APPID?
    var sceneInfo: [String: String]?

    var retryTime: Int = 0

    let maxRetryTime: Int = 1

    var context: RequestContext = RequestContext()
    var response: PassportResponse = PassportResponse<ResponseData>()

    var flowKey: String? {
        return getCombinedHeaders()[CommonConst.flowKey]
    }

    weak var task: URLSessionTask?

    required init(pathPrefix: String, pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        self.pathPrefix = pathPrefix
        self.pathSuffix = pathSuffix
        self.context.uniContext = uniContext

        let enabled = PassportStore.shared.configInfo?.config().getEnableFetchDeviceIDForAllRequests() ?? V3NormalConfig.defaultEnableFetchDeviceIDForAllRequests
        if enabled {
            self.commonMiddlewareTypes = Set([.fetchDeviceId, .requestCommonHeader, .updateDomain])
        } else {
            self.commonMiddlewareTypes = Set([.requestCommonHeader, .updateDomain])
        }
        self.middlewareTypes = []
    }

    func add(headers: [String: String]) {
        self.headers.merge(headers) { (_, new) -> String in
            let msg = "header key conflict old header not used"
            logger.error(msg)
            assertionFailure(msg)
            return new
        }
    }

    func retryRequest() -> Self {
        let request = Self(pathPrefix: pathPrefix, pathSuffix: pathSuffix)
        request.domain = domain
        request.headers = headers
        request.body = body
        request.method = method

        request.requiredHeader = requiredHeader
        request.middlewareTypes = middlewareTypes

        request.appId = appId
        request.sceneInfo = sceneInfo
        request.retryTime = retryTime + 1
        return request
    }

    func getCombinedHeaders() -> [String: String] {
        var combinedHeaders = headers
        /// 不要随意修改合并策略！
        combinedHeaders.merge(context.extraHeaders) { (_, new) -> String in
            let msg = "header key conflict new key header override old key"
            logger.warn(msg)
            return new
        }
        combinedHeaders.merge(reserveHeaders) { (_, new) -> String in
            let msg = "reserve header key conflict new key reserve header override old key"
            logger.warn(msg)
            return new
        }
        return combinedHeaders
    }

    func getCombinedParams() -> [String: Any] {
        var combinedParams = body.getParams()
        /// 不要随意修改合并策略！
        combinedParams.merge(context.extraParams) { (_, new) -> Any in
            let msg = "params key conflict new key param override old key"
            logger.warn(msg)
            return new
        }
        return combinedParams
    }

    @discardableResult
    func required(_ header: Request.Header) -> Self {
        requiredHeader.insert(header)
        return self
    }

    @discardableResult
    func no(_ header: Request.Header) -> Self {
        requiredHeader.remove(header)
        return self
    }

    @discardableResult
    func required(_ middlewareType: MiddlewareType) -> Self {
        middlewareTypes.insert(middlewareType)
        return self
    }

    @discardableResult
   func no(_ middlewareType: MiddlewareType) -> Self {
       middlewareTypes.remove(middlewareType)
       return self
   }

    func cancelTask() {
        logger.info("cancel task: \(task?.taskIdentifier ?? -1)")
        task?.cancel()
    }
    
    func configDomain(serverInfo: ServerInfo) {
        let usePackageDomain = serverInfo.usePackageDomain ?? false
        domain = .passportAccounts(usingPackageDomain: usePackageDomain)
    }
}

class PassportResponse<ResponseData: ResponseV3> {
    var header: ResponseHeader?
    var data: Data?
    var dictionary: NSDictionary?
    var resp: ResponseData?

    func transform(dictionary: NSDictionary, data: Data) throws -> ResponseData {
        self.data = data
        self.dictionary = dictionary
        let resp = try ResponseData(dict: dictionary)
        self.resp = resp
        return resp
    }
}

class AfterLoginRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {
    required init(pathPrefix: String, pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        super.init(pathPrefix: pathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
        self.middlewareTypes = [
            .captcha,
            .requestCommonHeader,
            .toastMessage,
            .saveToken
        ]
        self.requiredHeader = [.suiteSessionKey, .sessionKeys, .flowKey, .proxyUnit]

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }
}

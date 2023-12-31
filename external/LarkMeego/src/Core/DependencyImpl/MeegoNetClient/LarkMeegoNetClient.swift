//
//  LarkMeegoNetClient.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import TTNetworkManager
import LarkMeegoLogger
import LKCommonsTracker
import LarkMeegoNetClient
import LarkSetting

// 埋点详情可参考 https://bytedance.feishu.cn/wiki/wikcnlRvpO2GiBA3AHJegBsdjXe
enum MeegoNetworkEvent {
    static let eventName = "meego_network"
    enum MetricKey {
        static let proxy = "proxy"
        static let dns = "dns"
        static let connect = "connect"
        static let ssl = "ssl"
        static let send = "send"
        static let wait = "wait"
        static let receive = "receive"
        static let total = "total"
    }
    enum CategoryKey {
        static let host = "host"
        static let urlPath = "url_path"
        static let httpStatusCode = "http_status_code"
        static let bizErrorCode = "biz_error_code"
        static let apiEnv = "api_env"
        static let larkGW = "lark_gw"
        static let netLibType = "net_lib_type"
        static let resultType = "result_type"
        static let tenantBrand = "tenant_brand"
    }
    enum ExtraKey {
        static let requestId = "request_id"
        static let errorMsg = "error_msg"
    }
}

enum MeegoChannelCookieKey {
    static let channelKey = "login_channel_id"    // 渠道一期 渠道key
    static let tenantKey = "login_tenant_key"     // 渠道二期 租户key
    static let assetKey = "login_asset_key"       // 渠道二期 资产key
}

extension RequestMethod {
    var httpMethod: String {
        switch self {
        case .get:
            return HttpMethod.GET
        case .post:
            return HttpMethod.POST
        case .put:
            return HttpMethod.PUT
        case .delete:
            return HttpMethod.DELETE
        }
    }
}

public class LarkMeegoNetClient: MeegoNetClient {
    public init(_ baseURL: URL, config: MeegoNetClientConfig) {
        self.meegoNetClientConfig = config
        super.init(baseURL)
    }

    let meegoNetClientConfig: MeegoNetClientConfig
    public override var config: MeegoNetClientConfig {
        return meegoNetClientConfig
    }

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter
    }()

    private lazy var apiEnv: String = {
        if self.config.isPPE {
            return "ppe"
        } else if self.config.isBoe {
            return "boe"
        } else {
            return "online"
        }
    }()

    private lazy var tenantBrand: String = {
        return self.config.tenantBrand
    }()

    // csrf hookDomain: sth like feishu.cn
    // 目前 Native网络库、Flutter网络库插件、Account中有相似实现。
    // 后续可以统一下沉或者合规评估废弃移动端csrf校验
    static let hookDomain: String = {
        let projectDomainSetting = DomainSettingManager.shared.currentSetting["mg_project"]?.first

        guard let domainComponentsArray = projectDomainSetting?.components(separatedBy: "."), domainComponentsArray.count > 2 else {
            return ""
        }

        let hookDomainStr = domainComponentsArray[domainComponentsArray.endIndex - 2] + "." + domainComponentsArray[domainComponentsArray.endIndex - 1]

        return hookDomainStr
    }()

    // injectDomain --> .feishu.cn
    static let injectDomain: String = {
        return "." + LarkMeegoNetClient.hookDomain
    }()

    // 切换租户、退出登录时，主动清除Channel相关Cookie
    public static func cleanChannelCookie() {
        let targetDomain = LarkMeegoNetClient.injectDomain

        let targetCookies = HTTPCookieStorage.shared.cookies?.filter({
            (
                $0.name == MeegoChannelCookieKey.channelKey      // 渠道一期 渠道key
                || $0.name == MeegoChannelCookieKey.tenantKey    // 渠道二期 租户key
                || $0.name == MeegoChannelCookieKey.assetKey     // 渠道二期 资产key
            ) && $0.domain == targetDomain
        }) ?? []
        for cookie in targetCookies {
            MeegoLogger.info("cleanChannelCookie name:\(cookie.name)")
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }

    public override func sendRequest<T: Request>(_ request: T, completionHandler: @escaping (Result<T.ResponseType, APIError>) -> Void) where T: Request {
        guard let url = URL(string: request.endpoint, relativeTo: baseURL) else {
            MeegoLogger.warn("sendRequest fail for url is nil")
            return
        }
        let urlString = url.absoluteString

        var headers = config.commonHeaders().merging(request.customHeaders) { $1 }
        /// check and set csrf token
        headers[MeegoHeaderKeys.csrfToken] = getCsrfTokenInCookie()
        /// set logid in header
        let logId = getLogId()
        headers[MeegoHeaderKeys.ttLogId] = logId
        /// 告知TLB，请求路由到Lark网关。
        headers[MeegoHeaderKeys.switchToLarkGateway] = "1"
        var requestSerializerClass = getRequestSerializerClass(with: request.method)

        MeegoLogger.info("sendRequest with LogId:\(logId)")
        TTNetworkManager.shareInstance().requestForBinary(
            withResponse: urlString,
            params: request.parameters,
            method: request.method.httpMethod,
            needCommonParams: request.needCommonParams,
            headerField: headers,
            enableHttpCache: false,
            autoResume: true,
            isCustomizedCookie: false,
            requestSerializer: requestSerializerClass,
            responseSerializer: nil,
            progress: nil,
            callback: { [host = baseURL.host ?? "", path = request.endpoint, logId, apiEnv, tenantBrand]
                (error: Error?, responseObj: Any?, response: TTHttpResponse?) in

                let httpStatusCode: Int = response?.statusCode ?? MeegoNetClientErrorCode.unknownError
                let switchToLarkGateway: String? = response?.allHeaderFields?[MeegoHeaderKeys.switchToLarkGateway] as? String

                // TTNet callback with error.
                if let error = error {
                    MeegoLogger.error("response from \(host) | status code: \(httpStatusCode) | \(logId) | lgw: \(switchToLarkGateway) | errorMsg:\(error.localizedDescription).")

                    var apiError = APIError(host: host, path: path, httpStatusCode: httpStatusCode, logId: logId)
                    apiError.errorMsg = error.localizedDescription
                    apiError.ttnetErrorNum = error._userInfo?[TTNetErrorUserInfoKeys.errorNum] as? Int

                    LarkMeegoNetClient.trackNetReqError(apiError: apiError,
                                                        host: host,
                                                        urlPath: path,
                                                        apiEnv: apiEnv,
                                                        larkGW: switchToLarkGateway,
                                                        tenantBrand: tenantBrand)

                    completionHandler(.failure(apiError))
                } else {
                    // Response data is invalid.
                    guard let responseData = responseObj as? Data else {
                        MeegoLogger.error("Response data is invalid from \(host) | status code: \(httpStatusCode) | \(logId) | lgw: \(switchToLarkGateway)")

                        var apiError = APIError(host: host, path: path, httpStatusCode:
                                                    MeegoNetClientErrorCode.invalidResponseData, logId: logId)
                        apiError.errorMsg = "invalidResponseData"

                        LarkMeegoNetClient.trackNetReqError(apiError: apiError,
                                                            host: host,
                                                            urlPath: path,
                                                            apiEnv: apiEnv,
                                                            larkGW: switchToLarkGateway,
                                                            tenantBrand: tenantBrand)

                        completionHandler(.failure(apiError))
                        return
                    }

                    let result = T.ResponseType.build(from: responseData)
                    switch result {
                    case .success(let responseModel):
                        MeegoLogger.info("fetch data success from \(host) | status code: \(httpStatusCode) | \(logId) | lgw: \(switchToLarkGateway)")

                        LarkMeegoNetClient.trackNetReqSuccess(with: response,
                                                              host: host,
                                                              urlPath: path,
                                                              httpStatusCode: httpStatusCode,
                                                              logId: logId,
                                                              apiEnv: apiEnv,
                                                              larkGW: switchToLarkGateway,
                                                              tenantBrand: tenantBrand)

                        completionHandler(result)
                    case .failure(let error):
                        MeegoLogger.error("fetch data fail \(host) | status code: \(httpStatusCode) | \(logId) | lgw: \(switchToLarkGateway)")

                        var apiError = APIError(host: host, path: path, httpStatusCode: error.httpStatusCode, logId: logId)
                        apiError.errorMsg = error.errorMsg

                        LarkMeegoNetClient.trackNetReqError(apiError: apiError,
                                                            host: host,
                                                            urlPath: path,
                                                            apiEnv: apiEnv,
                                                            larkGW: switchToLarkGateway,
                                                            tenantBrand: tenantBrand)

                        completionHandler(.failure(apiError))
                    }
                }
            }, callbackInMainThread: false)
    }
}

private extension LarkMeegoNetClient {
    @inline(__always)
    func getRequestSerializerClass(with requestMethod: RequestMethod) -> TTHTTPRequestSerializerProtocol.Type? {
        var requestSerializerClass: TTHTTPRequestSerializerProtocol.Type?
        switch requestMethod {
        case .get:
            requestSerializerClass = TTDefaultHTTPRequestSerializer.self
        case .post,
             .put,
             .delete:
            requestSerializerClass = TTPostDataHttpRequestSerializer.self
        }
        return requestSerializerClass
    }

    func getCsrfTokenInCookie() -> String {
        var csrfToken = ""
        // 尝试从cookie中读取meego_csrf_token
        if let cookies = HTTPCookieStorage.shared.cookies,
           let sessionCookie = cookies.first(where: { $0.name == MeegoHeaderKeys.CookieName.csrfToken && $0.domain.contains(LarkMeegoNetClient.hookDomain) }),
           let properties = sessionCookie.properties {

            csrfToken = properties[.value] as? String ?? ""
            MeegoLogger.info("get csrfNekot in cookie")
        }

        // 如果cookie中没有meego_csrf_token => native侧生成并种到cookie中.
        if csrfToken.isEmpty {
            if let cookies = HTTPCookieStorage.shared.cookies,
               let sessionCookie = cookies.first(where: { $0.name == "session" && $0.domain.contains(LarkMeegoNetClient.hookDomain) }),
               var properties = sessionCookie.properties {
                // Native侧生成csrfToken
                csrfToken = UUID().uuidString

                properties[.name] = MeegoHeaderKeys.CookieName.csrfToken
                properties[.value] = csrfToken
                properties[.domain] = LarkMeegoNetClient.injectDomain
                if let csrfTokenCookie = HTTPCookie(properties: properties) {
                    HTTPCookieStorage.shared.setCookie(csrfTokenCookie)
                    MeegoLogger.info("set csrfNekot in cookie")
                }
            }
        }
        return csrfToken
    }

    func getLogId() -> String {
        let timeStr = dateFormatter.string(from: Date())
        var uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return timeStr + uuid
    }

    static func trackNetReqSuccess(with response: TTHttpResponse?,
                                   host: String,
                                   urlPath: String,
                                   httpStatusCode: Int,
                                   logId: String,
                                   apiEnv: String,
                                   larkGW: String?,
                                   tenantBrand: String) {
        guard let timingInfo = response?.timinginfo else {
            return
        }

        let metric: [String: Any] = [
            MeegoNetworkEvent.MetricKey.proxy: timingInfo.proxy,
            MeegoNetworkEvent.MetricKey.dns: timingInfo.dns,
            MeegoNetworkEvent.MetricKey.connect: timingInfo.connect,
            MeegoNetworkEvent.MetricKey.ssl: timingInfo.ssl,
            MeegoNetworkEvent.MetricKey.send: timingInfo.send,
            MeegoNetworkEvent.MetricKey.wait: timingInfo.wait,
            MeegoNetworkEvent.MetricKey.receive: timingInfo.receive,
            MeegoNetworkEvent.MetricKey.total: timingInfo.total
        ]
        let slardarEvent = SlardarEvent(
            name: MeegoNetworkEvent.eventName,
            metric: metric,
            category: [
                MeegoNetworkEvent.CategoryKey.host: host,
                MeegoNetworkEvent.CategoryKey.urlPath: urlPath,
                MeegoNetworkEvent.CategoryKey.httpStatusCode: httpStatusCode,
                MeegoNetworkEvent.CategoryKey.apiEnv: apiEnv,
                MeegoNetworkEvent.CategoryKey.larkGW: larkGW ?? "",
                MeegoNetworkEvent.CategoryKey.netLibType: "native",
                MeegoNetworkEvent.CategoryKey.resultType: "success",
                MeegoNetworkEvent.CategoryKey.tenantBrand: tenantBrand
            ],
            extra: [
                MeegoNetworkEvent.ExtraKey.requestId: logId
            ]
        )
        Tracker.post(slardarEvent)
    }

    static func trackNetReqError(apiError: APIError,
                                 host: String,
                                 urlPath: String,
                                 apiEnv: String,
                                 larkGW: String?,
                                 tenantBrand: String) {
        let httpStatusCode = apiError.ttnetErrorNum ?? apiError.httpStatusCode

        let slardarEvent = SlardarEvent(
            name: MeegoNetworkEvent.eventName,
            metric: [:],
            category: [
                MeegoNetworkEvent.CategoryKey.host: host,
                MeegoNetworkEvent.CategoryKey.urlPath: urlPath,
                MeegoNetworkEvent.CategoryKey.httpStatusCode: httpStatusCode,
                MeegoNetworkEvent.CategoryKey.apiEnv: apiEnv,
                MeegoNetworkEvent.CategoryKey.larkGW: larkGW ?? "",
                MeegoNetworkEvent.CategoryKey.netLibType: "native",
                MeegoNetworkEvent.CategoryKey.resultType: "failure",
                MeegoNetworkEvent.CategoryKey.tenantBrand: tenantBrand
            ],
            extra: [
                MeegoNetworkEvent.ExtraKey.requestId: apiError.logId,
                MeegoNetworkEvent.ExtraKey.errorMsg: apiError.errorMsg
            ]
        )
        Tracker.post(slardarEvent)
    }
}

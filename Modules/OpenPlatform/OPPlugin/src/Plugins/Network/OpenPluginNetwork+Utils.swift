//
//  OpenPluginNetwork+Utils.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/27.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import TTMicroApp
import OPPluginManagerAdapter
import LarkContainer
import LarkRustClient
import RustPB
import LKCommonsLogging
import LarkSetting
import RxSwift

// MARK: Common Params
extension OpenPluginNetwork {
    
    static func getOriginUserAgent() -> String? {
        if let originUA = BDPUserAgent.getOriginUserAgentString(),
           let appName = BDPUserAgent.getAppNameAndVersionString() {
            return "\(originUA) \(appName)"
        }
        return nil
    }
    
    static func getAPITimeoutConfig(api: APIName, uniqueID: OPAppUniqueID) -> UInt? {
        guard let task = BDPTaskManager.shared().getTaskWith(uniqueID) else {
            return nil
        }
        
        switch api {
        case .request:
            return task.config?.networkTimeout.requestTime as? UInt
        case .uploadFile:
            return task.config?.networkTimeout.uploadFileTime as? UInt
        case .downloadFile:
            return task.config?.networkTimeout.downloadFileTime as? UInt
        default:
            return nil
        }
    }
    
    
    static func getOriginReferer() -> String? {
        if let referer = BDPSDKConfig.shared().serviceRefererURL {
            return "\(referer)/"
        } else {
            return nil;
        }
    }
    
    static func getStorageCookies(cookieService: ECOCookieService?, from uniqueID: OPAppUniqueID, url: URL) -> [String] {
        guard let cookieService = cookieService else {
            return []
        }
        var firstPartyCookies = FirstPartyMicroAppLoginOpt.shared.cookiesForURL(url, uniqueID: uniqueID)
        let storage = cookieService.gadgetCookieStorage(with: uniqueID)
        let cookies = storage?.cookies(for: url) ?? []
        if cookies.count > 0 {
            let uniqueCookieNameSet = Set(firstPartyCookies.map { $0.name })
            firstPartyCookies.append(contentsOf: cookies.filter { !uniqueCookieNameSet.contains($0.name) })
        }
        
        return firstPartyCookies.map{ "\($0.name)=\($0.value)"}
    }
    
    static func saveCookies(cookieService: ECOCookieService?, uniqueID: GadgetCookieIdentifier, cookies: [String], url: URL) {
        guard let cookieService = cookieService else {
            return
        }
        let storage = cookieService.gadgetCookieStorage(with: uniqueID)
        var httpCookies: [HTTPCookie] = []
        cookies.forEach { cookie  in
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": cookie], for: url)
            httpCookies.append(contentsOf: cookies)
        }
        storage?.saveCookies(httpCookies, url: url)
    }
}

extension OpenPluginNetwork {
    /// 创建向 Rust 发请求的 pb command  对象
    /// https://bytedance.feishu.cn/docs/doccnoSVDeTjoplvPIU3nyjuY05
    /// - Parameters:
    ///   - apiName: APIName
    ///   - url: 请求地址
    ///   - payload: JSSDK 下发的 payload
    /// - Returns: Command 及 extra 对象
    private static func createRequestCommand(
        apiName: APIName,
        uniqueID: BDPUniqueID,
        cookieService: ECOCookieService,
        trace: OPTrace,
        url: URL,
        payload: String
    ) throws -> (Openplatform_Api_OpenAPIRequest, OpenPluginNetworkRequestParamsExtra) {

        var apiContext = try Self.apiContext(from: uniqueID)

        // 生成 Extra, 提供给 Rust 处理请求
        let extra = OpenPluginNetworkRequestParamsExtra(
            cookies: OpenPluginNetwork.getStorageCookies(cookieService:cookieService, from: uniqueID, url: url),
            originUA: OpenPluginNetwork.getOriginUserAgent(),
            referer: OpenPluginNetwork.getOriginReferer(),
            timeout: OpenPluginNetwork.getAPITimeoutConfig(api: apiName, uniqueID: uniqueID)
        )

        // 准备请求数据
        var request = Openplatform_Api_OpenAPIRequest()
        apiContext.traceID = trace.traceId
        request.apiContext = apiContext
        request.apiName = apiName.rawValue
        request.payload = payload;
        request.extra = try Self.encode(type: .internal, model: extra)

        return (request, extra)
    }

    static func sendAsyncRequest(
        apiName: APIName,
        uniqueID: BDPUniqueID,
        trace: OPTrace,
        url: URL,
        payload: String,
        cookieService: ECOCookieService,
        rustService: RustService,
        disposeBag: DisposeBag,
        resultMonitor: OPMonitor?,
        success: @escaping (String, OpenPluginNetworkRequestResultExtra) -> Void,
        fail: @escaping (Error) -> Void
    ) throws {
        let reqCmd: (request: Openplatform_Api_OpenAPIRequest, extra: OpenPluginNetworkRequestParamsExtra) = try OpenPluginNetwork.createRequestCommand(
            apiName: apiName,
            uniqueID: uniqueID,
            cookieService: cookieService,
            trace: trace,
            url: url,
            payload: payload
        )
        rustService.sendAsyncRequest(reqCmd.request)
            .flatMap({ (response: Openplatform_Api_OpenAPIResponse) -> Observable<(String, OpenPluginNetworkRequestResultExtra)> in
                // 解码 extra , 处理需要端上处理数据(request 接口只有 cookie)
                let extra = try Self.decode(
                    type: .internal,
                    model: OpenPluginNetworkRequestResultExtra.self,
                    fromJson: response.extra
                )
                // 处理 set-cookie
                if let cookies = extra.cookie {
                    OpenPluginNetwork.saveCookies(cookieService:cookieService, uniqueID: uniqueID, cookies: cookies, url: url)
                }

                resultMonitor?.setRequestResponseInfo(from: extra)
                return Observable.just((response.payload, extra))
            })
            .subscribe (
                onNext: {(payload: String, extra: OpenPluginNetworkRequestResultExtra) in
                    success(payload, extra)
                },
                onError: { error in
                    fail(error)
                }
            )
            .disposed(by: disposeBag)
    }
}


// MARK: Data convert
extension OpenPluginNetwork {
    
    enum ModelType {
        case input
        case `internal`
    }
    
    func encode(urlString: String) throws -> URL {
        if (urlQueryAllowedEnable()) {
            guard let urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                  let url = URL(string: urlString) else {
                throw OpenPluginNetworkError.encodeUrlFail(urlString)
            }
            return url
        } else {
            guard let urlString = urlString.addingPercentEncoding(withAllowedCharacters: self.encodeSet),
                  let url = URL(string: urlString) ?? (customHelpEncodeEnable() ? TMACustomHelper.url(with: urlString, relativeTo: nil) : nil) else {
                throw OpenPluginNetworkError.encodeUrlFail(urlString)
            }
            return url
        }
    }
    
    static func getUniqueID(context: OpenAPIContext) throws -> OPAppUniqueID {
        guard let uniqueID = context.uniqueID else {
            throw OpenPluginNetworkError.missingRequiredParams("uniqueID is nil")
        }
        return uniqueID
    }
    
    static func apiContext(from uniqueID: OPAppUniqueID) throws -> Openplatform_Api_APIAppContext {
        guard let apiContext = Openplatform_Api_APIAppContext.context(from: uniqueID) else {
            throw OpenPluginNetworkError.createContextFail
        }
        return apiContext
    }

    static func getDictionary(fromJson str: String) throws -> [String: AnyObject] {
        if let data = str.data(using: String.Encoding.utf8) {
            do {
                let dic = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.init(rawValue: 0)]) as? [String:AnyObject]
                return dic ?? [:]
            } catch let error {
                throw OpenPluginNetworkError.codeInputModelFail("Decode \(str) fail, error: \(error)")
            }
        }
        return [:]
    }
    
    static func decode<T: Decodable>(type: ModelType, model: T.Type, fromJson str: String) throws -> T {
        do {
            return try JSONDecoder().decode(model, from: Data(str.utf8))
        } catch let error {
            switch type {
            case .input: throw OpenPluginNetworkError.codeInputModelFail("Decode \(model) fail, error: \(error)")
            case .internal: throw OpenPluginNetworkError.codeInternalModelFail("Decode \(model) fail, error: \(error)")
            }
        }
    }
    
    static func encode<T: Encodable>(type: ModelType, model: T) throws -> String {
        do {
            let data = try JSONEncoder().encode(model)
            return String(decoding: data, as: UTF8.self)
        } catch let error {
            switch type {
            case .input: throw OpenPluginNetworkError.codeInputModelFail("Decode \(model) fail, error: \(error)")
            case .internal: throw OpenPluginNetworkError.codeInternalModelFail("Decode \(model) fail, error: \(error)")
            }
        }
    }
}

extension String {
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

// MARK: - AppSetting
private let networkV2EncodeURLStr = UserSettingKey.make(userKeyLiteral: "networkV2EncodeURL")
private let urlQueryAllowedEnableStr = "urlQueryAllowedEnable"
private let customHelpEncodeEnableStr = "customHelpEncodeEnable"
private extension OpenPluginNetwork {
    private func networkV2EncodeURL() -> [String: Any] {
        do {
            let config: [String: Any] = try userResolver.settings.setting(with: networkV2EncodeURLStr)
            return config
        } catch {
            return [
                urlQueryAllowedEnableStr: false,
                customHelpEncodeEnableStr: false,
            ]
        }
    }
    
    private func urlQueryAllowedEnable() -> Bool {
        let config = self.networkV2EncodeURL()
        return config[urlQueryAllowedEnableStr] as? Bool ?? false
    }
    
    private func customHelpEncodeEnable() -> Bool {
        let config = self.networkV2EncodeURL()
        return config[customHelpEncodeEnableStr] as? Bool ?? false
    }
}

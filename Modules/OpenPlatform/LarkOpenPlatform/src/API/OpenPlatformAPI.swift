//
//  OpenPlatformAPI.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2019/9/16.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON
import Swinject
import EEMicroAppSDK
import LarkLocalizations
import LKCommonsLogging
import LarkRustHTTP
import LarkContainer
import LarkAccountInterface

let OPLogger = Logger.oplog(OpenPlatformAPI.self, category: "openPlatformBase")
private let OpenPlatformAPIDefaultTimeout: TimeInterval = 30.0
class OpenPlatformAPI {

    public enum Scope {
        case microapp
        case uploadInfo
        case messageCard
        case appcenter
        case appplus
        case parseApplink
        ///AppLink 获取应用信息
        case appInterface
        /// 生成applink短链
        case generateShortAppLink
        /// 加号菜单展示快捷操作
        case plusExplorer
        /// 加号菜单更新用户外化展示配置
        case configPlusMenuUserDisplay
        /// MessageAction展示快捷操作
        case msgActionExplorer
        /// Message Action 获取消息内容
        case messageActionContent
        /// 分享应用
        case shareApp
        ///  个性化头像
        case personalizedAvatar
        /// 群机器人，域名alias为openAppInterface
        case groupBot
        /// 群机器人添加/移除，域名alias为open
        case groupBotManage
        /// 消息卡片样式配置
        case messageCardStyle
        /// 换取卡片
        case messageCardTransform
        /// 打卡
        case clockIn
        /// 消息卡片灰度CDN样式, 自定义URL
        case customURL(String, String)
        ///NativeApp可见性
        case nativeApp
        case menuPanel
        case applyForUse
        case appSetting
    }

    var parameters: [String: Any] = [:]
    var parameterEncode: ParameterEncoding = JSONEncoding.default
    var cookies: [String: String] = [:]
    var method: HTTPMethod = .post
    var path: APIUrlPath
    var headers: [String: String] = [:]
    var scope: Scope = .microapp
    var resolver: UserResolver
 
    var session = false                 // 是否携带lark session
    var sessionHeaderKey: APIHeaderKey = .X_Session_ID
    var cipher: EMANetworkCipher?       // 对参数加密
    /// 由于生命周期问题,目前无法实际使用
    var configuration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = OpenPlatformAPIDefaultTimeout    // 超时时间不要太小，否则低端机型在Lark启动后一端时间容易超时
        configuration.protocolClasses = [RustHttpURLProtocol.self]
        return configuration
    }()

    public init(path: APIUrlPath, resolver: UserResolver) {
        self.path = path
        self.resolver = resolver
        _ = appendHeader(key: .Content_Type, value: "application/json")
    }

    public func appendParam(key: APIParamKey, value: Any?) -> OpenPlatformAPI {
        parameters[key.rawValue] = value
        return self
    }
    
    public func appendParams(params: [String: Any]) -> OpenPlatformAPI {
        params.forEach { (k, v) in
            parameters[k] = v
        }
        return self
    }

    public func setMethod(_ method: HTTPMethod) -> OpenPlatformAPI {
        if method == .get {
            self.parameterEncode = URLEncoding.default
        }
        self.method = method
        return self
    }

    @discardableResult
    public func appendHeader(key: APIHeaderKey, value: String?) -> OpenPlatformAPI {
        headers[key.rawValue] = value
        return self
    }
    
    @discardableResult
    public func appendCookie() -> OpenPlatformAPI {
        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            OPLogger.error("PassportUserService impl is empty")
            return self
        }
        cookies[APICookieKey.session.rawValue] = userService.user.sessionKey
        return self
    }

    public func useSession() -> OpenPlatformAPI {
        session = true
        return self
    }

    public func useSessionKey(sessionKey: APIHeaderKey = .X_Session_ID) -> OpenPlatformAPI {
        self.sessionHeaderKey = sessionKey
        return self
    }

    public func useLocale() -> OpenPlatformAPI {
        return appendParam(key: .locale, value: OpenPlatformAPI.curLanguage())
    }

    public func useEncrypt() -> OpenPlatformAPI {
        cipher = EMANetworkCipher()
        return appendParam(key: .ttcode, value: cipher?.encryptKey)
    }

    public func setScope(_ scope: Scope) -> OpenPlatformAPI {
        self.scope = scope
        return self
    }
    
    /// 由于生命周期问题,目前无法实际使用
    public func setTimeout(_ timeout: TimeInterval) -> OpenPlatformAPI {
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        return self
    }

    /// 获取当前语言（适配后台，国际化Key统一使用小写）
    static public func curLanguage() -> String {
        return LanguageManager.currentLanguage.rawValue.lowercased()
    }
    @discardableResult
    public func getParameters() -> [String: Any]? {
        return self.parameters
    }
}

class APIResponse {
    public let json: JSON
    public let api: OpenPlatformAPI
    public let code: Int?
    public let msg: String?
    public let data: JSON?
    public let rawData: Data?
    /// 请求的 lob-logid ，用来上报排查后端的请求
    public var lobLogID: String?

    required init(json: JSON, api: OpenPlatformAPI) {
        self.json = json
        self.api = api
        self.code = self.json["code"].int
        self.msg = self.json["msg"].string
        if self.code == 0 {
            if let cipher = api.cipher {
                let encrypted_data = self.json["data"]["encrypted_data"].stringValue
                let data: Any? = EMANetworkCipher.decryptDict(forEncryptedContent: encrypted_data, cipher: cipher)
                if let data = data {
                    self.data = JSON(data)
                } else {
                    self.data = nil
                }
            } else {
                self.data = JSON(self.json["data"]["data"].rawValue)
            }
            if let rawData = try? self.json["data"].rawData() {
                self.rawData = rawData
            } else {
                self.rawData = nil
            }
        } else {
            self.data = nil
            self.rawData = nil
        }
    }

    /// 将json数据转化为指定类型的model
    /// - Parameters:
    ///   - type: model类型
    func buildDataModel<T: Codable>(type: T.Type) -> T? {
        return buildCustomDataModel(type: type, data: self.rawData)
    }

    /// 将自定义传入的json数据转化为指定类型的model
    /// - Parameters:
    ///   - type: model类型
    func buildCustomDataModel<T: Codable>(type: T.Type, data: Data?) -> T? {
        guard let data = data else {
            OPLogger.error("data is empty, parse failed!")
            return nil
        }
        do {
            let model = try JSONDecoder().decode(type, from: data)
            OPLogger.info("parse data to model(\(type)) success")
            return model
        } catch {
            OPLogger.error("parse data to model(\(type)) failed with error: \(error), desc: \(error.localizedDescription)")
            return nil
        }
    }
}

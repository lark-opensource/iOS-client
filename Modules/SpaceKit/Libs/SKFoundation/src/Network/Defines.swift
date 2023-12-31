//
//  Defines.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/10.
// swiftlint:disable line_length
// 和网络相关的定义们

import Foundation
import Alamofire
import LarkExtensions
import LarkContainer

/// 发起网络请求时，参数的编码类型及位置
///
/// - urlEncodeInBody: url编码，结果放在body里
/// - urlEncodeDefault: url编码，编码后位置和请求方法有关
/// - urlEncodeAsQuery: url编码，编码后作为query放在url里
/// - jsonEncodeDefault: jsonencode，放在body里
public enum ParamEncodingType {
    case urlEncodeInBody
    case urlEncodeDefault
    case urlEncodeAsQuery
    case jsonEncodeDefault
    var toAlamofire: ParameterEncoding {
        switch self {
        case .urlEncodeDefault: return URLEncoding.default
        case .urlEncodeAsQuery: return URLEncoding.queryString
        case .jsonEncodeDefault: return JSONEncoding.default
        case .urlEncodeInBody: return URLEncoding.httpBody
        }
    }
}

public enum DocsHTTPMethod: String {
    case POST
    case GET

    var toAlamofire: HTTPMethod {
        switch self {
        case .POST: return .post
        case .GET: return .get
        }
    }

}

//UserAgent以及HttpHeader规范: https://wiki.bytedance.net/pages/viewpage.action?pageId=179416229
public struct UserAgent {
    // WebView 请求的 User Agent,目前只有当加载template的时候需要
    //   DocsAPP: "Mozilla/5.0 (iPhone 8 (Simulator); CPU iOS 12_1 like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153 [en] Bytedance DocsSDK/2.2.0 Docs/1.1.0"
    //   LARK: "Mozilla/5.0 (iPhone 8 (Simulator); CPU iOS 12_1 like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153 [en] Bytedance DocsSDK/2.2.0 Lark/2.2.0-alpha "
    public static var defaultWebViewUA: String = {
        var ua = "Mozilla/5.0 (\(UIDevice.current.lu.modelName()); CPU \(UIDevice.current.systemName) \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153"
        return ua
    }()

    // Native API 请求的 User Agent, 包含被dosSource接管的H5请求
    // https://github.com/WURFL/User-Agent-Native-apps/blob/master/swift/UABuilder.swift
    // example
    //    DocsSDK:   DocsSDK/2.2.0 Docs/1.0.0 CFNetwork/975.0.3 Darwin/18.2.0 Mobile x86_64 iOS/12.1
    //    Lark: DocsSDK/2.2.0 Lark/2.2.0-alpha CFNetwork/975.0.3 Darwin/18.2.0 Mobile x86_64 iOS/12.1
    public static var defaultNativeApiUA: String = {
        let sdkInfo = "\("DocsSDK")/\(SKFoundationConfig.shared.spaceKitVersion)"
        let appNameInfo = appNameAndVersion()
        let networkInfo = CFNetworkVersion()
        let darwinInfo = darwinVersion()
        let type = "Mobile"
        return "\(sdkInfo) \(appNameInfo) \(networkInfo) \(darwinInfo) \(type) \(deviceName()) \(deviceVersion())"
    }()
}

//https://wiki.bytedance.net/pages/viewpage.action?pageId=179416229
//demo: "{\"doc-package-name\":\"com.openlanguage.ee.docs.dev\",\"doc-channel-id\":\"0\",\"doc-os-version\":\"12.1\",\"doc-version-code\":\"1\",\"doc-version-name\":\"0.3.0\",\"doc-device-model\":\"iPhone 8 (Simulator)\",\"doc-platform\":\"Docs\",\"doc-os\":\"iOS\"}"
public final class SpaceHttpHeaders {
    public var dictValue: [String: String] = [:]
    public static var common: [String: String] = {
        var dict = [String: String]()
        dict["doc-version-code"] = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String // 构建版本号。1.16.1-654 后面的654
        dict["doc-version-name"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String// app版本号，如 1.16.1
        dict["doc-package-name"] = Bundle.main.bundleIdentifier //应用程序的包名，唯一id

        dict["doc-platform"]     = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String // app的名字 Docs/Lark
        dict["doc-biz"]     = SpaceHttpHeaders.docBiz // 因为platform前端传的是web,所以后端没法通过platform判断是飞书还是飞书单品，所以统一通过doc-biz来标识
        dict["doc-os"]           = UIDevice.current.systemName //系统名字 iOS/
        dict["doc-os-version"]   = UIDevice.current.systemVersion // 系统版本
        dict[DocsCustomHeader.deviceId.rawValue]    =  CCMKeyValue.globalUserDefault.string(forKey: SKFoundationConfig.shared.kDeviceID) // 设备id，根据
        dict["doc-channel-id"]   = "0" //渠道号  写死为0先
        dict["doc-device-model"] = UIDevice.current.lu.modelName() //iphone11,6
        return dict
    }()

    public init() {}

    public static var docBiz: String? {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    public static func updateDevice(_ newDiviceId: String) {
        common[DocsCustomHeader.deviceId.rawValue] = newDiviceId
    }

    public func addLanguage() -> SpaceHttpHeaders {
        dictValue["Accept-Language"] = SKFoundationConfig.shared.currentLanguageIdentifer
        return self
    }

    public func addCookieString() -> SpaceHttpHeaders {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        dictValue["Cookie"] = userResolver.docs.netConfig?.cookies()?.cookieString
        return self
    }

    public func merge(_ dict: [String: String]?) -> SpaceHttpHeaders {
        guard let dict = dict else { return self }
        for (k, v) in dict {
            dictValue.updateValue(v, forKey: k)
        }
        return self
    }
}

//
//  Defines.swift
//  MailSDK
//
//  Created by huahuahu on 2019/1/10.
//
// 和网络相关的定义们

import Foundation
import Alamofire
import LarkExtensions

/// 发起网络请求时，参数的编码类型及位置
///
/// - urlEncodeInBody: url编码，结果放在body里
/// - urlEncodeDefault: url编码，编码后位置和请求方法有关
/// - urlEncodeAsQuery: url编码，编码后作为query放在url里
/// - jsonEncodeDefault: jsonencode，放在body里
enum ParamEncodingType {
//    case urlEncodeInBody
    case urlEncodeDefault
    case urlEncodeAsQuery
    case jsonEncodeDefault
    var toAlamofire: ParameterEncoding {
        switch self {
        case .urlEncodeDefault: return URLEncoding.default
        case .urlEncodeAsQuery: return URLEncoding.queryString
        case .jsonEncodeDefault: return JSONEncoding.default
        }
    }
}

enum MailHTTPMethod: String {
    case POST
    case GET

    var toAlamofire: HTTPMethod {
        switch self {
        case .POST: return .post
        case .GET: return .get
        }
    }

}
// swiftlint:disable line_length

// UserAgent以及HttpHeader规范: https://wiki.bytedance.net/pages/viewpage.action?pageId=179416229
struct UserAgent {
    // WebView 请求的 User Agent,目前只有当加载template的时候需要
    //   DocsAPP: "Mozilla/5.0 (iPhone 8 (Simulator); CPU iOS 12_1 like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153 [en] Bytedance DocsSDK/2.2.0 Docs/1.1.0"
    //   LARK: "Mozilla/5.0 (iPhone 8 (Simulator); CPU iOS 12_1 like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153 [en] Bytedance DocsSDK/2.2.0 Lark/2.2.0-alpha"
    static var defaultWebViewUA: String = {
        #if DEBUG
        return "Mozilla/5.0 (\(UIDevice.current.lu.modelName()); CPU \(UIDevice.current.systemName) \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153 Lark/2.4.0"
        #else
        return "Mozilla/5.0 (\(UIDevice.current.lu.modelName()); CPU \(UIDevice.current.systemName) \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153"
        #endif
    }()

    // Native API 请求的 User Agent, 包含被dosSource接管的H5请求
    // https://github.com/WURFL/User-Agent-Native-apps/blob/master/swift/UABuilder.swift
    // example
    //    DocsSDK:   DocsSDK/2.2.0 Docs/1.0.0 CFNetwork/975.0.3 Darwin/18.2.0 Mobile x86_64 iOS/12.1
    //    Lark: DocsSDK/2.2.0 Lark/2.2.0-alpha CFNetwork/975.0.3 Darwin/18.2.0 Mobile x86_64 iOS/12.1
    static var defaultNativeApiUA: String = {
        let appNameInfo = appNameAndVersion()
        let networkInfo = CFNetworkVersion()
        let darwinInfo = darwinVersion()
        let type = "Mobile"
        return "\(appNameInfo) \(networkInfo) \(darwinInfo) \(type) \(deviceName()) \(deviceVersion())"
    }()
}

//https://wiki.bytedance.net/pages/viewpage.action?pageId=179416229
// demo: "{\"mail-package-name\":\"com.openlanguage.ee.docs.dev\",\"mail-channel-id\":\"0\",\"mail-os-version\":\"12.1\",\"mail-version-code\":\"1\",\"mail-version-name\":\"0.3.0\",\"mail-device-model\":\"iPhone 8 (Simulator)\",\"mail-platform\":\"Docs\",\"mail-os\":\"iOS\"}"
class MailHttpHeaders {
    var dictValue: [String: String] = [:]
    static var common: [String: String] = {
        var dict = [String: String]()
        dict["mail-version-code"] = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String // 构建版本号。1.16.1-654 后面的654
        dict["mail-version-name"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String// app版本号，如 1.16.1
        dict["mail-package-name"] = Bundle.main.bundleIdentifier // 应用程序的包名，唯一id
        dict["mail-platform"]     = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String // app的名字 Docs/Lark
        dict["mail-os"]           = UIDevice.current.systemName // 系统名字 iOS/
        dict["mail-os-version"]   = UIDevice.current.systemVersion // 系统版本
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        dict[MailCustomRequestHeader.deviceId.rawValue] = kvStore.value(forKey: UserDefaultKeys.deviceID) // 设备id，根据
        dict["mail-channel-id"]   = "0" // 渠道号  写死为0先
        dict["mail-device-model"] = UIDevice.current.lu.modelName() // iphone11,6
        return dict
    }()
}
// swiftlint:enable line_length

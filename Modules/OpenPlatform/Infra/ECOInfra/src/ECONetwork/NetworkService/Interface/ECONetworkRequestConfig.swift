//
//  RequestConfig.swift
//  ECOInfra
//
//  Created by MJXin on 2021/5/23.
//

import Foundation

public enum ECONetworkHTTPMethod: String {
    case OPTIONS = "OPTIONS"
    case GET     = "GET"
    case HEAD    = "HEAD"
    case POST    = "POST"
    case PUT     = "PUT"
    case PATCH   = "PATCH"
    case DELETE  = "DELETE"
    case TRACE   = "TRACE"
    case CONNECT = "CONNECT"
}


/// ECONetworkService 层级的 Task 类型, 对应 URLSession 的不同 Task
public enum ECONetworkTaskType {
    case dataTask
    case download
    case uploadData
    case uploadFile

    var stringValue: String {
        switch self {
        case .dataTask:
            return "request"
        case .download:
            return "download"
        case .uploadData, .uploadFile:
            return "upload"
        }
    }
}


/// 请求设置信息
/// 备注: 相同的请求配置和 channel , 会复用同一个底层 client, 以此利用 URLSession 复用通道的特性.
public struct ECONetworkRequestSetting: Hashable {
    public var timeout: TimeInterval
    public var cachePolicy: URLRequest.CachePolicy
    /// rust 字段, 是否使用复合连接。复合连接会尝试建立多份连接，来获取更好的连接速度。但Header和Body的回调会延迟到结束请求时
    public var enableComplexConnect: Bool
    public var httpShouldUsePipelining: Bool
    
    /// 用所有 字段 Hash 值生成的 Hash
    /// 目前用于决定是否复用 Clinet
    public func hash(into hasher: inout Hasher) {
        hasher.combine(timeout)
        hasher.combine(cachePolicy)
        hasher.combine(enableComplexConnect)
        hasher.combine(httpShouldUsePipelining)
    }
}

/// 请求通道, 指网络请求走 Rust, 原生, 或 Mock
/// 实际用于 DI 根据字符串生成不同的 NetworkClient
public enum ECONetworkChannel: String {
    case rust = "ECONetworkChannelRust"
    case native = "ECONetworkClientTypeNative"
//    case mock = "ECONetworkClientTypeMock" // 暂未支持
    
    public static var `default`: ECONetworkChannel {
         return .rust
     }
}

/// 一个描述 "特定业务" 接口的配置文件
/// 业务使用 NetworkService 需要先依据接口定义好 RequestConfig
///  - ParamsType:  用来描述业务变量的数据类型, 作为请求接口的动态值传入
///  - RequestSerializer: 请求数据的序列化器, 用于将 ParamsType 序列化成 URL 或 Body 需要的数据
///     - 现有 Serializer:
///     ECORequestQueryItemSerializer: 将入参序列化成 URL Query Item, 用于 Get
///     ECORequestBodyJSONSerializer: 将入参序列化成 JSON 再转为 BodyData, 用于常见 Post
///  - ResultType: 返回值类型
///  - ResponseSerializer: 响应数据的序列化器, 用于将 BodyData 反序列化为指定数据
///     - 现有 Serializer:
///     ECOResponseJSONDecodableSerializer: 将 BodyData 反序列化为指定 ResultType (需要为 Codable)
///     ECOResponseJSONSerializer: 将 BodyData 反序列化为 SwiftyJSON.JSON
///  - path: 请求的路径
public protocol ECONetworkRequestConfig {
    associatedtype ParamsType
    associatedtype ResultType
    associatedtype RequestSerializer: ECONetworkRequestSerializer where RequestSerializer.Parameters == ParamsType
    associatedtype ResponseSerializer: ECONetworkResponseSerializer where ResponseSerializer.SerializedObject == ResultType
    
    /// scheme, 默认为 https
    static var scheme: Scheme { get }
    
    /// domain , 默认为 nil, 需要配置能注入 domain 的中间件, 否者请求时会报错.
    static var domain: String? { get }
    
    /// api path, 无默认值, 根据接口协议自定
    static var path: String { get }
    
    /// method, 无默认值, 根据接口协议自定
    static var method: ECONetworkHTTPMethod { get }

    static var port: Int? { get }
    
    /// initialHeaders,  默认为空, 对于 POST 建议写好 ContextType.  依赖上下文的内容可以由中间件注入
    static var initialHeaders: [String : String] { get }
    
    /// request 序列化器, 无默认值.
    ///  ⚠️ 注意避免因使用同一个对象导致成员变量影响到不同的请求
    /// 代码建议: 根据语法特性,建议每次请求都需要新对象用 return, 每次接口都使用同一个对象可用 lazy ,
    static var requestSerializer: RequestSerializer { get }
    
    /// response 反序列化器, 无默认值
    ///  定义时可利用语法特性, 每次新对象用 return, 每次同一个对象用 lazy ,
    ///  ⚠️ 注意避免因使用同一个对象导致成员变量影响到不同的请求
    static var responseSerializer: ResponseSerializer { get }
    
    /// 返回值校验器, 用于🔅请求成功到服务端并返回数据, 校验数据是否正确用(比如校验 statuscode)
    /// 协议不限定校验内容, 可以根据 content-type, status-code, header 等自定义.
    /// 默认为 statusCode: 200..<300 不抛错
    static var responseValidator: ECONetworkResponseValidator { get }
    
    /// 请求配置, 默认 {timeout: 60, cachePolicy: useProtocolCachePolicy}
    static var setting: ECONetworkRequestSetting { get }
    
    /// task 类型, 对应 URLsession 的几种 task,  默认 dataTask
    static var taskType: ECONetworkTaskType { get }
    
    /// 中间件, 默认 [] 用于在请求过程中做注入
    ///  定义时可利用语法特性, 每次新对象用 return, 每次同一个对象用 lazy ,
    ///  ⚠️ 注意避免因使用同一个对象导致成员变量影响到不同的请求
    static var middlewares: [ECONetworkMiddleware] { get }
    
    /// 请求通道, 默认 Rust 通道
    /// 实际效用为决定 NetworkService 内部注入的 NetworkClient 类型
    static var channel: ECONetworkChannel { get }
}

/// ECONetworkRequestConfig 默认设置
public extension ECONetworkRequestConfig {
    static var scheme: Scheme { .https }
    static var domain: String? { nil }
    static var initialHeaders: [String : String] { [:] }
    static var setting: ECONetworkRequestSetting { DefaultRequestSetting }
    static var taskType: ECONetworkTaskType { .dataTask }
    static var channel: ECONetworkChannel { ECONetworkChannel.default }
    static var responseValidator: ECONetworkResponseValidator { ECONetworkStatusCodeValidator(statusCode: 200..<300 ) }
    static var port: Int? { nil }

    static func description() -> String {
        """
{
    self: \(Self.self),
    scheme: \(Self.scheme),
    domain: \(Self.domain ?? "nil"),
    method: \(Self.method),
    path: \(Self.path),
    paramsType:\(Self.ParamsType.self),
    resultType: \(Self.ResultType.self),
    setting: \(Self.setting),
    type:\(Self.taskType),
    channel\(Self.channel),
    port: \(Self.port ?? -1)
}
"""
    }
}

public protocol ECONetworkRequestJSONGetConfig: ECONetworkRequestConfig where
ParamsType == [String : String]?,
ResultType == [String : Any],
RequestSerializer == ECORequestQueryItemSerializer,
ResponseSerializer == ECOResponseJSONObjSerializer<[String : Any]> {}

public extension ECONetworkRequestJSONGetConfig {
    static var requestSerializer: ECORequestQueryItemSerializer { ECORequestQueryItemSerializer() }

    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
}

public protocol ECONetworkRequestJSONPostConfig: ECONetworkRequestConfig where
ParamsType == [String : Any],
ResultType == [String : Any],
RequestSerializer == ECORequestBodyJSONSerializer,
ResponseSerializer == ECOResponseJSONObjSerializer<[String : Any]> {}

public extension ECONetworkRequestJSONPostConfig {
    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }

    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
}

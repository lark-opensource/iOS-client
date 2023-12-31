//
//  ECONetworkRequest.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation
import LKCommonsLogging

public enum Scheme: String {
    case http
    case https
}

/// 供序列化使用的原始字段信息
public protocol ECONetworkRequestOrigin {
    var method: ECONetworkHTTPMethod { get }
    
    var headerFields: [String : String] { get }
    
    var urlQueryItems: [URLQueryItem] { get }
    
    var bodyFields: [String: Any] { get }
}

/// NetworkService 操作过程中的 Request 对象
public struct ECONetworkRequest: ECONetworkRequestOrigin {
    static let logger = Logger.oplog(ECONetworkRequest.self, category: "ECONetwork")
    
    public var scheme: Scheme
    
    public var domain: String? {
        didSet {
            log(info: """
            change domain
            - \(oldValue ?? "")
            + \(domain ?? "")
            """
            )
        }
    }
    
    public var path: String {
        didSet {
            log(info: """
            change path
            - \(oldValue)
            + \(path)
            """
            )
        }
    }

    public var method: ECONetworkHTTPMethod {
        didSet {
            log(info: """
            change method
            - \(oldValue.rawValue)
            + \(method.rawValue)
            """
            )
        }
    }

    public var port: Int? {
        didSet {
            log(info: """
            change port
            - \(oldValue ?? -1)
            + \(port ?? -1)
            """
            )
        }
    }
    
    /// 请求的 Header, 供中间件修改
    /// 不开放直接 set 权限, 通过 setHeaderField, mergingHeaderFields 修改. 避免被整个换掉
    public private(set) var headerFields: [String : String]
    
    /// 请求的 bodyFields, 未经序列化, 供中间件修改
    /// 不开放直接 set 权限, 通过 setBodyField, mergingBodyFields 修改. 避免被整个换掉
    public private(set) var bodyFields: [String: Any] = [:]
    
    /// 请求的 urlQueryItem, 未经序列化, 供中间件修改
    /// 不开放直接 set 权限, 通过 setBodyField, mergingBodyFields 修改. 避免被整个换掉
    public private(set) var urlQueryItems: [URLQueryItem] = []
    
    /// 请求配置, 生成 URLRequest 时同步加入
    /// 由于 URLRequest 的设置在走 URLSession 存在的情况下无效.
    /// 所以实际生效是由 NetworkService 在保障请求的设置一致(不排除以后有不走 URLSession 的情况)
    public var setting: ECONetworkRequestSetting
    
    /// 代表序列化后的数据
    /// 只对内开放, 不允许外界修改,
    /// 外部需要传入 Data (如上传场景) 可以 createTask 时作为 Params 的方式
    internal var bodyData: Data?
    
    /// 代表处理后的 URL
    /// 只对内开放, 不允许外界修改,
    /// 外部需要传入 URL (如上传场景) 可以 createTask 时作为 Params 的方式
    internal var uploadFileURL: URL?

    let trace: OPTrace
    
    // ❗勿对模块外暴露初始化接口, 外部只允许更新操作
    internal init(
        scheme: Scheme,
        domain: String?,
        path: String,
        method: ECONetworkHTTPMethod,
        port: Int?,
        headerFields: [String: String],
        setting: ECONetworkRequestSetting,
        trace: OPTrace
    ) {
        self.scheme = scheme
        self.domain = domain
        self.path = path
        self.method = method
        self.port = port
        self.headerFields = headerFields
        self.setting = setting
        self.trace = trace
    }

    private func log(info: String) {
        let log = """
        ECONetwork/request-id/\(trace.getRequestID() ?? ""),
        domain=\(domain ?? ""),
        path=\(path),
        info=\(info)
        """
        trace.info(log, tag: ECONetworkLogKey.startRequestEdit)
    }
    
    /// 使用序列化的结果更新 Request
    /// - Parameter serializeResult:  序列化结果, 由 RequestSerilizer 生成
    public mutating func update(withSerializeResult serializeResult: ECONetworkSerializeResult) {
        switch serializeResult {
        case .urlQueryItems(let items):
            urlQueryItems.append(contentsOf: items)
        case .bodyData(let data, let contentType):
            bodyData = data
            if headerFields[ContentTypeKey] == nil { headerFields[ContentTypeKey] = contentType }
        case .uploadFileURL(let url, let contentType):
            uploadFileURL = url
            if headerFields[ContentTypeKey] == nil { headerFields[ContentTypeKey] = contentType }
        }
    }
    
    internal mutating func update(withURL url: String) throws {
        guard let url = URL(string: url),
              let scheme = Scheme(rawValue: url.scheme ?? ""),
              let domain = url.host else {
            throw OPError.unknownError(detail: "Unsupported url \(url.safeURLString)")
        }
        
        self.scheme = scheme
        self.domain = domain
        path = url.path
        port = url.port
        
        let component = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlQueryItems.insert(contentsOf: component?.queryItems ?? [], at: 0)
    }
    
    public mutating func setHeaderField(key: String, value: String) {
        if headerFields[key] != nil {
            Self.logger.warn("object for key\(key) is existed")
            assertionFailure("object for key\(key) is existed")
        }
        headerFields[key] = value

        log(info: """
        add header \(key)
        header
        + \(ECONetworkLogTools.monitorValue(data: [key: value])?.total ?? "")
        """
        )
    }
    
    public mutating func mergingHeaderFields(with input: [String: String]) {
        headerFields = headerFields.merging(input) { (first, second) -> String in
            assertionFailure("merge new object to existed key, first:\(first), second:\(second)")
            return second
        }

        log(info: """
        add header \(input.keys)
        header
        + \(ECONetworkLogTools.monitorValue(data: input)?.total ?? "")
        """
        )
    }
    
    public mutating func addUrlQueryItems(item: URLQueryItem) {
        urlQueryItems.append(item)

        log(info: """
        add query \(item.name)
        query
        + \(ECONetworkLogTools.monitorValue(data: [item.name: item.value ?? ""])?.total ?? "")
        """
        )
    }
    
    public mutating func setBodyField(key: String, value: Encodable) {
        if headerFields[key] != nil {
            Self.logger.warn("object for key\(key) is existed")
            assertionFailure("object for key\(key) is existed")
        }
        
        bodyFields[key] = value

        log(info: """
        add body \(key)
        body
        + \(ECONetworkLogTools.monitorValue(data: [key: value])?.total ?? "")
        """
        )
    }
    
    public mutating func mergingBodyFields(with input: [String: Any]) {
        bodyFields = bodyFields.merging(input) { (first, second) -> Any in
            assertionFailure("merge new object to existed key, first:\(first), second:\(second)")
            return second
        }

        log(info: """
        add body \(input.keys)
        body
        + \(ECONetworkLogTools.monitorValue(data: input)?.total ?? "")
        """
        )
    }
    
    /// 将内部字段拼接为 URL
    /// - Throws: 无法生成 URL 时抛错
    public func getURL() throws -> URL {
        guard let host = domain else { throw OPError.invalidHost(detail: domain) }
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = host
        components.path = path
        components.port = port
        if !urlQueryItems.isEmpty {
            components.queryItems = urlQueryItems
        }
        guard let url = components.url else {
            Self.logger.error("get url fail scheme: \(scheme.rawValue), host:\(host), path: \(path)")
            throw OPError.invalidURL(detail: scheme.rawValue + "," + host + "," + path)
        }
        return url
    }
    
    /// 将内部数据转为 URLRequest
    /// - Throws: URL 异常时抛出错误
    public func toURLRequest() throws -> URLRequest {
        let url = try getURL()
        var request = URLRequest(
            url: url,
            cachePolicy: setting.cachePolicy,
            timeoutInterval: setting.timeout
        )
        // rust 独有字段, 定义在 LarkRustHttpHelper 中
        request.enableComplexConnect = setting.enableComplexConnect
        request.allHTTPHeaderFields = headerFields
        request.httpMethod = method.rawValue
        request.httpBody = bodyData
        request.httpShouldUsePipelining = setting.httpShouldUsePipelining
        return request
    }
}

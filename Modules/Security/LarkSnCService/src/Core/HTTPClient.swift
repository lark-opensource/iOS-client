//
//  HTTPClient.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/8.
//

import Foundation

/// 请求头
public typealias HTTPHeaders = [String: String]

/// HTTP method definitions.
///
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
}

/// HTTP Request
public struct HTTPRequest {
    /// 请求基本路径
    public let baseURL: String
    /// 请求路径
    public let path: String
    /// 请求 Method
    public let method: HTTPMethod
    /// 请求 Header
    public var headers: HTTPHeaders?
    /// URL 请求参数
    public var query: [String: Any]?
    /// Body 请求参数
    public var data: [String: Any]?
    /// 失败重试次数
    public var retryCount: Int
    /// 重试间隔
    public var retryDelay: DispatchTimeInterval

    public init(_ baseURL: String,
                path: String,
                method: HTTPMethod = .get,
                headers: HTTPHeaders? = nil,
                query: [String: Any]? = nil,
                data: [String: Any]? = nil,
                retryCount: Int = 0,
                retryDelay: DispatchTimeInterval = .seconds(1)
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.headers = headers
        self.query = query
        self.data = data
        self.retryCount = retryCount
        self.retryDelay = retryDelay
    }
}

// MARK: Private

private let httpScheme = "http://"
private let httpsScheme = "https://"

fileprivate extension HTTPRequest {
    /// 通过对 baseURL 和 path 的检查和修改，将其格式调整为特定的格式
    var _baseURL: String {
        baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
    }

    var _path: String {
        path.hasPrefix("/") ? path : "/" + path
    }

    /// 解析出domain
    var baseDomain: String {
        if baseURL.hasPrefix(httpScheme) {
            return String(baseURL.dropFirst(httpScheme.count))
        } else if baseURL.hasPrefix(httpsScheme) {
            return String(baseURL.dropFirst(httpsScheme.count))
        } else {
            return baseURL
        }
    }
}

// MARK: Public

extension HTTPRequest: URLRequestConvertible {
    public func asURLRequest() throws -> URLRequest {
        let pathHasBaseURL = path.hasPrefix(httpScheme) || path.hasPrefix(httpsScheme)
        let urlString = pathHasBaseURL ? path : _baseURL + _path
        guard var urlComponents = URLComponents(string: urlString) else {
            throw SnCError.invalidURL(urlString)
        }
        var queryItems = query?.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        queryItems?.append(contentsOf: urlComponents.queryItems ?? [])
        urlComponents.queryItems = queryItems
        // create url request
        let url = try urlComponents.asURL()
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        if let data = data, !data.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        }
        return request
    }

    public var desc: [String: Any] {
        return ["path": path,
                "method": method.rawValue,
                "domain": baseDomain]
    }
}

/// 网络请求协议
public protocol HTTPClient {
    /// 发送 Request 请求，返回 Any 数据
    /// - Parameters:
    ///   - request: Request 对象
    ///   - completion: 回调结果，Data 数据，Error 错误
    func request(_ request: HTTPRequest, completion: ((Result<Data, Error>) -> Void)?)
}

public extension HTTPClient {
    /// 发送 Request 请求，返回 Model 数据
    /// - Parameters:
    ///   - request: Request 对象
    ///   - dataType: 数据类型
    ///   - completion: 回调结果，T Model 结构，Error 错误
    func request<T: Decodable>(_ request: HTTPRequest,
                               dataType: T.Type,
                               completion: ((Result<T, Error>) -> Void)?) {
        self.request(request) { result in
            completion?(result.flatMap { data in
                do {
                    let model = try JSONDecoder().decode(dataType, from: data)
                    return .success(model)
                } catch {
                    return .failure(error)
                }
            })
        }
    }
}

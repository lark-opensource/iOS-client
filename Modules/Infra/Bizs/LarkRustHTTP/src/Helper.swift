//
//  Helper.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/11/25.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import RustPB
import HTTProtocol
import EEAtomic

/// 是否打印详细的http请求日志
let dataFormatter: DateFormatter = {
    let v = DateFormatter()
    v.dateFormat = "MM-dd HH:mm:ss.SSSS"
    return v
}()

@inline(__always)
func debug(
    _ message: @autoclosure () -> String? = "",
    file: StaticString = #fileID,
    line: Int = #line,
    function: StaticString = #function
) {
    #if DEBUG
    if !HTTProtocol.shouldShowDebugMessage { return }
    let threadno = Thread.current
    print( "\(dataFormatter.string(from: Date())) [\(threadno)]\(file):\(line) \(function) ==> \(message() ?? "")" )
    #endif
}

func reflect<T>(_ obj: T) -> String {
    var v = ""
    dump(obj, to: &v)
    return v
}

func dump(request: URLRequest?) -> String {
    if let request = request {
        return "\((request.url?.absoluteString, request.httpMethod, request.allHTTPHeaderFields))"
    }
    return "no request"
}

extension FetchRequest {
    init?(request: URLRequest, with cookieStorage: HTTPCookieStorage?) {
        guard let url = request.url, let method = Method(method: request.httpMethod) else { return nil }

        self = FetchRequest()
        self.requestID = RustHttpManager.nextTaskID()
        self.url = url.absoluteString
        self.method = method
        self.headers = headers(from: request, with: cookieStorage)
        // NOTE: request.timeout是无响应的超时，不是总体超时。rust有默认的无响应超时
        // 另一方面，URLSession会根据request.timeout控制超时，并调用endLoading.
        // 这里提供直接设置rust总超时的能力
        let timeout = request.rustMaxTimeout
        if timeout > 0 {
            self.timeout = timeout >= Double(Int32.max) ? Int32.max : Int32(timeout)
        }
        if case let retry = request.retryCount, retry > 0 { self.retryNum = Int32(clamping: retry) }
        if request.enableComplexConnect { self.enableComplexConnect = true }
    }

    private func headers(from request: URLRequest, with cookieStorage: HTTPCookieStorage?) -> [HttpHeader] {
        var headers = HttpHeader.convert(from: request.allHTTPHeaderFields)

        // append defealt cookies
        // https://tools.ietf.org/html/rfc6265#section-5.4
        if
            let cookieStorage = cookieStorage,
            !headers.contains(where: { $0.name == "cookie" }), //苹果实现: 如果用户设置了cookie header,则忽略默认的
            let url = request.url,
            let cookies = cookieStorage.cookies(for: url),
            !cookies.isEmpty,
            let cookiesValue = HTTPCookie.requestHeaderFields(with: cookies)
                .first(where: { (k, _) in k.lowercased() == "cookie" })?.value,
            !cookiesValue.isEmpty
            // swiftlint:disable:next all
        {
            headers.append(HttpHeader(name: "cookie", value: cookiesValue))
        }
        return headers
    }
}

extension FetchRequest.Method {
    init?(method: String?) {
        guard let method = method else { return nil }
        switch method.uppercased() {
        case "GET":    self = .get
        case "POST":   self = .post
        case "DELETE": self = .delete
        case "PUT":    self = .put
        case "PATCH":  self = .patch
        case "HEAD":   self = .head
        case "CONNECT": self = .connect
        case "OPTIONS": self = .options
        case "TRACE":   self = .trace
       default:
           logger.warn("unsupport rust http method: \(method)")
           return nil
        }
    }
}

extension HttpHeader {
    init(name: String, value: String) {
        self = HttpHeader()
        self.name = name
        self.value = value
    }
    /// 为了处理方便，转换后的fieldname全是小写
    static func convert(from: [String: String]?) -> [HttpHeader] {
        guard let headers = from else { return [] }
        return headers.map { (key, val) in
            // http header field name should be case insensitive.
            // but according to [rfc7540](https://tools.ietf.org/html/rfc7540#section-8.1.2.6),
            // http/2 inner use lowercased name. so convert it first
            return HttpHeader(name: key.lowercased(), value: val)
        }
    }
    /// 为了处理方便，转换后的fieldname全是小写
    static func convert(back: [HttpHeader]) -> [String: String] {
        return back.reduce(into: [:]) { (result, header) in
            let name = header.name.lowercased()
            if let value = result[name] {
                // multiple field value can be folded by `, `, space is important for ios recognize!
                result[name] = "\(value), \(header.value)"
            } else {
                result[name] = header.value
            }
        }
    }
}

extension OnFetchResponse.OnHeaderResponse.ProtocolEnum {
    var canonicalName: String {
        switch self {
        case .http11: return "HTTP/1.1"
        case .http2: return "HTTP/2"
        case .quic: return "QUIC"
        @unknown default:
            logger.warn("unknown rusthttp protocol \(self)")
            return "HTTP/1.1"
        }
    }
}

extension NSURLRequest {
    /// 是否使用复合连接。复合连接会尝试建立多份连接，来获取更好的连接速度。但Header和Body的回调会延迟到结束请求时
    /// 同时有可能导致无响应timeout被URLSession cancel
    @objc public var enableComplexConnect: Bool {
        return URLProtocol.property(forKey: "_enableComplexConnect", in: self as URLRequest) as? Bool == true
    }
    /// 失败时是否重试，该选项会导致header和Body延迟到结束时才回调。
    /// 同时有可能导致无响应timeout被URLSession cancel
    @objc public var retryCount: Int {
         return URLProtocol.property(forKey: "_retryCount", in: self as URLRequest) as? Int ?? 0
    }
    /// RustHTTP的最大超时时间，区别于URLRequest本身的无响应超时 timeout
    @objc public var rustMaxTimeout: TimeInterval {
        return URLProtocol.property(forKey: "_rustMaxTimeout", in: self as URLRequest) as? TimeInterval ?? 0
    }
}

extension NSMutableURLRequest {
    /// 是否使用复合连接。复合连接会尝试建立多份连接，来获取更好的连接速度。但Header和Body的回调会延迟到结束请求时
    /// 同时有可能导致无响应timeout被URLSession cancel
    @objc public override var enableComplexConnect: Bool {
        get { return super.enableComplexConnect }
        set {
            URLProtocol.setProperty(newValue, forKey: "_enableComplexConnect", in: self)
            assert(enableComplexConnect == newValue, "set property enableComplexConnect should success")
        }
    }
    /// 失败时是否重试，该选项会导致header和Body延迟到结束时才回调。
    /// 同时有可能导致无响应timeout被URLSession cancel
    @objc public override var retryCount: Int {
        get { return super.retryCount }
        set {
            URLProtocol.setProperty(newValue, forKey: "_retryCount", in: self)
        }
    }
    /// RustHTTP的最大超时时间，区别于URLRequest本身的无响应超时 timeout
    @objc public override var rustMaxTimeout: TimeInterval {
        get { super.rustMaxTimeout }
        set {
            URLProtocol.setProperty(newValue, forKey: "_rustMaxTimeout", in: self)
            assert(rustMaxTimeout == newValue, "set property rustMaxTimeout should success")
        }
    }
}

extension URLProtocol {
    // 不知道以为苹果会不会改进URLRequest的兼容性，先这里扩展用着
    static func setProperty(_ value: Any, forKey key: String, in request: inout URLRequest) {
        guard let ref = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            return
            #endif
        }
        self.setProperty(value, forKey: key, in: ref)
        request = ref as URLRequest
    }
    static func removeProperty(forKey key: String, in request: inout URLRequest) {
        if property(forKey: key, in: request) != nil {
            if let ref = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
                self.removeProperty(forKey: key, in: ref)
                request = ref as URLRequest
            } else {
                #if DEBUG || ALPHA
                fatalError("unexpected")
                #endif
            }
        }
    }
}

extension URLRequest {
    /// 是否使用复合连接。复合连接会尝试建立多份连接，来获取更好的连接速度。但Header和Body的回调会延迟到结束请求时,
    /// 同时有可能导致无响应timeout被URLSession cancel
    public var enableComplexConnect: Bool {
        get { return URLProtocol.property(forKey: "_enableComplexConnect", in: self) as? Bool == true }
        set {
            URLProtocol.setProperty(newValue, forKey: "_enableComplexConnect", in: &self)
            assert(enableComplexConnect == newValue, "set property enableComplexConnect should success")
        }
    }
    /// 失败时是否重试，该选项会导致header和Body延迟到结束时才回调。
    /// 同时有可能导致无响应timeout被URLSession cancel, 因此需要设置一个大一点的timeout值
    public var retryCount: Int {
        get { return URLProtocol.property(forKey: "_retryCount", in: self) as? Int ?? 0 }
        set {
            URLProtocol.setProperty(newValue, forKey: "_retryCount", in: &self)
        }
    }
    /// RustHTTP的最大超时时间，区别于URLRequest本身的无响应超时 timeout
    public var rustMaxTimeout: TimeInterval {
        get { return URLProtocol.property(forKey: "_rustMaxTimeout", in: self) as? TimeInterval ?? 0 }
        set {
            URLProtocol.setProperty(newValue, forKey: "_rustMaxTimeout", in: &self)
            assert(rustMaxTimeout == newValue, "set property rustMaxTimeout should success")
        }
    }
}

/// use to print the case name. value must be a enum value
func enumCaseName(_ value: Any) -> String {
    let mirror = Mirror(reflecting: value)
    return mirror.children.first?.label ?? String(describing: value)
}

private var _uniqueID = AtomicUInt64Cell()
// each call generate a unique id
func getUniqueID() -> UInt64 { _uniqueID.increment(order: .relaxed) }

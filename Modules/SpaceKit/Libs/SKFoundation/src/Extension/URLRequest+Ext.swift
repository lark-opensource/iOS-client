//  Included OSS: DingSoung/Extension
//  Copyright (c) 2017 Songwen Ding
//  spdx license identifier: MIT

import Foundation
import SwiftyJSON

// MARK: - init request
extension URLRequest {
    public init?(method: HTTPMethod, url: String, parameters: [String: Any]? = nil, contentType: MIMEType? = nil) {
        guard let parameters = parameters else {
            self.init(method: method.raw, url: url, body: nil)
            return
        }
        switch method {
        case .get, .head, .delete:
            if parameters.isEmpty == false,
                let u = URL(string: url),
                var components = URLComponents(url: u, resolvingAgainstBaseURL: false) {
                let encodedQuery = (components.percentEncodedQuery.map { $0 + "&" } ?? "") + parameters.wwwFormUrlEncoded
                components.percentEncodedQuery = encodedQuery
                if let encodeUrl = components.url?.absoluteString {
                    self.init(method: method.raw, url: encodeUrl, body: nil)
                    return
                }
            }
            self.init(method: method.raw, url: url, body: nil)
        case .post:
            let cType = contentType ?? .json
            let body: Data?
            switch cType {
            case .wwwFormUrlEncoded:
                body = parameters.wwwFormUrlEncoded.data(using: .utf8, allowLossyConversion: false)
            case .json:
                body = parameters.json
            }
            self.init(method: HTTPMethod.post.raw, url: url, body: body)
            self.setValue(cType.raw, forHTTPHeaderField: "Content-Type")
        }
    }
    public init?(method: String, url: String, body: Data?) {
        guard let url = URL(string: url) else { return nil }
        self.init(url: url)
        self.networkServiceType = URLRequest.NetworkServiceType.default
        self.allowsCellularAccess = true
        self.httpMethod = method
        self.httpBody = body
        self.httpShouldHandleCookies = true
        self.httpShouldUsePipelining = true
    }
}

// MARK: - HTTPMethod
extension URLRequest {
    public enum HTTPMethod: Int {
        case get = 0, head, delete, post
    }
}

extension URLRequest.HTTPMethod {
    init?(raw: String) {
        switch raw {
        case "GET": self = .get
        case "HEAD": self = .head
        case "DELETE": self = .delete
        case "POST": self = .post
        default:
            // unsupport type: "OPTIONS" "PUT" "PATCH" "TRACE" "CONNECT"
            return nil
        }
    }
    var raw: String {
        switch self {
        case .get: return "GET"
        case .head: return "HEAD"
        case .delete: return "DELETE"
        case .post: return "POST"
        }
    }
}

// MARK: - MIMEType
extension URLRequest {
    public enum MIMEType: Int {
        case wwwFormUrlEncoded = 0, json
    }
}

extension URLRequest.MIMEType {
    init?(raw: String) {
        if raw.hasPrefix(URLRequest.MIMEType.wwwFormUrlEncoded.raw) { self = .wwwFormUrlEncoded; return }
        if raw.hasPrefix(URLRequest.MIMEType.json.raw) { self = .json; return }
        return nil
    }
    var raw: String {
        switch self {
        case .wwwFormUrlEncoded: return "application/x-www-form-urlencoded"
        case .json: return "application/json"
        }
        // unsupport type "charset=utf-8", "multipart/form-data", "text/xml"
    }
}

// MARK: - MIME transform for Content-Type Data
extension Data {
    public var jsonObject: Any? {
        do {
            return try  JSONSerialization.jsonObject(with: self)
        } catch let error {
            DocsLogger.error("data to jsobject fail", extraInfo: nil, error: error, component: nil)
            return nil
        }
    }

    public var json: JSON? {
        do {
            return try JSON(data: self, options: .mutableContainers)
        } catch {
            DocsLogger.warning(error.localizedDescription)
        }
        return nil
    }

    public var jsonArray: [Any]? {
        return self.jsonObject as? Array
    }
    public var jsonDictionary: [String: Any]? {
        return self.jsonObject as? [String: Any]
    }
}

// MARK: - MIME transform for Content-Type Dictionary
extension Dictionary where Key == String {
    public var json: Data? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        do {
            return try JSONSerialization.data(withJSONObject: self)
        } catch let error {
            DocsLogger.error("dict to json data fail", extraInfo: nil, error: error, component: nil)
            return nil
        }
    }
    public var wwwFormUrlEncoded: String {
        var components: [(String, String)] = []
        for key in self.keys.sorted(by: <) {
            let value = self[key]!
            components += String.queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    public var jsonString: String? {
        guard let data = self.json else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - copy from alamofire
extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

extension String {
    fileprivate var escape: String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        var escaped = ""
        escaped = self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? self
        return escaped
    }
    fileprivate static func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((key.escape, (value.boolValue ? "1" : "0").escape))
            } else {
                components.append((key.escape, "\(value)".escape))
            }
        } else if let bool = value as? Bool {
            components.append((key.escape, (bool ? "1" : "0").escape))
        } else {
            components.append((key.escape, "\(value)".escape))
        }
        return components
    }
}

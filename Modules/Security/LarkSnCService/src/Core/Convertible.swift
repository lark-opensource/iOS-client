//
//  Convertible.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/9/8.
//

import Foundation

public protocol URLConvertible {
    /// 构造完整 URL
    /// - Returns: URL 对象
    func asURL() throws -> URL
}

extension String: URLConvertible {
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw SnCError.invalidURL(self) }
        return url
    }
}

extension URLComponents: URLConvertible {
    public func asURL() throws -> URL {
        guard let url = self.url else { throw SnCError.invalidURL(self) }
        return url
    }
}

public protocol URLRequestConvertible {
    /// 构造完整 URLRequest
    /// - Returns: URLRequest
    func asURLRequest() throws -> URLRequest
}

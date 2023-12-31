//
//  SnCError.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/9/8.
//

import Foundation

/// SnC Service 中的错误
public enum SnCError: Error {
    case invalidURL(URLConvertible)
    case unknown
}

extension SnCError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidURL(url):
                return "URL is not valid: \(url)"
        case .unknown:
                return "unknown error."
        }
    }
}

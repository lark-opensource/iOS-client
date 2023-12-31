//
//  NetworkRequestOptions.swift
//  ByteViewNetwork
//
//  Created by kiri on 2022/12/20.
//

import Foundation

public struct NetworkRequestOptions: ExpressibleByArrayLiteral {

    public static let none = NetworkRequestOptions()
    /// 是否执行通用错误处理，默认为true
    public var shouldHandleError = true
    /// 是否保序，默认为false
    /// - 不同的command有不同的保序队列
    public var keepOrder = false
    /// 当>0时重试，默认为0
    /// - 业务错误时不重试
    public var retryCount = 0
    /// 仅在retryOwner != nil时retry，默认为一个永久的object
    public weak var retryOwner: AnyObject?
    /// contextId回调，默认为nil
    public var contextIdCallback: ((String) -> Void)?
    /// 是否打印response，默认为false
    public var shouldPrintResponse: Bool = false
    /// 错误预处理
    /// - 处理成功的不在走通用错误处理
    /// - shouldHandleError = false时无效
    public weak var preErrorHandler: NetworkErrorHandler?

    public init() {}

    public init(arrayLiteral elements: Option...) {
        for item in elements {
            switch item {
            case .notHandleError:
                shouldHandleError = false
            case .shouldPrintResponse:
                shouldPrintResponse = true
            case .keepOrder:
                keepOrder = true
            case let .retry(count, owner: owner):
                self.retryCount = count
                self.retryOwner = owner
            case let .contextIdCallback(callback):
                self.contextIdCallback = callback
            case let .preErrorHandler(handler):
                self.preErrorHandler = handler
            }
        }
    }

    public static func retry(_ count: Int, owner: AnyObject?) -> NetworkRequestOptions {
        var options = NetworkRequestOptions()
        options.retryCount = count
        options.retryOwner = owner
        return options
    }

    public static func contextIdCallback(_ callback: @escaping (String) -> Void) -> NetworkRequestOptions {
        var options = NetworkRequestOptions()
        options.contextIdCallback = callback
        return options
    }

    var isNone: Bool {
        shouldHandleError == true
        && keepOrder == false
        && retryCount == 0
        && contextIdCallback == nil
        && shouldPrintResponse == false
        && preErrorHandler == nil
    }

    public enum Option {
        case notHandleError
        case keepOrder
        case shouldPrintResponse
        case retry(_ count: Int, owner: AnyObject?)
        case contextIdCallback((String) -> Void)
        case preErrorHandler(NetworkErrorHandler?)
    }
}

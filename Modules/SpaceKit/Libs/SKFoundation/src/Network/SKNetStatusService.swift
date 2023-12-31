//
//  SKNetStatusService.swift
//  SKFoundation
//
//  Created by lijuyou on 2020/6/9.
//  


import Foundation

// MARK: - 网络状态监听
public typealias NetStatusCallback = (_ networkType: NetworkType, _ isReachable: Bool) -> Void
public enum NetworkType: Int {
    case wifi = 1
    case wwan4G = 2
    case wwan3G = 3
    case wwan2G = 4
    case notReachable = 5

    public func isWifi() -> Bool {
        return self == .wifi
    }

    public func isWwan() -> Bool {
        return self == .wwan2G || self == .wwan3G || self == .wwan4G
    }
}

public protocol SKNetStatusService {
    var accessType: NetworkType { get }
    var isReachable: Bool { get }
    func addObserver(_ observer: AnyObject, _ block: @escaping NetStatusCallback)
}

// MARK: - 网络请求
public protocol SKNetRequestServcie: AnyObject {
    init(skRequest: URLRequest)

    var requestID: String { get }

    @discardableResult
    func set(additionalStatistics: [String: Any]) -> Self

    @discardableResult
    func set(retryCount: UInt) -> Self

    @discardableResult
    func set(forceComplexConnect: Bool) -> Self

    @discardableResult
    func set(needFilterBOMChar: Bool) -> Self

    func start(rawResult: @escaping DRRawResponse)
    
    func cancel()
}

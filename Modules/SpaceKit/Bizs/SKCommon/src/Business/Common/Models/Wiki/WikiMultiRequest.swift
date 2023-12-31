//
//  WikiMultiRequest.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/26.
//

import Foundation
import SwiftyJSON
import SKFoundation

public final class WikiMultiRequest<Key: Hashable, Value>: NSObject {

    public enum ConflictStrategy {
        /// 不发送新请求
        case ignore
        /// 取消旧请求，重新发送请求
        case resend
    }

    @ThreadSafe private var requestMap: [Key: DocsRequest<Value>] = [:]

    public typealias RequestConfiguration = (DocsRequest<Value>) -> Void

    var conflictStrategy: ConflictStrategy

    public init(onConflict: ConflictStrategy) {
        conflictStrategy = onConflict
    }

    deinit {
        requestMap.values.forEach { $0.cancel() }
        requestMap = [:]
    }

    public func setupRequest(key: Key, path: String, params: [String: Any]?, qos: NetConfigQos = .default,
                      trafficType: NetConfigTrafficType = .default, callbackQueue: DispatchQueue = .main,
                      configuration: RequestConfiguration? = nil, completion: @escaping (Value?, Error?) -> Void) {
        if let request = requestMap[key] {
            switch conflictStrategy {
            case .ignore:
                return
            case .resend:
                request.cancel()
                requestMap[key] = nil
            }
        }
        let request = DocsRequest<Value>(path: path, params: params, qos: qos, trafficType: trafficType)
        configuration?(request)
        request.start(callbackQueue: callbackQueue) { [weak self] (value, error) in
            completion(value, error)
            if let error = error as NSError?,
            error.code == 999 {
                return
            }
            self?.requestMap[key] = nil
        }
        requestMap[key] = request
    }
}

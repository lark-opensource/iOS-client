//
//  Assembly.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/16.
//

import Foundation
import Swinject
import LarkAssembler
import LarkRustHTTP

public final class ECONetworkAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.register(ECONetworkClientProtocol.self, name: ECONetworkChannel.rust.rawValue) { (_, delegateQueue: OperationQueue, setting: ECONetworkRequestSetting)  in
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [EMARustHttpURLProtocol.self]
            configuration.timeoutIntervalForRequest = setting.timeout
            configuration.requestCachePolicy = setting.cachePolicy
            return ECONetworkClient(configuration: configuration, delegateQueue: delegateQueue)
        }.inObjectScope(.container)

        container.register(ECONetworkClientProtocol.self, name: ECONetworkChannel.native.rawValue) { (_, delegateQueue: OperationQueue, setting: ECONetworkRequestSetting)  in
            let configuration = URLSessionConfiguration.default
            // native 无 protocolClasses
            configuration.timeoutIntervalForRequest = setting.timeout
            configuration.requestCachePolicy = setting.cachePolicy
            return ECONetworkClient(configuration: configuration, delegateQueue: delegateQueue)
        }.inObjectScope(.container)
        
        container.register(ECONetworkRustHttpClientProtocol.self, name: ECONetworkChannel.rust.rawValue) { (_, delegateQueue: OperationQueue, setting: ECONetworkRequestSetting)  in
            let configuration = RustHTTPSessionConfig.default
            configuration.requestCachePolicy = setting.cachePolicy
            return ECONetworkRustClient(configuration: configuration, delegateQueue: delegateQueue)
        }.inObjectScope(.container)

        container.register(ECONetworkService.self) { _ in
            return ECONetworkServiceImpl(resolver: container)
        }.inObjectScope(.container)
    }
}

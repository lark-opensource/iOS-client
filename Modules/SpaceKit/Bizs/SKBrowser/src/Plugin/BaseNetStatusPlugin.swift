//
//  SKBaseNetStatusPlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/15.
//  

import Foundation
import SKCommon
import SKFoundation

public struct SKBaseNetStatusPluginConfig {
    weak var executeJsService: SKExecJSFuncService?
    let netStatusService: SKNetStatusService
    public init(executeJsService: SKExecJSFuncService, netstatusService: SKNetStatusService) {
        self.executeJsService = executeJsService
        self.netStatusService = netstatusService
    }
}
public final class SKBaseNetStatusPlugin: JSServiceHandler {
    public var logPrefix: String = ""
    private let config: SKBaseNetStatusPluginConfig
    public init(_ config: SKBaseNetStatusPluginConfig) {
        self.config = config
        observeNetStatus()
    }

    private func observeNetStatus() {
        config.netStatusService.addObserver(self) { [weak self] (networkType, isConnected) in
            guard let self = self, let service = self.config.executeJsService else { return }
            //这里延时是因为可能存在多个网页plug，可能会导致网络变化后的主线程堵塞
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                let params = ["type": networkType.rawValue, "connected": isConnected] as [String: Any]
                service.callFunction(DocsJSCallBack.notityNetStatus, params: params, completion: { (_, err) in
                    err.map {
                        skError("set net status JS error", extraInfo: ["error": "\($0)", "identify": self.logPrefix], error: nil, component: nil)
                    }
                    skInfo("net status to JS \(String(describing: params))", extraInfo: ["identify": self.logPrefix])
                })
            }
        }
    }

    public var handleServices: [DocsJSService] = []
    public func handle(params: [String: Any], serviceName: String) {
        skAssertionFailure("can not handle \(serviceName)")
    }
}

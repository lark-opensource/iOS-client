//
//  UniversalCardLynxResourceProvider.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/9/22.
//

import Foundation
import Lynx
import LarkStorage
import LarkContainer
import EEAtomic
import LarkSetting
import ECOInfra
import OPFoundation
import LarkStorageCore

public class UniversalCardLynxResourceProvider: NSObject, LynxResourceProvider {
    
    private static var service: ECONetworkService {
        Injected<ECONetworkService>().wrappedValue
    }
    @AtomicObject
    private static var data: Data?

    @FeatureGatingValue(key: "messagecard.updatelayoutcontainer.enable")
    var enableUpdateLayoutContainer: Bool
    
    public func request(_ request: LynxResourceRequest, onComplete callback: @escaping LynxResourceLoadBlock) {
#if ALPHA || DEBUG
        if request.url.hasPrefix("http") {
            let networkContext = OpenECONetworkAppContext(trace: OPTrace(traceId: ""), uniqueId: OPAppUniqueID(fullString: ""), source: .other)
            let task = Self.service.get(url: request.url, header: [:], params: [:], context: networkContext) { response, _ in
                if let data = response?.bodyData, !data.isEmpty {
                    callback(LynxResourceResponse(data: data))
                }
            }
            if let task = task {
                Self.service.resume(task: task)
            }
            
        } else {
            if enableUpdateLayoutContainer, let data = Self.data {
                callback(LynxResourceResponse(data: data))
                return
            }
            @Injected var moduleDependency: UniversalCardModuleDependencyProtocol
            guard let jsPath = moduleDependency.latestVersionCard(with: request.url),
                  let data = try? Data.read(from: jsPath) else {
                assertionFailure("MessageCardContainer load dynamic data fail")
                return
            }
            if enableUpdateLayoutContainer {
                Self.data = data
            }
            callback(LynxResourceResponse(data: data))
        }
#else
        if enableUpdateLayoutContainer, let data = Self.data {
            callback(LynxResourceResponse(data: data))
            return
        }
        @Injected var moduleDependency: UniversalCardModuleDependencyProtocol
        guard let jsPath = moduleDependency.latestVersionCard(with: request.url),
              let data = try? Data.read(from: jsPath) else {
            assertionFailure("MessageCardContainer load dynamic data fail")
            return
        }
        if enableUpdateLayoutContainer {
            Self.data = data
        }
        callback(LynxResourceResponse(data: data))
#endif
    }
    
    public func cancel(_ request: LynxResourceRequest) {}
    
}

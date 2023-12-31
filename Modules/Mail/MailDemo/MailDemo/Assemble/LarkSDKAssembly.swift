////
////  Dependency.swift
////  LarkSDKAssembly
////
////  Created by CharlieSu on 10/8/19.
////
//
//import Foundation
//import LarkSDK
//import Swinject
//import LarkModel
//import LarkAppConfig
//import LarkMessengerInterface
//import LarkContainer
//import SpaceInterface
//import RxSwift
//import LarkSDKInterface
//import LarkFeatureGating
//import EEAtomic
//import RustPB
//
//
//class LarkSDKAssembly: Assembly {
//
//    public init() { }
//
//    public func assemble(container: Container) {
//        let resolver = container
//        container.register(SDKDependency.self) { _ -> SDKDependency in
//            return SDKDependencyImpl(resolver: resolver)
//        }
//    }
//}
//
//class SDKDependencyImpl: SDKDependency {
//
//    fileprivate let resolver: Resolver
//
//
//    init(resolver: Resolver) {
//        self.resolver = resolver
//    }
//
//    // MARK: RustSendMessageAPIDependency & RustSendThreadAPIDependency
//    private lazy var modelService = { return resolver.resolve(ModelService.self)! }()
//    private lazy var feedSyncDispatchService = { return resolver.resolve(FeedSyncDispatchService.self)! }()
//
//    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus {
//        return feedSyncDispatchService.dynamicNetStatus
//    }
//
//    var imageToFileThresholdMB: Double {
//        return 25
//    }
//
//    func messageSummerize(_ message: LarkModel.Message) -> String {
//        return modelService.messageSummerize(message)
//    }
//
//    func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
//        return (false, "", "")
//    }
//
//    func setCallModel(_ call: Videoconference_V1_E2EEVoiceCall) {
//        // nothing
//    }
//
//    // MARK: DocsCacheDependency
//    private lazy var docsCacheService = { return resolver.resolve(DocsUserCacheServiceProtocol.self)! }()
//
//    func calculateCacheSize() -> Observable<Float> {
//        return docsCacheService.calculateCacheSize()
//    }
//
//    func clearCache() -> Observable<Void> {
//        return docsCacheService.clearCache()
//    }
//}

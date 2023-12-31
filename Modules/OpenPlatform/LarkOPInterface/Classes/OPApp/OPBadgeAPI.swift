//
//  OPBadgeAPI.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/10/16.
//

import Foundation
import LKCommonsLogging
import LarkRustClient
import RxSwift

public protocol OPBadgeAPI {

    init(rustService: RustService)
    /// 拉取 Badge 数据
    /// 包含本地数据和远端数据拉取，优先拉取本地，再拉取远端数据，可能会有多次返回
    ///
    /// - Parameter
    /// - appId: appId
    /// - featureType: 开平应用能力类型, 值：miniApp, h5
    /// - Returns: badge 信息
    func pullBadgeData(
        for appId: String,
        featureType: OPBadgeRustAlias.OpenAppFeatureType)
    -> Observable<[OPBadgeRustAlias.OpenAppBadgeNode]>
}

public final class RustOpenAppBadgeAPI: OPBadgeAPI {
    
    static let logger = Logger.log(RustOpenAppBadgeAPI.self)
    
    private let rustService: RustService
    
    public init(rustService: RustService) {
        self.rustService = rustService
    }
    
    public func pullBadgeData(
        for appId: String,
        featureType: OPBadgeRustAlias.OpenAppFeatureType
    ) -> Observable<[OPBadgeRustAlias.OpenAppBadgeNode]> {
        Self.logger.info("[OPBadge] start pull badge data", additionalData: [
            "appId" : appId,
            "featureType" : "\(featureType.rawValue)"
        ])
        var idFeaturePair = OPBadgeRustAlias.IdFeaturePair()
        idFeaturePair.appID = appId
        idFeaturePair.feature = featureType
        return pullBadge(strategy: .local, idFeaturePairs: [idFeaturePair])
            .flatMap({ [weak self] badgeNodes -> Observable<[OPBadgeRustAlias.OpenAppBadgeNode]> in
                guard let `self` = self else {
                    return .just(badgeNodes)
                }
                return self.pullRemoteBadge(for: appId, featureType: featureType)
                    .startWith(badgeNodes)
            })
            .catchError({ [weak self] error in
                guard let `self` = self else { throw error }
                Self.logger.error("[OPBadge] pull badge data fail", additionalData: [
                    "appId" : appId,
                    "featureType" : "\(featureType.rawValue)",
                    "errorDesc" : error.localizedDescription
                ])
                return self.pullRemoteBadge(for: appId, featureType: featureType)
            })
    }

    private func pullBadge(
        strategy: OPBadgeRustAlias.LoadStrategy,
        idFeaturePairs: [OPBadgeRustAlias.IdFeaturePair]
    ) -> Observable<[OPBadgeRustAlias.OpenAppBadgeNode]> {
        var request = OPBadgeRustAlias.PullOpenAppBadgeNodesRequest()
        request.isMobile = true
        request.needTriggerPush = true
        request.strategy = strategy
        request.idFeaturePairs = idFeaturePairs
        return rustService.sendAsyncRequest(
            request,
            transform: { (res: OPBadgeRustAlias.PullOpenAppBadgeNodesResponse) -> [OPBadgeRustAlias.OpenAppBadgeNode] in
                let badgeNodes = res.noticeNodes
                let nodesLogInfo: [[String: String]] = badgeNodes.map({ [
                    "appId": $0.appID,
                    "needShow": "\($0.needShow)",
                    "badgeNum": "\($0.badgeNum)",
                    "version": "\($0.version)",
                    "feature": "\($0.feature)",
                    "updateTime": "\($0.updateTime)"
                ] })
                Self.logger.error("[OPBadge] pull badge data, get response", additionalData: [
                    "strategy": "\(strategy.rawValue)",
                    "badgeNodes.count": "\(badgeNodes.count)",
                    "badgeNodes": "\(nodesLogInfo)"
                ])
                return badgeNodes
            }
        )
    }

    private func pullRemoteBadge(
        for appId: String,
        featureType: OPBadgeRustAlias.OpenAppFeatureType
    ) -> Observable<[OPBadgeRustAlias.OpenAppBadgeNode]> {
        var idFeaturePair = OPBadgeRustAlias.IdFeaturePair()
        idFeaturePair.appID = appId
        idFeaturePair.feature = featureType
        return pullBadge(strategy: .net, idFeaturePairs: [idFeaturePair])
            .map({ badgeNodes in
                return badgeNodes
            })
    }
}

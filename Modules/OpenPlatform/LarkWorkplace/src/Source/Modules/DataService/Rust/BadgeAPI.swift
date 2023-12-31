//
//  BadgeAPI.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/7/8.
//

import Foundation
import RxSwift

/// Badge API
protocol BadgeAPI {

    /// 拉取 Web badge
    ///
    /// 包含本地数据和远端数据拉取，优先拉取本地，再拉取远端数据，可能会有多次返回
    ///
    /// - Parameter web: web 初始化数据
    /// - Returns: badge 信息
    func pullWorkplaceWebBadgeData(for web: WPHomeVCInitData.Web) -> Observable<BadgeLoadType.LoadData>

    /// flush badge 信息到 rust
    /// - Parameter badgeNodes: badgeNodes
    func saveBadgeNodes(_ badgeNodes: [Rust.OpenAppBadgeNode]) -> Observable<Void>
}

final class RustBadgeAPI: WorkplaceAPI, BadgeAPI {
    func pullWorkplaceWebBadgeData(for web: WPHomeVCInitData.Web) -> Observable<BadgeLoadType.LoadData> {
        var idFeaturePair = Rust.IdFeaturePair()
        idFeaturePair.appID = web.refAppId
        idFeaturePair.feature = .h5
        return pullBadge(strategy: .local, idFeaturePairs: [idFeaturePair])
            .flatMap({ [weak self]badgeNodes -> Observable<BadgeLoadType.LoadData> in
                let localWebData = BadgeLoadType.LoadData.WebData(
                    portalId: web.id,
                    scene: .fromRustLocal,
                    badgeNodes: badgeNodes
                )
                guard let `self` = self else { return .just(.web(localWebData)) }
                return self.pullRemoteWebBadge(for: web)
                    .startWith(.web(localWebData))
            })
            .catchError({ [weak self]error -> Observable<BadgeLoadType.LoadData> in
                guard let `self` = self else { throw error }
                return self.pullRemoteWebBadge(for: web)
            })
    }

    func saveBadgeNodes(_ badgeNodes: [Rust.OpenAppBadgeNode]) -> Observable<Void> {
        var request = Rust.SaveOpenAppBadgeNodesRequest()
        request.badgeNodes = badgeNodes
        request.needTriggerPush = true
        return rustService.sendAsyncRequest(request)
    }

    private func pullBadge(
        strategy: Rust.LoadStrategy, idFeaturePairs: [Rust.IdFeaturePair]
    ) -> Observable<[Rust.OpenAppBadgeNode]> {
        var request = Rust.PullOpenAppBadgeNodesRequest()
        request.isMobile = true
        request.needTriggerPush = true
        request.strategy = strategy
        request.idFeaturePairs = idFeaturePairs
        return rustService.sendAsyncRequest(
            request,
            transform: { (res: Rust.PullOpenAppBadgeNodesResponse) -> [Rust.OpenAppBadgeNode] in
                return res.noticeNodes
            }
        )
    }

    private func pullRemoteWebBadge(for web: WPHomeVCInitData.Web) -> Observable<BadgeLoadType.LoadData> {
        var idFeaturePair = Rust.IdFeaturePair()
        idFeaturePair.appID = web.refAppId
        idFeaturePair.feature = .h5
        return pullBadge(strategy: .net, idFeaturePairs: [idFeaturePair])
            .map({ badgeNodes in
                let webData = BadgeLoadType.LoadData.WebData(
                    portalId: web.id,
                    scene: .fromRustNet,
                    badgeNodes: badgeNodes
                )
                return .web(webData)
            })
    }
}

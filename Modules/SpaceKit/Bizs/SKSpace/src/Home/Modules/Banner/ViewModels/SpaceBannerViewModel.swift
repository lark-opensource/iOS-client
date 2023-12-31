//
//  SpaceBannerViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/2.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKCommon
import LarkLocalizations
import ServerPB
import LarkContainer
import UGBanner
import UGReachSDK
import UGRCoreIntegration

public final class SpaceBannerViewModel {

    @InjectedLazy private var reachService: UGReachSDKService
    private let reachPointId: String
    private let scenarioId: String

    lazy var bannerReachPoint: BannerReachPoint? = {
        let reachPoint: BannerReachPoint? = reachService.obtainReachPoint(reachPointId: reachPointId, bizContextProvider: nil)
        return reachPoint
    }()

    public init(reachPointId: String = "RP_CCM-HOME_TOP",
                scenarioId: String = "SCENE_COMMON") {
        self.reachPointId = reachPointId
        self.scenarioId = scenarioId
    }

    deinit {
        reachService.recycleReachPoint(reachPointId: self.reachPointId, reachPointType: BannerReachPoint.reachPointType)
    }

    func startPullUgBannerData() {
        let ctxProvider = SyncBizContextProvider(scenarioId: scenarioId, contextBlock: {
            return ["version": "4"]
           })
        reachService.tryExpose(by: scenarioId,
                               actionRuleContext: nil,
                               bizContextProvider: ctxProvider)
    }

    func closeCurUGBanner() {
        bannerReachPoint?.reportEvent(eventName: .consume)
        bannerReachPoint?.hide()
    }
}

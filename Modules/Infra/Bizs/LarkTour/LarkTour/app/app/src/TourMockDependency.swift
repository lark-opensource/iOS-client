//
//  TourMockDependency.swift
//  AFNetworking
//
//  Created by Meng on 2020/5/21.
//

import UIKit
import Foundation
import EENavigator
import LarkTourInterface
import LarkModel
import RxSwift
import LarkFeatureGating
import LarkNavigation

open class TourMockDependency: TourDependency {

    open func generateAddFriendsViewController(title: String?, skipText: String?, confirmText: String?, nextHandler: @escaping () -> Void) -> Observable<UIViewController?> {
        let fakeAddFriendsViewController = FakeAddFriendsViewController()
        fakeAddFriendsViewController.skipText = "跳过"
        fakeAddFriendsViewController.nextHandler = nextHandler
        return Observable.of(FakeAddFriendsViewController())
    }

    open func pushToChatId(
        _ chatId: String,
        from: NavigatorFrom,
        animated: Bool,
        completion: ((Request, Response) -> Void)?
    ) {
        let vc = FakeChatController(chatId: chatId)
        Navigator.shared.push(vc, from: from, animated: animated)
    }

    /// 生成邀请成员VC
    open func generateInviteMemberViewController(
        isUpgrade: Bool,
        baseView: UIView?,
        nextHandler: @escaping () -> Void,
        sourceScenes: String,
        nextTitle: String?
    ) -> Observable<UIViewController?> {
        let vc = FakeInviteController()
        vc.nextHandler = nextHandler
        return .just(vc)
    }

    /// 团队加入-卡片信息
    open func generateTeamJoinCardInfo() -> Observable<TeamJoinGuideInfo> {
        let teamJoinPushData = TeamJoinPushData(userID: "",
                                                tenantID: "",
                                                tenantName: "MockName",
                                                type: .show,
                                                isActiveJoin: false)
        return Observable.of(TeamJoinGuideInfo(teamJoinPushData: teamJoinPushData,
                                               closeHandler: { _ in },
                                               title: "mock title",
                                               message: "mock",
                                               laterTitle: "later",
                                               switchTitle: "switch"))
    }

    /// 团队加入-发送卡片信号
    open func triggerTeamJoinGuideEvent(teamJoinGuideInfo: TeamJoinGuideInfo) {}

    /// 归因信息是否ready（AF SDK场景）
    open var conversionDataReady: Bool {
        return true
    }
    /// 归因信息处理block
    open func setConversionDataHandler(_ handler: @escaping (String) -> Void) {}

    open var needSkipOnboarding: Bool = false
}

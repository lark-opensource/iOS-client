//
//  FeedMainViewModelDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/23.
//

import UIKit
import Foundation
import RustPB
import LarkSDKInterface
import RxSwift
import RxCocoa
import SwiftProtobuf
import LarkMessengerInterface
import LarkOpenFeed
import RxRelay
import LarkRustClient
import LarkContainer

protocol FeedMainViewModelDependency: UserResolverWrapper {

    // MARK: - FloatAction
    func dynamicMemberInvitePageResource(baseView: UIView?,
                 sourceScenes: MemberInviteSourceScenes,
                 departments: [String]) -> Observable<ExternalDependencyBodyResource>

    func handleInviteEntryRoute(routeHandler: @escaping (InviteEntryType) -> Void)

    // MARK: - GuideService

    // 是否显示引导
    func needShowGuide(key: String) -> Bool

    /// 已经显示引导
    func didShowGuide(key: String)

    /// 是否显示新引导
    func needShowNewGuide(guideKey: String) -> Bool

    /// 上报显示新引导
    func didShowNewGuide(guideKey: String)

    // MARK: - GuideTeamJoin

    var filtersDriver: Driver<[FilterItemModel]> { get }

    //展示切换至基本功能模式提示(内部会去判断是否需要执行展示逻辑)
    //show：具体的展示逻辑
    func showMinimumModeChangeTip(show: () -> Void)

    var selectFeedObservable: Observable<FeedSelection?> { get }

    func showMinimumModeTipViewEnable() -> Bool

    var isDefaultSearchButtonDisabled: Bool { get }
}

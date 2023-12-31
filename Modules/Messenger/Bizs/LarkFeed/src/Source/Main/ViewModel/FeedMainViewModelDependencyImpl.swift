//
//  FeedMainViewModelDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/23.
//

import UIKit
import Foundation
import RustPB
import LarkSDKInterface
import LarkRustClient
import SwiftProtobuf
import RunloopTools
import LarkMessengerInterface
import LarkOpenFeed
import RxRelay
import RxSwift
import RxCocoa
import LarkContainer
import Swinject
import LarkNavigation

final class FeedMainViewModelDependencyImpl: FeedMainViewModelDependency {
    let userResolver: UserResolver
    let feedGuideDependency: FeedGuideDependency

    let invitationService: UnifiedInvitationService
    let chatterManager: ChatterManagerProtocol

    let filtersDriver: Driver<[FilterItemModel]>
    private let feedSelection: FeedSelectionService

    var selectFeedObservable: Observable<FeedSelection?> {
        return self.feedSelection.selectFeedObservable
    }

    init(resolver: UserResolver,
         filtersDriver: Driver<[FilterItemModel]>,
         feedSelection: FeedSelectionService
    ) throws {
        self.userResolver = resolver
        self.feedGuideDependency = try resolver.resolve(assert: FeedGuideDependency.self)
        self.invitationService = try resolver.resolve(assert: UnifiedInvitationService.self)
        self.chatterManager = try resolver.resolve(assert: ChatterManagerProtocol.self)
        self.filtersDriver = filtersDriver
        self.feedSelection = feedSelection
    }

    // MARK: - FloatAction
    func dynamicMemberInvitePageResource(baseView: UIView?,
                sourceScenes: MemberInviteSourceScenes,
                departments: [String]) -> Observable<ExternalDependencyBodyResource> {
        return invitationService.dynamicMemberInvitePageResource(baseView: baseView,
                                                                 sourceScenes: sourceScenes,
                                                                 departments: departments)
    }

    func handleInviteEntryRoute(routeHandler: @escaping (InviteEntryType) -> Void) {
        invitationService.handleInviteEntryRoute(routeHandler: routeHandler)
    }

    // MARK: - GuideService
    /// 是否显示切租户引导
    func needShowGuide(key: String) -> Bool {
        return feedGuideDependency.needShowGuide(key: key)
    }

    func didShowGuide(key: String) {
        feedGuideDependency.didShowGuide(key: key)
    }

    /// 是否显示新引导
    func needShowNewGuide(guideKey: String) -> Bool {
        return feedGuideDependency.checkShouldShowGuide(key: guideKey)
    }

    /// 上报显示新引导
    func didShowNewGuide(guideKey: String) {
        feedGuideDependency.didShowNewGuide(key: guideKey)
    }

    // MARK: - GuideTeamJoin

    func showMinimumModeTipViewEnable() -> Bool {
        return self.chatterManager.currentChatter.isCustomer && Feed.Feature(userResolver).isBasicModeEnabe
    }

    func showMinimumModeChangeTip(show: () -> Void) { }

    var isDefaultSearchButtonDisabled: Bool {
        if let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOuterService.enableUseNewSearchEntranceOnPad() {
            return true
        }
        return false
    }
}

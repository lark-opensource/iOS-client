//
//  FlagDataDependencyImpl.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import LarkModel
import LarkContainer
import RxSwift
import LarkCore
import Swinject
import LarkFeatureGating
import LarkOpenFeed
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import TangramService
import RustPB
import RxCocoa

final class FlagDataDependencyImpl: FlagDataDependency {

    let userResolver: UserResolver

    private var selection = BehaviorRelay<String?>(value: nil)

    // iPad选中态监听
    func observeSelect() -> Observable<String?> {
        return selection.asObservable()
    }

    // 设置FlagItem选中
    func setSelected(flagId: String?) {
        selection.accept(flagId)
    }

    // 获取当前选中FlagItem的FlagId
    func getSelected() -> String? {
        return selection.value
    }

    // 先这么写，之后需要解耦
    var getResolver: UserResolver {
        return userResolver
    }

    var audioPlayer: AudioPlayMediator? {
        return try? userResolver.resolve(assert: AudioPlayMediator.self)
    }

    var feedAPI: FeedAPI? {
        return try? userResolver.resolve(assert: FeedAPI.self)
    }

    var flagAPI: FlagAPI? {
        return try? userResolver.resolve(assert: FlagAPI.self)
    }

    var chatAPI: ChatAPI? {
        return try? userResolver.resolve(assert: ChatAPI.self)
    }

    var abbreviationEnable: Bool {
        let enterpriseEntityService = try? userResolver.resolve(assert: EnterpriseEntityWordService.self)
        return enterpriseEntityService?.abbreviationHighlightEnabled() ?? false
    }

    lazy var checkIsMe: CheckIsMe = {
        return { [weak self] id in
            return self?.userResolver.userID == id
        }
    }()

    var isByteDancer: Bool {
        return self.passportUserService?.user.tenant.isByteDancer ?? false
    }

    var passportUserService: PassportUserService? {
        return try? userResolver.resolve(assert: PassportUserService.self)
    }

    var audioResourceService: AudioResourceService? {
        return try? userResolver.resolve(assert: AudioResourceService.self)
    }

    lazy var is24HourTime: Driver<Bool> = {
        let userGeneralSettingService = try? self.userResolver.resolve(assert: UserGeneralSettings.self)
        let replay = userGeneralSettingService?.is24HourTime ?? BehaviorRelay<Bool>(value: true)
        return replay.asDriver()
    }()

    let inlinePreviewVM: MessageInlineViewModel

    // Push: PushFeedHandler
    let pushFeedMessage: Observable<PushFeedMessage>

    // Push: PushFlagHandler
    var pushFlagMessage: Observable<PushFlagMessage>

    // Push: PushFeedFilterHandler
    var pushFeedFilterMessage: Observable<PushFeedFilterMessage>

    var refreshObserver = PublishSubject<Void>()

    let feedThreeBarService: FeedThreeBarService?

    var iPadStatus: String? {
        if let unfold = feedThreeBarService?.padUnfoldStatus {
            return unfold ? "unfold" : "fold"
        }
        return nil
    }

    let teamActionService: TeamActionService?

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.inlinePreviewVM = MessageInlineViewModel()
        self.pushFeedMessage = try userResolver.userPushCenter.observable(for: LarkFlag.PushFeedMessage.self)
        self.pushFlagMessage = try userResolver.userPushCenter.observable(for: LarkFlag.PushFlagMessage.self)
        self.pushFeedFilterMessage = try userResolver.userPushCenter.observable(for: LarkFlag.PushFeedFilterMessage.self)
        self.feedThreeBarService = try? userResolver.resolve(assert: FeedThreeBarService.self)
        self.teamActionService = try? userResolver.resolve(assert: TeamActionService.self)
    }

    // feed清除未读
    func clearSingleBadge(feedID: String, feedEntityPBType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        var feed = Feed_V1_FeedCardBadgeIdentity()
        feed.feedID = feedID
        feed.feedEntityType = feedEntityPBType
        let taskID = UUID().uuidString
        return feedAPI?.clearSingleBadge(taskID: taskID, feeds: [feed]) ?? Observable<Void>.empty()
    }
}

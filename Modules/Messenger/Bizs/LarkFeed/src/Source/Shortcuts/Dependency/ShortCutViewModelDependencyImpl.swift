//
//  ShortCutViewModelDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15.
//

import UIKit
import Foundation
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkMessengerInterface
import UniverseDesignDialog
import Swinject
import LarkContainer

final class ShortCutViewModelDependencyImpl: ShortCutViewModelDependency, UserResolverWrapper {
    let userResolver: UserResolver
    private let feedAPI: FeedAPI

    private let feedSelectionService: FeedSelectionService

    var pushShortcuts: Observable<PushShortcuts>
    let pushFeedPreview: Observable<PushFeedPreview>

    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle>

    private let disposeBag: DisposeBag = DisposeBag()

    init(resolver: UserResolver,
         pushShortcuts: Observable<PushShortcuts>,
         pushFeedPreview: Observable<PushFeedPreview>,
         badgeStyleObservable: Observable<Settings_V1_BadgeStyle>
    ) throws {
        self.userResolver = resolver
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.feedSelectionService = try resolver.resolve(assert: FeedSelectionService.self)

        self.pushShortcuts = pushShortcuts
        self.pushFeedPreview = pushFeedPreview
        self.badgeStyleObservable = badgeStyleObservable
    }

    // 获取数据
    func loadShortcuts(strategy: Basic_V1_SyncDataStrategy) -> Observable<FeedContextResponse> {
        feedAPI.loadShortcuts(strategy: strategy)
    }

    func update(shortcut: RustPB.Feed_V1_Shortcut, newPosition: Int) -> Observable<Void> {
        feedAPI.update(shortcut: shortcut, newPosition: newPosition)
    }

    func removeFeedCard(channel: Basic_V1_Channel,
                     feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType?,
                     from vc: UIViewController?) {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkFeed.Lark_IM_YouAreNotInThisChat_Text, numberOfLines: 0)
        dialog.addPrimaryButton(text: BundleI18n.LarkFeed.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.feedAPI.removeFeedCard(channel: channel, feedType: feedPreviewPBType).subscribe().disposed(by: self.disposeBag)
        })
        vc?.present(dialog, animated: true, completion: nil)
    }

    func preloadChatFeed(by ids: [String]) {
        self.feedAPI.preloadFeedCards(by: ids, feedPosition: nil).subscribe().disposed(by: disposeBag)
    }

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String? {
        feedSelectionService.getSelected()
    }
}

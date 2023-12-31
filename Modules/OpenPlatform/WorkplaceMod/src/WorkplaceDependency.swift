//
//  WorkplaceDependency.swift
//  WorkplaceMod
//
//  Created by Meng on 2022/6/14.
//

import EENavigator
import Foundation
import LarkWorkplace
import LarkOPInterface
import LKCommonsLogging
import RxSwift
import Swinject
import LarkTab
import LarkUIKit
import LarkContainer
import LarkNavigator
import LarkWorkplaceModel

#if OpenPlatformMod
import LarkMicroApp
#endif

#if MessengerMod
import LarkMessengerInterface
import LarkSDKInterface
import LarkForward
#endif

final class WorkplaceDependencyImpl: WorkPlaceDependency {
    private let logger = Logger.log(WorkPlaceDependency.self)
    private let userResolver: UserResolver

    private var openplatformService: OpenPlatformService? {
        return try? userResolver.resolve(assert: OpenPlatformService.self)
    }

#if OpenPlatformMod
    private var badgeService: AppBadgeAPI? {
        return try? userResolver.resolve(assert: AppBadgeAPI.self)
    }
#endif

#if MessengerMod
    private var chatService: ChatService? {
        return try? userResolver.resolve(assert: ChatService.self)
    }
#endif

    private var navigator: UserNavigator {
        return userResolver.navigator
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // MAKR: - WorkplaceDependencyShare
    func shareAppFromWorkplaceAppCard(with appId: String, from: UIViewController) {
#if OpenPlatformMod
        let shareFromType = ShareFromType.workplaceAppCard
        let appLink = openplatformService?.buildAppShareLink(with: appId, opTracking: shareFromType.opTracking)
        let appShare = ShareApp(appId: appId, link: appLink)
        // /client/app_share/open 类型，appType 暂时取unknown
        let body = OPShareBody(shareType: .app(appShare), fromType: shareFromType)
        navigator.open(body: body, from: from)
#else
        // do nothing
#endif
    }

    func sharePureLink(with link: String, from: UIViewController, sentHandler: @escaping ([String], [String]) -> Void) {
#if MessengerMod
        let forwardTextBody = ForwardTextBody(text: link, sentHandler: sentHandler)
        navigator.present(
            body: forwardTextBody,
            from: from,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
#else
        // do nothing
#endif
    }

    func shareBlockCard(from: UIViewController, shareTaskGenerator: @escaping ([WPMessageReceiver], String?) -> Observable<[String]>?) {
#if MessengerMod
        let forwardBlockBody = WorkplaceForwardBlockBody(shareTaskGenerator: shareTaskGenerator)
        navigator.present(
            body: forwardBlockBody,
            from: from,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
#else
        // do nothing
#endif
    }

    // MARK: - WorkPlaceDependencyBadge
    func update(appID: String, badgeEnable: Bool) {
#if OpenPlatformMod
        let extraModel = UpdateBadgeRequestParameters(type: UpdateBadgeRequestParametersType.needShow)
        extraModel.needShow = badgeEnable
        extraModel.scene = AppBadgeUpdateNodeScene.workplaceSetting
        badgeService?.updateAppBadge(
            appID,
            appType: nil,
            extra: extraModel,
            completion: { (result, error) in
                self.logger.info("badge update, result(\(String(describing: result))), error(\(String(describing: error)))")
            }
        )
#else
        // do nothing
#endif
    }

    func pull(appID: String) {
#if OpenPlatformMod
        let pullExtra = PullBadgeRequestParameters(scene: AppBadgePullNodeScene.rustNet)
        badgeService?.pullAppBadge(
            appID,
            appType: nil,
            extra: pullExtra,
            completion: { (result, error) in
                self.logger.info("badge pull, result(\(String(describing: result))), error(\(String(describing: error)))")
            }
        )
#else
        // do nothing
#endif
    }

    // MARK: - WorkPlaceDependencyNavigation
    func showDiagnoseSettingVC(from: UIViewController) {
#if MessengerMod
        let body = NetDiagnoseSettingBody(from: .workplace)
        // iPhone为push，iPad为present
        navigator.presentOrPush(body: body, from: from)
#else
        // do nothing
#endif
    }

    func toMainSearch(from: UIViewController) {
#if MessengerMod
        let body = SearchMainBody(topPriorityScene: .rustScene(.searchOpenAppScene), sourceOfSearch: .workplace)
        navigator.push(body: body, from: from)
#else
        // do nothing
#endif
    }

    func toChat(_ info: WPChatInfo, completion: ((Bool) -> Void)?) {
#if MessengerMod
        chatService?.createP2PChat(
            userId: info.userId,
            isCrypto: false,
            chatSource: nil
        )
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self](chat) in
            let body = ChatControllerByChatBody(chat: chat)
            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
            ]
            var from: NavigatorFrom
            if let f = info.from {
                from = f
            } else if let f = Navigator.shared.mainSceneWindow?.fromViewController {
                from = f
            } else {
                completion?(false)
                return
            }
            self?.navigator.showAfterSwitchIfNeeded(
                tab: Tab.feed.url,
                body: body,
                context: context,
                wrap: LkNavigationController.self,
                from: from
            )
            completion?(true)
        }).disposed(by: info.disposeBag)
#else
        // do nothing
#endif
    }
}

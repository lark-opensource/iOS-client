//
//  LarkProfileDataProviderDependencyImp.swift
//  LarkContact
//
//  Created by 姚启灏 on 2021/7/19.
//

import UIKit
import Foundation
import LarkSDKInterface
import EENavigator
import LarkAlertController
import LarkCore
import LarkContainer
import LarkMessengerInterface
import LarkOpenFeed
import AnimatedTabBar
import LarkUIKit
import LarkAccountInterface
import LarkModel
import SuiteAppConfig
import LarkFeatureGating
import UniverseDesignToast
import RxSwift
import LarkTab
import LarkSceneManager
import RustPB
import LarkProfile

final class LarkProfileDataProviderDependencyImp: LarkProfileDataProviderDependency, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var dependency: ContactDependency?
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var feedAPI: FeedAPI?

    private let disposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    func startByteViewFromAddressBookCard(userId: String) {
        dependency?.startByteViewFromAddressBookCard(userId: userId)
    }

    func jumpToChatViewController(_ userId: String,
                                  isCrypto: Bool,
                                  fromVC: UIViewController,
                                  needShowErrorAlert: Bool,
                                  chatSource: LarkUserProfilChatSource,
                                  source: LarkUserProfileSource) {
        DispatchQueue.global().async {
            let chatId = self.chatAPI?.getLocalP2PChat(by: userId)?.id

            var createChatSource = CreateChatSource()
            createChatSource.senderIDV2 = chatSource.senderIDV2
            createChatSource.sourceID = chatSource.sourceID
            createChatSource.sourceName = chatSource.sourceName
            createChatSource.sourceType = chatSource.sourceType
            createChatSource.subSourceType = chatSource.subSourceType

            let body = ChatControllerByChatterIdBody(
                chatterId: userId,
                fromWhere: .profile,
                isCrypto: isCrypto,
                isPrivateMode: false,
                needShowErrorAlert: needShowErrorAlert,
                createChatSource: createChatSource
            )

            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chatId, selectionType: .skipSame)
            ]

            DispatchQueue.main.async {
                // 转换下类型，因为需要调showAlert方法
                let goToChat: (NavigatorFrom) -> Void = { (from: NavigatorFrom) in
                    self.navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url,
                                                             body: body,
                                                             context: context,
                                                             wrap: LkNavigationController.self,
                                                             from: from)
                }
                if Display.phone || !SceneManager.shared.supportsMultipleScenes {
                    goToChat(fromVC)
                } else if SceneManager.shared.supportsMultipleScenes {
                    if #available(iOS 13.0, *) {
                        /// iPad 中会优先跳转已经开启的辅助 scene
                        /// 如果是在非主 scene 打开，则在主 scene 打开
                        // scene 配置
                        let scene = LarkSceneManager.Scene(
                            key: "P2pChat",
                            id: userId,
                            windowType: "single",
                            createWay: "window_click"
                        )
                        if SceneManager.shared.connectedScene(scene: scene) != nil {
                            /// 已经存在对应 scene， 直接激活
                            SceneManager.shared.active(scene: scene, from: fromVC) { [weak fromVC] (_, error) in
                                if error != nil, let vc = fromVC {
                                    UDToast.showTips(
                                        with: BundleI18n.LarkContact.Lark_Core_SplitScreenNotSupported,
                                        on: vc.view
                                    )
                                }
                            }
                        } else {
                            /// 激活主 scene 跳转页面
                            SceneManager.shared.active(scene: Scene.mainScene(), from: fromVC) { [weak fromVC] (window, error) in
                                if let window = window {
                                    goToChat(window)
                                } else if error != nil,
                                  let vc = fromVC {
                                  UDToast.showTips(
                                      with: BundleI18n.LarkContact.Lark_Core_SplitScreenNotSupported,
                                      on: vc.view
                                  )
                                }
                            }
                        }
                    }
                }
            }

            self.peakFeedCard(userId)
        }
    }

    func jumpToChatViewController(_ userId: String,
                                  isCrypto: Bool,
                                  isPrivate: Bool,
                                  fromVC: UIViewController,
                                  needShowErrorAlert: Bool,
                                  chatSource: LarkUserProfilChatSource,
                                  source: LarkUserProfileSource) {
        DispatchQueue.global().async {
            let chatId = self.chatAPI?.getLocalP2PChat(by: userId)?.id

            var createChatSource = CreateChatSource()
            createChatSource.senderIDV2 = chatSource.senderIDV2
            createChatSource.sourceID = chatSource.sourceID
            createChatSource.sourceName = chatSource.sourceName
            createChatSource.sourceType = chatSource.sourceType
            createChatSource.subSourceType = chatSource.subSourceType

            let body = ChatControllerByChatterIdBody(
                chatterId: userId,
                fromWhere: .profile,
                isCrypto: isCrypto,
                isPrivateMode: isPrivate,
                needShowErrorAlert: needShowErrorAlert,
                createChatSource: createChatSource
            )

            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chatId, selectionType: .skipSame)
            ]

            DispatchQueue.main.async {
                // 转换下类型，因为需要调showAlert方法
                let goToChat: (NavigatorFrom) -> Void = { (from: NavigatorFrom) in
                    self.navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url,
                                                             body: body,
                                                             context: context,
                                                             wrap: LkNavigationController.self,
                                                             from: from)
                }
                if Display.phone || !SceneManager.shared.supportsMultipleScenes {
                    goToChat(fromVC)
                } else if SceneManager.shared.supportsMultipleScenes {
                    if #available(iOS 13.0, *) {
                        /// iPad 中会优先跳转已经开启的辅助 scene
                        /// 如果是在非主 scene 打开，则在主 scene 打开
                        // scene 配置
                        let scene = LarkSceneManager.Scene(
                            key: isPrivate ? "P2pPrivateChat" : "P2pChat",
                            id: userId,
                            windowType: isPrivate ? "private_single" : "single",
                            createWay: "window_click"
                        )
                        if SceneManager.shared.connectedScene(scene: scene) != nil {
                            /// 已经存在对应 scene， 直接激活
                            SceneManager.shared.active(scene: scene, from: fromVC) { [weak fromVC] (_, error) in
                                if error != nil, let vc = fromVC {
                                    UDToast.showTips(
                                        with: BundleI18n.LarkContact.Lark_Core_SplitScreenNotSupported,
                                        on: vc.view
                                    )
                                }
                            }
                        } else {
                            /// 激活主 scene 跳转页面
                            SceneManager.shared.active(scene: Scene.mainScene(), from: fromVC) { [weak fromVC] (window, error) in
                                if let window = window {
                                    goToChat(window)
                                } else if error != nil,
                                  let vc = fromVC {
                                  UDToast.showTips(
                                      with: BundleI18n.LarkContact.Lark_Core_SplitScreenNotSupported,
                                      on: vc.view
                                  )
                                }
                            }
                        }
                    }
                }
            }

            self.peakFeedCard(userId)
        }
    }

    private func peakFeedCard(_ userId: String) {
        chatAPI?.fetchLocalP2PChat(by: userId)
            .flatMap({ [weak self] (chat) -> Observable<Void> in
                if let chatid = chat?.id {
                    return self?.feedAPI?.peakFeedCard(by: chatid, entityType: .chat) ?? Observable.empty()
                } else {
                    return .just(())
                }
            }).subscribe(onNext: {
            }).disposed(by: disposeBag)
    }
}

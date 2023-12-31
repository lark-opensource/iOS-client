//
//  AppSearchViewModel.swift
//  Lark
//
//  Created by ChalrieSu on 02/04/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import UIKit
import LarkModel
import LarkUIKit
import LarkTag
import RxSwift
import LarkCore
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import LarkAppLinkSDK
import LarkSearchCore
import LarkContainer
import LarkTab

final class AppSearchViewModel: SearchCellViewModel {
    static let logger = Logger.log(AppSearchViewModel.self, category: "Module.IM.Search")

    let disposeBag = DisposeBag()
    let router: SearchRouter

    private let chatService: ChatService
    private let currentChatterId: String
    private let context: SearchViewModelContext
    let searchResult: SearchResultType
    let enableDocCustomIcon: Bool

    let userResolver: UserResolver
    var searchClickInfo: String {
        if case let .openApp(appInfo) = searchResult.meta {
            if let ability = appInfo.appAbilities.first {
                switch ability {
                case .bot:
                    return "single_bot"
                case .h5, .microApp, .localComponent:
                    return "apps"
                case .unknown:
                    assert(false, "new value")
                    return "unknown"
                @unknown default:
                    assert(false, "new value")
                    return "unknown"
                }
            }
            if !appInfo.isAvailable {
                // 未安装应用可能不吐abilities数据，默认为应用
                return "apps"
            }
        }
        return ""
    }

    var resultTypeInfo: String {
        if case let .openApp(appInfo) = searchResult.meta {
            if let ability = appInfo.appAbilities.first {
                switch ability {
                case .bot:
                    return "app_bot"
                case .h5, .microApp, .localComponent:
                    return "apps"
                case .unknown:
                    assert(false, "new value")
                    return "unknown"
                @unknown default:
                    assert(false, "new value")
                    return "unknown"
                }
            }
            if !appInfo.isAvailable {
                // 未安装应用可能不吐abilities数据，默认为应用
                return "apps"
            }
        }
        return ""
    }

    init(userResolver: UserResolver,
         searchResult: SearchResultType,
         currentChatterId: String,
         chatService: ChatService,
         enableDocCustomIcon: Bool,
         router: SearchRouter,
         context: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.currentChatterId = currentChatterId
        self.chatService = chatService
        self.enableDocCustomIcon = enableDocCustomIcon
        self.router = router
        self.context = context
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        switch searchResult.meta {
        case .openApp(let appInfo):
            if !appInfo.isAvailable, case let appStoreURL = appInfo.appStoreURL, !appStoreURL.isEmpty {
                self.goToURL(appStoreURL, from: vc)
                return nil
            }
            var microAppURL: String?
            var h5URL: String?
            var botID: String?
            var localComponentURL: String?
            appInfo.appAbilities.forEach { (ability) in
                switch ability {
                case .microApp:
                    microAppURL = appInfo.appURL
                case .h5:
                    h5URL = appInfo.appURL
                case .bot:
                    botID = appInfo.botID
                case .localComponent:
                    localComponentURL = appInfo.appURL
                case .unknown:
                    break
                @unknown default:
                    assert(false, "new value")
                    break
                }
            }
            if let localComponentURL = localComponentURL, !localComponentURL.isEmpty {
                // Then check if can open as a localComponent
                self.goToURL(localComponentURL, from: vc)
            } else if let microAppURL = microAppURL, !microAppURL.isEmpty {
                // First check if can open as a microApp
                self.goToURL(microAppURL, from: vc)
            } else if let h5URL = h5URL, !h5URL.isEmpty {
                // Then check if can open as a H5
                self.goToURL(h5URL, from: vc)
            } else if let botID = botID, !botID.isEmpty {
                // Then check if can open as a bot
                goToBotChat(botID: botID, from: vc)
            } else {
                // Finally, show open in other platforms
                UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkSearch.Lark_Search_AppUnavailableInMobile, on: vc.view)
            }
        case .facility(let facilityInfo):
            if searchResult.isSpotlight, SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: userResolver), searchResult.type == .facility {
                let sourceKey = facilityInfo.sourceKey
                guard let tab = Tab.getTab(appType: .native, key: sourceKey) else { return nil }
                userResolver.navigator.switchTab(tab.url, from: vc)
                return nil
            }
        default:
            break
        }
        return nil
    }

    private func goToURL(_ url: String, from: UIViewController) {
        if let url = URL(string: url) {
            userResolver.navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: from)
        } else {
            UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkSearch.Lark_Search_AppUnavailableInMobile, on: from.view)
            AppSearchViewModel.logger.error("[LarkSearch] invalid url")
        }
    }

    private func goToBotChat(botID: String, from: UIViewController) {
        UDToast.showLoading(with: "", on: from.view)
        chatService.createP2PChat(userId: botID, isCrypto: false, chatSource: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak from] (chatModel) in
                guard let `self` = self, let from = from else { return }
                self.router.gotoChat(withChat: chatModel, fromVC: from)
                UDToast.removeToast(on: from.view)
            }, onError: { [weak self, weak from] (error) in
                guard self != nil, let from = from else { return }
                AppSearchViewModel.logger.error("[LarkSearch] click bot, create chat fail", additionalData: ["Bot": botID], error: error)
                UDToast.removeToast(on: from.view)
                UDToast.showFailure(
                    with: BundleI18n.LarkSearch.Lark_Legacy_ProfileDetailCreateSingleChatFailed,
                    on: from.view,
                    error: error
                )

            }, onDisposed: {[weak self, weak from] in
                guard self != nil, let from = from else { return }
                UDToast.removeToast(on: from.view)
            })
            .disposed(by: disposeBag)
    }

    func supprtPadStyle() -> Bool {
        if !UIDevice.btd_isPadDevice() {
            return false
        }
        if SearchTab.main == context.tab {
            return false
        }
        return isPadFullScreenStatus(resolver: userResolver)
    }
}

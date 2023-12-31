//
//  CustomerContactRouter.swift
//  LarkContact
//
//  Created by lichen on 2018/9/17.
//

import UIKit
import Foundation
import LarkUIKit
import LarkFoundation
import LarkContainer
import LarkModel
import RxSwift
import RxCocoa
import LKCommonsLogging
import Swinject
import EENavigator
import UniverseDesignToast
import LarkNavigator
import LarkMessengerInterface
import LarkNavigation

protocol CustomerContactRouter: AnyObject {
    func openContactApplicationViewController(_ vc: UIViewController)
    func openMyGroups(_ vc: UIViewController)
    func openChatterDetail(chatter: Chatter, _ vc: UIViewController)
    func openSearchController(vc: UIViewController)
}

final class CustomerContactRouterFactory {
    var userResolver: UserResolver
    var navigationService: NavigationService
    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.navigationService = try resolver.resolve(assert: NavigationService.self)
    }
    func create() -> CustomerContactRouter {
        let mailEnable = navigationService.checkInTabs(for: .mail)
        if Display.pad && !mailEnable {
            return CustomerContactRouterForIPad(resolver: userResolver)
        } else {
            return CustomerContactRouterImpl(resolver: userResolver)
        }
    }
}

final class CustomerContactRouterForIPad: CustomerContactRouter, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var myAIService: MyAIService?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func openContactApplicationViewController(_ vc: UIViewController) {
        navigator.showDetail(body: ContactApplicationsBody(), wrap: LkNavigationController.self, from: vc)
    }

    func openMyGroups(_ vc: UIViewController) {
        let body = GroupsViewControllerBody(title: BundleI18n.LarkContact.Lark_Legacy_MyGroup)
        navigator.showDetail(body: body, wrap: LkNavigationController.self, from: vc)
    }

    func openChatterDetail(chatter: Chatter, _ vc: UIViewController) {
        switch chatter.type {
        case .user:
            let body = PersonCardBody(chatterId: chatter.id)
            navigator.presentOrPush(body: body,
                                           wrap: LkNavigationController.self,
                                           from: vc,
                                           prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        case .bot:
            let body = ChatControllerByChatterIdBody(
                chatterId: chatter.id,
                fromWhere: .profile,
                isCrypto: false
            )

            navigator.showDetail(body: body, wrap: LkNavigationController.self, from: vc) { [weak vc] (_, res) in
                if res.error != nil, let window = vc?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_ProfileDetailCreateSingleChatFailed, on: window)
                    ContactTopStructureHandler.logger.error(
                        "创建单聊失败",
                        additionalData: ["botId": chatter.id],
                        error: res.error
                    )
                }
            }
        case .ai:
            guard let aiService = myAIService else { return }
            if !aiService.canOpenOthersAIProfile, chatter.id != aiService.info.value.id { return }
            aiService.openMyAIProfile(from: vc)
        case .unknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    func openSearchController(vc: UIViewController) {
        let body = SearchMainBody(
            scenes: [
                .rustScene(.searchChatters),
                .rustScene(.searchChats),
                .rustScene(.searchOncallScene)
            ],
            topPriorityScene: .rustScene(.searchChatters),
            sourceOfSearch: .contact
        )
        navigator.push(body: body, from: vc)
    }
}

final class CustomerContactRouterImpl: CustomerContactRouter, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var myAIService: MyAIService?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func openContactApplicationViewController(_ vc: UIViewController) {
        navigator.push(body: ContactApplicationsBody(), from: vc)
    }

    func openMyGroups(_ vc: UIViewController) {
        let body = GroupsViewControllerBody(title: BundleI18n.LarkContact.Lark_Legacy_MyGroup)
        navigator.push(body: body, from: vc)
    }

    func openChatterDetail(chatter: Chatter, _ vc: UIViewController) {
        switch chatter.type {
        case .user:
            let body = PersonCardBody(chatterId: chatter.id)
            navigator.presentOrPush(body: body,
                                           wrap: LkNavigationController.self,
                                           from: vc,
                                           prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        case .bot:
            let body = ChatControllerByChatterIdBody(
                chatterId: chatter.id,
                fromWhere: .profile,
                isCrypto: false
            )

            navigator.push(body: body, from: vc) { [weak vc] (_, res) in
                if res.error != nil, let window = vc?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_ProfileDetailCreateSingleChatFailed, on: window)
                    ContactTopStructureHandler.logger.error(
                        "创建单聊失败",
                        additionalData: ["botId": chatter.id],
                        error: res.error
                    )
                }
            }
        case .ai:
            guard let aiService = myAIService else { return }
            if !aiService.canOpenOthersAIProfile, chatter.id != aiService.info.value.id { return }
            aiService.openMyAIProfile(from: vc)
        case .unknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    func openSearchController(vc: UIViewController) {
        let body = SearchMainBody(
            scenes: [
                .rustScene(.searchChatters),
                .rustScene(.searchChats),
                .rustScene(.searchOncallScene)
            ],
            topPriorityScene: .rustScene(.searchChatters),
            sourceOfSearch: .contact
        )
        navigator.push(body: body, from: vc)
    }
}

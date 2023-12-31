//
//  GroupCardJoinHandler.swift
//  Action
//
//  Created by K3 on 2018/9/29.
//

import UIKit
import Foundation
import LarkContainer
import Swinject
import EENavigator
import LarkUIKit
import RxSwift
import LarkFoundation
import LarkRustClient
import LarkModel
import LarkAlertController
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import LarkAppLinkSDK
import LarkTab
import LarkNavigator

// 群二维码识别成非AppLink的链接
final class GroupCardQRCodeJoinByURLHandler: UserRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(req: EENavigator.Request, res: Response) throws {
        guard let token = req.url.lf.queryDictionary["share_chat_token"] else {
            res.end(error: RouterError.invalidParameters("share_chat_token"))
            return
        }
        res.redirect(body: GroupCardQRCodeJoinBody(token: token))
    }
}

struct GroupCardQRCodeJoinBody: PlainBody {
    static let pattern = "//client/chat/groupCard/qrCode/join"
    let token: String
}

// 从群二维码识别成的链接中获取到 token 加群
final class GroupCardQRCodeJoinHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private static let logger = Logger.log(GroupCardQRCodeJoinHandler.self, category: "GroupCard")
    private let disposeBag = DisposeBag()
    private lazy var chatAPI: ChatAPI? = { return try? resolver.resolve(assert: ChatAPI.self) }()

    func handle(_ body: GroupCardQRCodeJoinBody, req: EENavigator.Request, res: Response) throws {
        guard let chatAPI = chatAPI else { return }
        let token = body.token
        guard !token.isEmpty else {
            res.end(error: RouterError.invalidParameters("QRCodeJoinChatToken"))
            return
        }
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        let viewForShowingHUD = from.fromViewController?.currentWindow()

        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.sdkNetCostStart()
        if let view = viewForShowingHUD {
            UDToast.showLoading(on: view, disableUserInteraction: false)
        }

        chatAPI.getChatQRCodeInfo(token: token)
            .timeout(.seconds(8), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak viewForShowingHUD] (info) in
                GroupCardTracker.sdkNetCostEnd()
                if let view = viewForShowingHUD {
                    UDToast.removeToast(on: view)
                }
                if info.alreadyInChat {
                    let body = ChatControllerByIdBody(chatId: info.chatID)

                    var params = NaviParams()
                    params.openType = .push
                    params.switchTab = Tab.feed.url
                    res.redirect(body: body, naviParams: params)
                } else {
                    guard let self = self else { return }
                    res.end(resource: self.createGroupCard(info, token: token))
                }
            }, onError: { [weak viewForShowingHUD] error in
                let defaultMessage: String

                if let rxError = error as? RxError, case .timeout = rxError {
                    defaultMessage = BundleI18n.LarkChat.Lark_Legacy_NetworkErrorRetry
                    GroupCardTracker.trackError(errorType: .network, errorMessage: defaultMessage)
                } else {
                    defaultMessage = BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip
                    GroupCardTracker.trackError(errorType: .sdk, errorMessage: error.localizedDescription)
                }
                if let view = viewForShowingHUD {
                    UDToast.showFailure(with: defaultMessage, on: view, error: error)
                }
                Self.logger.error("Get QRCode info error.", error: error)
                res.end(error: error)
            }).disposed(by: self.disposeBag)

        res.wait()
    }

    // 创建群卡片ViewController
    private func createGroupCard(_ info: ChatQRCodeInfo, token: String) -> UIViewController {
        GroupCardTracker.initViewStart()
        defer {
            GroupCardTracker.initViewCostEnd()
        }
        guard let viewModel = try? GroupQRCodeJoinViewModel(userResolver: userResolver,
                                                            info: info,
                                                            token: token)
        else { return UIViewController() }
        let controller = GroupCardJoinViewController(userResolver: userResolver, viewModel: viewModel)
        viewModel.router.rootVCBlock = { [weak controller] in
            controller
        }
        return controller
    }
}

// 点击系统消息群名进群
final class GroupCardSystemMessageJoinHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    // private var chatAPI: ChatAPI { return try resolver.resolve(assert: ChatAPI.self) }
    // private lazy var chatterAPI: ChatterAPI = { return try resolver.resolve(assert: ChatterAPI.self) }()

    func handle(_ body: GroupCardSystemMessageJoinBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.sdkNetCostStart()

        guard let from = req.context.from() else {
            assertionFailure()
            return
        }

        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        chatAPI.fetchChats(by: [body.chatId], forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak viewForShowingHUD] (chats) in
                GroupCardTracker.sdkNetCostEnd()
                guard let self = self, let chat = chats[body.chatId] else {
                    res.end(error: RouterError.invalidParameters("chatId"))
                    GroupCardTracker.trackError(errorType: .other)
                    return
                }

                /*
                 1. 是群成员，则打开群聊
                 2. 群被解散，则提示群被解散
                 3. 进入群卡片
                 */
                if chat.role == .member {
                    let chatBody = ChatControllerByChatBody(chat: chat)
                    res.redirect(body: chatBody)
                } else if chat.isDissolved {
                    if let view = viewForShowingHUD {
                        UDToast().showTips(with: BundleI18n.LarkChat.Lark_Legacy_HasBeenDissolved, on: view)
                    }
                    res.end(resource: EmptyResource())
                } else {
                    res.end(resource: self.createGroupCard(chat))
                }
            }, onError: { (error) in
                res.end(error: error)
                GroupCardTracker.trackError(errorType: .sdk, errorMessage: error.localizedDescription)
            }).disposed(by: disposeBag)

        res.wait()
    }

    // 创建群卡片ViewController
    private func createGroupCard(_ chat: Chat) -> UIViewController {
        GroupCardTracker.initViewStart()
        defer {
            GroupCardTracker.initViewCostEnd()
        }
        guard let router = try? resolver.resolve(assert: GroupCardJoinRouter.self),
            let chatterAPI = try? resolver.resolve(assert: ChatterAPI.self)
        else { return .init() }
        let viewModel = SystemMessageJoinViewModel(
            chat: chat,
            chatterAPI: chatterAPI,
            currentChatterId: userResolver.userID,
            router: router
        )
        let controller = GroupCardJoinViewController(userResolver: userResolver, viewModel: viewModel)
        router.rootVCBlock = { [weak controller] in
            controller
        }
        return controller    }
}

final class RecommendGroupJoinHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    func handle(_ body: RecommendGroupJoinBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.sdkNetCostStart()

        guard let from = req.context.from() else {
            assertionFailure()
            return
        }

        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        chatAPI.fetchChats(by: [body.chatID], forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak viewForShowingHUD] (chats) in
                GroupCardTracker.sdkNetCostEnd()
                guard let self = self, let chat = chats[body.chatID] else {
                    res.end(error: RouterError.invalidParameters("chatId"))
                    GroupCardTracker.trackError(errorType: .other)
                    return
                }

                // 群被解散，则提示群被解散
                if chat.isDissolved {
                    if let view = viewForShowingHUD {
                        UDToast().showTips(with: BundleI18n.LarkChat.Lark_Legacy_HasBeenDissolved, on: view)
                    }
                    res.end(resource: EmptyResource())
                } else {
                    res.end(resource: self.createGroupCard(chat))
                }
            }, onError: { (error) in
                res.end(error: error)
                GroupCardTracker.trackError(errorType: .sdk, errorMessage: error.localizedDescription)
            }).disposed(by: disposeBag)

        res.wait()
    }

    // 创建群卡片ViewController
    private func createGroupCard(_ chat: Chat) -> UIViewController {
        GroupCardTracker.initViewStart()
        defer {
            GroupCardTracker.initViewCostEnd()
        }
        guard let router = try? resolver.resolve(assert: GroupCardJoinRouter.self),
            let chatterAPI = try? resolver.resolve(assert: ChatterAPI.self)
        else { return .init() }
        let viewModel = RecommendGroupJoinViewModel(chat: chat,
                                                    chatterAPI: chatterAPI,
                                                    router: router)
        let controller = GroupCardJoinViewController(userResolver: userResolver, viewModel: viewModel)
        router.rootVCBlock = { [weak controller] in
            controller
        }
        return controller
    }
}

// 群链接入群
struct GroupViaLinkJoinHandler {
    struct Link {
        static let Path = "/client/chat/chatter/add_by_link"
    }

    private static let logger = Logger.log(GroupViaLinkJoinHandler.self, category: "GroupViaLinkJoinHandler")
    private let disposeBag = DisposeBag()

    private let resolver: UserResolver
    private var chatAPI: ChatAPI? { return try? resolver.resolve(assert: ChatAPI.self) }

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(applink: AppLink) {
        guard let chatAPI = self.chatAPI else { return }
        guard let token = applink.url.lf.queryDictionary["link_token"] else { return }
        guard let from = applink.context?.from() else {
            assertionFailure()
            return
        }
        let userResolver = resolver
        if let fromQRCode = applink.url.lf.queryDictionary["qr_code"], fromQRCode == "true" {
            Self.logger.info("applink detected from qrcode")
            userResolver.navigator.push(body: GroupCardQRCodeJoinBody(token: token), from: from)
            return
        }

        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.sdkNetCostStart()
        if let view = viewForShowingHUD {
            UDToast.showLoading(on: view, disableUserInteraction: false)
        }

        chatAPI.getChatViaLinkInfo(token: token)
            .timeout(.seconds(8), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak viewForShowingHUD] (info) in
                GroupCardTracker.sdkNetCostEnd()

                if let view = viewForShowingHUD {
                    UDToast.removeToast(on: view)
                }

                if info.alreadyInChat {
                    let body = ChatControllerByIdBody(chatId: info.chatID)
                    userResolver.navigator.push(body: body, from: from)
                } else {
                    userResolver.navigator.push(self.createGroupCard(info, token: token), from: from)
                }
            }, onError: { [weak viewForShowingHUD] error in
                let defaultMessage: String

                if let rxError = error as? RxError, case .timeout = rxError {
                    defaultMessage = BundleI18n.LarkChat.Lark_Legacy_NetworkErrorRetry
                    GroupCardTracker.trackError(errorType: .network, errorMessage: defaultMessage)
                } else {
                    defaultMessage = BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip
                    GroupCardTracker.trackError(errorType: .sdk, errorMessage: error.localizedDescription)
                }
                if let view = viewForShowingHUD {
                    UDToast.showFailure(with: defaultMessage, on: view, error: error)
                }
                Self.logger.error("Get GroupViaLink info error.", error: error)
            }).disposed(by: self.disposeBag)

    }

    // 创建群卡片ViewController
    private func createGroupCard(_ info: ChatLinkInfo, token: String) -> UIViewController {
        GroupCardTracker.initViewStart()
        defer {
            GroupCardTracker.initViewCostEnd()
        }
        guard let viewModel = try? GroupViaLinkJoinViewModel(userResolver: resolver,
                                                             info: info,
                                                             token: token)
        else { return .init() }
        let controller = GroupCardJoinViewController(userResolver: resolver, viewModel: viewModel)
        viewModel.router.rootVCBlock = { [weak controller] in
            controller
        }
        return controller
    }
}

// 通过团队群进入群卡片
final class GroupCardTeamJoinHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    func handle(_ body: GroupCardTeamJoinBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.sdkNetCostStart()

        guard let from = req.context.from() else {
            assertionFailure()
            return
        }

        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        chatAPI.fetchChats(by: [body.chatId], forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak viewForShowingHUD] (chats) in
                GroupCardTracker.sdkNetCostEnd()
                guard let self = self, let chat = chats[body.chatId] else {
                    res.end(error: RouterError.invalidParameters("chatId"))
                    GroupCardTracker.trackError(errorType: .other)
                    return
                }

                /*
                 1. 是群成员，则打开群聊
                 2. 群被解散，则提示群被解散
                 3. 进入群卡片
                 */
                if chat.role == .member {
                    let chatBody = ChatControllerByChatBody(chat: chat)
                    res.redirect(body: chatBody)
                } else if chat.isDissolved {
                    if let view = viewForShowingHUD {
                        UDToast().showTips(with: BundleI18n.LarkChat.Lark_Legacy_HasBeenDissolved, on: view)
                    }
                    res.end(resource: EmptyResource())
                } else {
                    res.end(resource: self.createGroupCard(chat, teamId: body.teamId))
                }
            }, onError: { (error) in
                res.end(error: error)
                GroupCardTracker.trackError(errorType: .sdk, errorMessage: error.localizedDescription)
            }).disposed(by: disposeBag)

        res.wait()
    }

    // 创建群卡片ViewController
    private func createGroupCard(_ chat: Chat, teamId: Int64) -> UIViewController {
        GroupCardTracker.initViewStart()
        defer {
            GroupCardTracker.initViewCostEnd()
        }
        guard let router = try? resolver.resolve(assert: GroupCardJoinRouter.self),
            let chatterAPI = try? resolver.resolve(assert: ChatterAPI.self)
        else { return .init() }
        let viewModel = TeamGroupJoinViewModel(
            chatterAPI: chatterAPI,
            chat: chat,
            teamId: teamId,
            router: router)
        let controller = GroupCardJoinViewController(userResolver: userResolver, viewModel: viewModel)
        router.rootVCBlock = { [weak controller] in
            controller
        }
        return controller
    }
}

struct PreviewChatCardByLinkPageBody: PlainBody {
    static let pattern = "//client/chat/previewGroupCardByLinkPage"
    let chatID: String
    let linkPageURL: String

    init(chatID: String, linkPageURL: String) {
        self.chatID = chatID
        self.linkPageURL = linkPageURL
    }
}

final class PreviewChatCardByLinkPageHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    func handle(_ body: PreviewChatCardByLinkPageBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let router = try resolver.resolve(assert: GroupCardJoinRouter.self)
        let chatterAPI = try resolver.resolve(assert: ChatterAPI.self)
        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.sdkNetCostStart()

        guard let from = req.context.from() else {
            assertionFailure()
            res.end(error: RouterError.empty)
            return
        }
        let fromViewController = from.fromViewController

        chatAPI.fetchChats(by: [body.chatID], forceRemote: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromViewController] (chats) in
                GroupCardTracker.sdkNetCostEnd()
                guard let self = self, let chat = chats[body.chatID] else {
                    res.end(error: RouterError.invalidParameters("chatId"))
                    GroupCardTracker.trackError(errorType: .other)
                    return
                }
                GroupCardTracker.initViewStart()
                let model = GroupCardJoinModel(content: ShareGroupChatContentMeta(chat: chat),
                                               isFromSearch: false,
                                               chatAPI: chatAPI)
                let viewModel = GroupCardJoinByLinkPageViewModel(
                    fromViewController: fromViewController,
                    linkPageURL: body.linkPageURL,
                    groupShareContent: model,
                    chatterAPI: chatterAPI,
                    chatAPI: chatAPI,
                    chat: chat,
                    currentChatterId: userResolver.userID,
                    router: router,
                    joinStatusCallback: nil
                )
                let controller = GroupCardJoinViewController(userResolver: userResolver, viewModel: viewModel)
                router.rootVCBlock = { [weak controller] in
                    controller
                }
                GroupCardTracker.initViewCostEnd()
                res.end(resource: controller)
            }, onError: { (error) in
                res.end(error: error)
                GroupCardTracker.trackError(errorType: .sdk, errorMessage: error.localizedDescription)
            }).disposed(by: disposeBag)

        res.wait()
    }
}

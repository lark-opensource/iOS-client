//
//  ForwarChatMessagesPreviewHandler.swift
//  LarkChat
//
//  Created by ByteDance on 2022/9/1.
//

import Foundation
import LarkContainer
import Swinject
import LarkCore
import LarkMessageCore
import EENavigator
import LarkModel
import RxSwift
import LKCommonsLogging
import LarkMessageBase
import LarkFeatureGating
import LarkSDKInterface
import LarkMessengerInterface
import LarkSceneManager
import AsyncComponent
import UIKit
import LarkAlertController
import LarkNavigator

final class ForwarChatMessagesPreviewHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(ForwarChatMessagesPreviewHandler.self, category: "Module.ForwarChatMessagesPreviewHandler")
    let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: ForwardChatMessagePreviewBody, req: EENavigator.Request, res: Response) throws {
        let rxChat: Observable<[Chat]> = fetch(chatId: body.chatId, userId: body.userId)
        let resolver = self.userResolver
        let onError = { (error) in
            res.end(error: error)
            Self.logger.error("fail to get chat from chatid ,error: \(error)")
        }
        rxChat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chats) in
                struct EmptyChat: Error {}
                guard let chat = chats.first else {
                    onError(EmptyChat())
                    return
                }
                let chatWrapper: ChatPushWrapper
                do {
                    chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
                } catch {
                    onError(error)
                    return
                }
                let dragManager = DragInteractionManager()
                dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
                let context = MergeForwardContext(
                    resolver: resolver,
                    dragManager: dragManager,
                    defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
                )
                context.downloadFileScene = nil
                let dependency = MergeForwardMessageDetailVMDependency(userResolver: resolver)
                let viewModel = ForwardChatPreviewViewModel(
                    dependency: dependency,
                    context: context,
                    chatWrapper: chatWrapper)
                var itemsGenerator: ForwardChatPreviewBarItemsGenerator?
                var titleView: UIStackView?
                if resolver.fg.staticFeatureGatingValue(with: "core.forward.preview_potential_crash_fix") {
                    titleView = UIStackView()
                    titleView?.axis = .horizontal
                    titleView?.distribution = .fill
                    titleView?.alignment = .center
                    titleView?.spacing = 4
                    let textLabel = UILabel()
                    textLabel.font = UIFont.boldSystemFont(ofSize: 17)
                    textLabel.textColor = UIColor.ud.textTitle
                    textLabel.numberOfLines = 1
                    textLabel.textAlignment = .center
                    textLabel.text = body.title
                    titleView?.addArrangedSubview(textLabel)
                    if chat.type == .p2P {
                        let arrowIcon = UIImageView()
                        arrowIcon.image = Resources.guide_select_language_icon
                        titleView?.addArrangedSubview(arrowIcon)
                    } else {
                        itemsGenerator = ForwardChatPreviewBarItemsGenerator()
                    }
                } else {
                    if chat.type == .p2P {
                        titleView = UIStackView()
                        titleView?.axis = .horizontal
                        titleView?.distribution = .fill
                        titleView?.alignment = .center
                        titleView?.spacing = 4
                        let textLabel = UILabel()
                        textLabel.font = UIFont.boldSystemFont(ofSize: 17)
                        textLabel.textColor = UIColor.ud.textTitle
                        textLabel.numberOfLines = 1
                        textLabel.textAlignment = .center
                        textLabel.text = body.title
                        let arrowIcon = UIImageView()
                        arrowIcon.image = Resources.guide_select_language_icon
                        titleView?.addArrangedSubview(textLabel)
                        titleView?.addArrangedSubview(arrowIcon)
                    } else if chat.type == .group {
                        itemsGenerator = ForwardChatPreviewBarItemsGenerator()
                    }
                }
                let controller = ForwardChatPreviewViewController(contentTitle: body.title,
                                                                  viewModel: viewModel,
                                                                  itemsGenerator: itemsGenerator,
                                                                  titleView: titleView,
                                                                  userResolver: resolver)
                context.pageAPI = controller
                context.dataSourceAPI = viewModel
                context.chatPageAPI = controller
                context.mergeForwardType = .targetPreview
                context.showPreviewLimitTip = true
                context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
                    return ChatScreenProtectService(chat: chatWrapper.chat,
                                                    getTargetVC: { [weak context] in return context?.pageAPI },
                                                    userResolver: resolver)
                }
                res.end(resource: controller)
            }, onError: onError).disposed(by: self.disposeBag)
        res.wait()
    }

    private func fetch(chatId: String, userId: String) -> Observable<[Chat]> {
        return self.checkAndCreateChats(chatIds: [chatId], userIds: [userId])
    }

    private func checkAndCreateChats(chatIds: [String], userIds: [String]) -> Observable<[Chat]> {
        guard let chatAPI = try? resolver.resolve(assert: ChatAPI.self)
        else { return .error(UserScopeError.disposed) }

        var results: [Chat] = []
        var userIdsHasNoChat: [String] = []

        return chatAPI.fetchChats(by: chatIds, forceRemote: false)
            .do(onNext: { (chatsMap) in
                let chats = chatsMap.compactMap({ $1 })
                results.append(contentsOf: chats)
            })
            .catchErrorJustReturn([:])
            .flatMap({ _ -> Observable<[Chat]> in
                return chatAPI.fetchLocalP2PChatsByUserIds(uids: userIds)
                    .do(onNext: { (chatsDic) in
                        userIds.forEach { (userId) in
                            if let chat = chatsDic[userId] {
                                results.append(chat)
                            } else {
                                userIdsHasNoChat.append(userId)
                            }
                        }
                    })
                    .catchErrorJustReturn([:])
                    .flatMap({ _ -> Observable<[Chat]> in
                        if !userIdsHasNoChat.isEmpty {
                            return chatAPI.createP2pChats(uids: userIdsHasNoChat).map {
                                results.append(contentsOf: $0)
                                return results
                            }
                        } else {
                            return .just(results)
                        }
                    })
            })
            .observeOn(MainScheduler.instance)
    }
}

//
//  FlagListViewController+Navigation.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/20.
//

import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import RxSwift
import LarkContainer
import LarkCore
import LKCommonsLogging
import EENavigator
import LarkAlertController
import LarkMessengerInterface
import RustPB
import LarkSwipeCellKit
import LarkModel
import LarkMessageCore
import LarkSDKInterface
import LarkMessageBase

extension FlagListViewController {
    // 标记的消息类型点击需要跳转到Chat会话页面
    public func pushToChatViewController(_ flagItem: FlagItem) {
        // 保护一下
        guard let messageVM = flagItem.messageVM, let content = messageVM.content as? MessageFlagContent else {
            return
        }
        // 如果这个消息依附的会话已经不存在了需要给个兜底
        guard let chat = content.chat else {
            self.viewModel.dataDependency.chatAPI?.getKickInfo(chatId: messageVM.message.channel.id)
                .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                .asDriver(onErrorJustReturn: BundleI18n.LarkFlag.Lark_IM_YouAreNotInThisChat_Text)
                .drive(onNext: { [weak self] (content) in
                    guard let self = self else { return }
                    let alertController = LarkAlertController()
                    alertController.setContent(text: content)
                    alertController.addPrimaryButton(text: BundleI18n.LarkFlag.Lark_Legacy_IKnow,
                                                     dismissCompletion: {
                        FlagListViewController.logger.debug("get flags success")
                    })
                    self.viewModel.userResolver.navigator.present(alertController, from: self)
                }).disposed(by: self.disposeBag)
            return
        }
        // 如果被踢出群聊或者群组已解散需要路由到错误承接页面
        guard chat.role == .member && !chat.isDissolved else {
            var title = BundleI18n.LarkFlag.Lark_IM_YouAreNotInThisChat_Text
            if chat.isDissolved {
                title = BundleI18n.LarkFlag.Lark_IM_GroupDisbandedOrNoLongerInThisGroup_Toast2
            }
            self.viewModel.dataDependency.chatAPI?.getKickInfo(chatId: chat.id)
                .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                .asDriver(onErrorJustReturn: title)
                .drive(onNext: { [weak self] (content) in
                    guard let self = self else { return }
                    self.routeToMessageDetailViewController(flagItem, content)
                }).disposed(by: self.disposeBag)
            return
        }
        // 处理下密聊和非字节用户
        if chat.isCrypto, !self.viewModel.dataDependency.isByteDancer {
            SecretChatFirstCheck.showSecretChatNoticeIfNeeded(navigator: navigator, targetVC: self, cancelAction: nil) { [weak self] in
                guard let self = self else { return }
                // 路由到消息承接页
                self.routeToChatViewController(flagItem)
            }
        } else {
            // 路由到消息承接页
            routeToChatViewController(flagItem)
        }
    }

    // 路由到会话页面
    private func routeToChatViewController(_ flagItem: FlagItem) {
        guard let messageVM = flagItem.messageVM, let content = messageVM.content as? MessageFlagContent, let chat = content.chat else {
            return
        }
        let context: [String: Any] = ["kFlagSelection": flagItem]
        // 跟产品确认，标记的话题消息需要跳转到话题详情页
        if chat.chatMode == .threadV2 {
            let body = ThreadDetailByIDBody(threadId: messageVM.message.threadId, loadType: .position, position: messageVM.message.threadPosition)
            viewModel.userResolver.navigator.showDetailOrPush(body: body,
                                              context: context,
                                              wrap: LkNavigationController.self,
                                              from: self)
        } else {
            if messageVM.message.position == replyInThreadMessagePosition {
                let message = messageVM.message
                let body = ReplyInThreadByIDBody(threadId: message.threadId,
                                      loadType: .position,
                                      position: message.threadPosition)
                viewModel.userResolver.navigator.showDetailOrPush(body: body,
                                                  context: context,
                                                  wrap: LkNavigationController.self,
                                                  from: self)
                return
            }
            let body = ChatControllerByBasicInfoBody(chatId: chat.id,
                                                     positionStrategy: .position(messageVM.message.position),
                                                     messageId: messageVM.message.id,
                                                     fromWhere: .flag,
                                                     isCrypto: chat.isCrypto,
                                                     isMyAI: chat.isP2PAi,
                                                     chatMode: chat.chatMode)
            viewModel.userResolver.navigator.showDetailOrPush(body: body,
                                              context: context,
                                              wrap: LkNavigationController.self,
                                              from: self)
        }
    }

    // 路由到消息详情错误承接页面
    private func routeToMessageDetailViewController(_ flagItem: FlagItem, _ reason: String) {
        // 保护一下
        guard let messageVM = flagItem.messageVM, let content = messageVM.content as? MessageFlagContent, let chat = content.chat else {
            return
        }
        let userResolver = self.viewModel.dataDependency.getResolver
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
        let context = FlagMessageDetailContext(
            resolver: userResolver,
            dragManager: dragManager,
            defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: userResolver)
        )
        let scene: Media_V1_DownloadFileScene = .chat
        context.downloadFileScene = scene
        let dependency = FlagMessageDetailVMDependency(userResolver: self.viewModel.userResolver)
        guard let chatWrapper = try? userResolver.resolve(assert: ChatPushWrapper.self, argument: chat) else {
            return
        }
        let viewModel = FlagMessageDetailContentViewModel(
            dependency: dependency,
            context: context,
            reason: reason,
            chatWrapper: chatWrapper,
            messages: [messageVM.message])
        let detailController = FlagMessageDetailViewControlller(contentTitle: content.source, viewModel: viewModel)
        context.dataSourceAPI = viewModel
        context.flagMsgPageAPI = detailController
        context.chat = content.chat
        self.viewModel.userResolver.navigator.push(detailController, from: self)
    }
}

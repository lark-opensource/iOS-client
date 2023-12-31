//
//  UrgentTipsComponentViewModel.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/9.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import EENavigator
import LarkUIKit
import LarkCore
import LarkMessengerInterface

public protocol UrgentTipsComponentViewModelContext: ViewModelContext, ColorConfigContext {
    func isBurned(message: Message) -> Bool
    var maxCellWidth: CGFloat { get }
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func getChatThemeScene() -> ChatThemeScene
}

public final class ChatterForUrgentTip: UrgentTipChatter {
    let id: String
    let displayName: String
    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

// 管理底部加急提交的显示
public final class UrgentTipsComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: UrgentTipsComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    let urgentTipVM: UrgentTipViewModel

    /// The font of "from" text
    public var textFont: UIFont { UIFont.ud.caption1 }

    /// The size of forward icon
    public var iconSize: CGSize { .square(textFont.pointSize) }

    public var iconMarginBottom: CGFloat { 2.auto() }

    public var attributeText: NSAttributedString {
        return urgentTipVM.attributedString
    }

    public var tapableRangeList: [NSRange] {
        return urgentTipVM.tapRanges
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene, isMe: self.isMe)
    }

    private var isMe: Bool
    private var channelID: String
    private var transform: ([Chatter], Chat) -> [ChatterForUrgentTip]
    public init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>, transform: @escaping ([Chatter], Chat) -> [ChatterForUrgentTip]) {
        isMe = context.isMe(metaModel.message.fromId, chat: metaModel.getChat())
        let chat = metaModel.getChat()
        let scene = context.getChatThemeScene()
        let chatComponentTheme = ChatComponentThemeManager.getComponentTheme(scene: scene, isMe: isMe)

        self.urgentTipVM =
        UrgentTipViewModel(
            ackUrgentChatters: transform(metaModel.message.ackUrgentChatters, chat),
            ackUrgentChatterIds: metaModel.message.ackUrgentChatterIds,
            unackUrgentChatters: transform(metaModel.message.unackUrgentChatters, chat),
            unackUrgentChatterIds: metaModel.message.unackUrgentChatterIds,
            maxCellWidth: context.maxCellWidth,
            attributedStyle: UrgentTip.AttributedStyle(
                buzzReadColor: chatComponentTheme.urgentReadColor,
                buzzUnReadColor: chatComponentTheme.urgentUnReadColor,
                nameAttributes: [
                    .font: UIFont.ud.caption1,
                    .foregroundColor:
                        chatComponentTheme.urgentTipNameColor
                ],
                tipAttributes: [
                    .font: UIFont.ud.caption1,
                    .foregroundColor: chatComponentTheme.urgentTipColor
                ]
        ))
        self.channelID = chat.id
        self.transform = transform
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    /// size 发生变化, 更新 binder
    override public func onResize() {
        // 主要场景是ipad下app width的变化，需要重新计算
        urgentTipVM.resize(maxCellWidth: context.maxCellWidth)
        super.onResize()
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        let chat = metaModel.getChat()
        // 更新风格
        self.urgentTipVM.updateStyle(UrgentTip.AttributedStyle(
            buzzReadColor: chatComponentTheme.urgentReadColor,
            buzzUnReadColor: chatComponentTheme.urgentUnReadColor,
            nameAttributes: [
                .font: UIFont.ud.caption1,
                .foregroundColor:
                    chatComponentTheme.urgentTipNameColor
            ],
            tipAttributes: [
                .font: UIFont.ud.caption1,
                .foregroundColor: chatComponentTheme.urgentTipColor
            ]
        ))
        // 更新string
        self.urgentTipVM.update(ackUrgentChatterIds: metaModel.message.ackUrgentChatterIds,
                                ackUrgentChatters: transform(metaModel.message.ackUrgentChatters, chat),
                                unackUrgentChatterIds: metaModel.message.unackUrgentChatterIds,
                                unackUrgentChatters: transform(metaModel.message.unackUrgentChatters, chat),
                                maxCellWidth: context.maxCellWidth)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }
}

// MARK: - LKLabelDelegate
extension UrgentTipsComponentViewModel: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {

        for (chatterId, saveRange) in self.urgentTipVM.chatterIdToRange where saveRange == range && chatterId != "all" {
            let body = PersonCardBody(chatterId: chatterId,
                                      chatId: channelID,
                                      source: .chat)

            if Display.phone {
                context.navigator(type: .push, body: body, params: nil)
            } else {
                context.navigator(
                    type: .present,
                    body: body,
                    params: NavigatorParams(wrap: LkNavigationController.self, prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    }))
            }

            return false
        }
        if self.urgentTipVM.tipMoreRange == range {
            let body = ReadStatusBody(chatID: metaModel.getChat().id, messageID: message.id, type: .urgent)
            if Display.phone {
                context.navigator(type: .push, body: body, params: nil)
            } else {
                context.navigator(
                    type: .present,
                    body: body, params: NavigatorParams(
                        wrap: LkNavigationController.self,
                        prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                    )
                )
            }
            return false
        }
        return true
    }
}

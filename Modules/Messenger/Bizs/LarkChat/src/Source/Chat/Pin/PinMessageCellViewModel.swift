//
//  PinMessageCellViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/22.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkMessageCore
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkCore
import EENavigator
import LarkMessengerInterface
import LarkExtensions
import LKCommonsLogging
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkContainer
import LarkOpenChat

final class PinMessageCellViewModel: LarkMessageBase.PinMessageCellViewModel<PinMetaModel, PinCellMetaModelDependencyImp> {
    static let logger = Logger.log(PinMessageCellViewModel.self, category: "PinMessageCellViewModel")

    private lazy var _identifier: String = {
        return [content.identifier, "message"].joined(separator: "-")
    }()

    override var identifier: String {
        return _identifier
    }

    private lazy var currentUserId = context.userID

    /// 消息卡片转发
    private var messageCardForward: Bool {
        return self.context.getStaticFeatureGating(.messageCardForward)
    }

    override func dequeueReusableCell(_ tableView: UITableView, cellId: String) -> MessageCommonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? PinListCell ?? PinListCell(style: .default, reuseIdentifier: identifier)
        cell.update(with: renderer, cellId: cellId)
        cell.tkDescription = { [weak self] in
            self?.buildDescription() ?? [:]
        }
        cell.hightView.alpha = 0
        return cell
    }

    var chat: Chat {
        return metaModel.getChat()
    }

    var contentPreferMaxWidth: CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(message)
    }

    func getDisplayName(chatter: Chatter, chat: Chat, scene: GetChatterDisplayNameScene) -> String {
        return context.getDisplayName(chatter: chatter, chat: chat, scene: scene)
    }

    var sendTime: String {
        let createTime = message.createTime.lf.cacheFormat("pinMessage", formater: {
            $0.lf.formatedStr_v4()
        })
        return BundleI18n.LarkChat.Lark_Pin_PostAt(createTime)
    }

    func showSeperateLine() -> Bool {
        if self.message.content is FileContent
            || self.message.content is AudioContent
            || self.message.content is EventShareContent
            || self.message.content is ShareUserCardContent
            || (message.content as? LarkModel.CardContent)?.type == .vote
            || self.message.type == .vote {
            return false
        }
        return true
    }

    var config: PinCellConfig

    init(metaModel: PinMetaModel,
         context: PinContext,
         contentFactory: PinMessageSubFactory,
         getContentFactory: @escaping (PinMetaModel, PinCellMetaModelDependencyImp) -> MessageSubFactory<PinContext>,
         subFactories: [SubType: PinMessageSubFactory],
         metaModelDependency: PinCellMetaModelDependencyImp,
         cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?) {
        self.config = metaModelDependency.config
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: { contentComponent in
                return PinMessageCellComponentBinder(context: context, contentComponent: contentComponent)
            },
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
        super.calculateRenderer()
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.initialized(metaModel: self.metaModel, context: self.context)
        }
    }

    public override func buildDescription() -> [String: String] {
        return ["id": "\(message.id)",
            "cid": "\(message.cid)",
            "type": "\(message.type)",
            "channelId": "\(message.channel.id)",
            "channelType": "\(message.channel.type)"]
    }

    override func didSelect() {
        guard let vc = self.context.pageAPI else {
            assertionFailure()
            return
        }
        let navigator = context.navigator
        if message.position == replyInThreadMessagePosition {
            let body = ReplyInThreadByModelBody(message: message,
                                                chat: self.chat,
                                                loadType: .position,
                                                position: message.threadPosition,
                                                sourceType: .other)
            navigator.push(body: body, from: vc)
            return
        }

        // Thread中点击pin消息，直接进入Thread Detail
        if self.chat.chatMode == .threadV2 {
            // ThreadId 和 rootMessage.id 一致。
            let body = ThreadDetailByIDBody(threadId: message.id, loadType: .root)
            navigator.push(body: body, from: vc)
        } else {
            let body = ChatControllerByChatBody(
                chat: chat,
                position: message.position
            )
            navigator.push(body: body, from: vc)
        }
        super.didSelect()
    }

    override func willDisplay() {
        super.willDisplay()
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.willDisplay(metaModel: self.metaModel, context: self.context)
        }
    }

    override func update(metaModel: PinMetaModel, metaModelDependency: PinCellMetaModelDependencyImp? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        self.updateContent(metaModel: metaModel, metaModelDependency: metaModelDependency)
        self.calculateRenderer()
    }

    func showMenu(location: CGPoint? = nil, view: UIView = UIView()) {
        let chat = self.metaModel.getChat()
        ChatTracker.imChatPinClickMore(chat: chat)
        guard let controller = context.pageAPI else {
                return
        }
        let info = MessageMenuInfo(trigerView: view, trigerLocation: location)
        ChatTracker.imChatPinMoreView(chat: self.metaModel.getChat())
        self.context.pageContainer.resolve(PinMenuService.self)?.show(
            vc: controller,
            message: self.message,
            chat: self.metaModel.getChat(),
            info: info
        )
    }

}

final class PinMessageCellComponentBinder: ComponentBinder<PinContext> {
    private let props: PinMessageCellProps
    private let style = ASComponentStyle()
    private var _component: PinMessageCellComponent

    override var component: ComponentWithContext<PinContext> {
        return _component
    }

    init(key: String? = nil, context: PinContext? = nil, contentComponent: ComponentWithContext<PinContext>) {
        props = PinMessageCellProps(contentComponent: contentComponent)
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        _component = PinMessageCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinMessageCellViewModel else {
            assertionFailure()
            return
        }
        props.fromChatter = vm.message.fromChatter
        props.contentComponent = vm.contentComponent
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.onlyHasURLLink = vm.message.onlyHasURLLink()
        props.onlyHasDocLink = vm.message.onlyHasDocLink()
        props.showSeperateLine = vm.showSeperateLine()
        props.getDisplayName = { [unowned vm] chatter in
            return vm.getDisplayName(chatter: chatter, chat: vm.metaModel.getChat(), scene: .head)
        }
        props.sendTime = vm.sendTime
        props.subComponents = vm.getSubComponents()
        if vm.config.showFromChat {
            props.fromChat = BundleI18n.LarkChat.Lark_Pin_From("\(vm.chat.name)")
        } else {
            props.fromChat = nil
        }
        props.onFunctionButtonClicked = { [unowned vm] view in
            ChatTracker.trackPinMoreClick()
            vm.showMenu(location: CGPoint(x: view.frame.width / 2.0, y: view.frame.height / 2.0), view: view)
        }
        _component.props = props
    }
}

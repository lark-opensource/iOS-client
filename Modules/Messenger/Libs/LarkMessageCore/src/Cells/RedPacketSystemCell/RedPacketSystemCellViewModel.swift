//
//  RedPacketSystemCellViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/10.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast

open class RedPacketSystemCellViewModel<C: RedPacketSystemCellContext>: CellViewModel<C> {
    override open var identifier: String {
        return "red-packet-system"
    }

    open private(set) var metaModel: CellMetaModel
    open var message: Message {
        return metaModel.message
    }

    private var content: SystemContent {
        return (message.content as? SystemContent) ?? SystemContent.transform(pb: .init())
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    open private(set) var text: String = ""
    open private(set) var hightlightText: String = ""

    public init(metaModel: CellMetaModel, context: C) {
        self.metaModel = metaModel
        super.init(context: context, binder: RedPacketSystemCellComponentBinder(context: context))
        formatSystemText()
        self.calculateRenderer()
    }

    public func update(metaModel: CellMetaModel) {
        self.metaModel = metaModel
        formatSystemText()
        self.calculateRenderer()
    }

    private func formatSystemText() {
        self.text = String.lf.decode(
            template: content.template,
            contents: content.values
        )
        self.hightlightText = self.content.values["hongbao"] ?? BundleI18n.LarkMessageCore.Lark_Legacy_Hongbao
    }

    public func tapAction() {
        let chat = self.metaModel.getChat()
        if chat.isInMeetingTemporary {
            if let targetVC = self.context.targetVC {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_TemporaryJoinMeetingFunctionUnavailableNotice_Desc, on: targetVC.view)
            }
            return
        }
        if let messageID = self.content.values["message_id"], let redpacketId = self.content.values["hongbao_id"] {
            let body = OpenRedPacketBody(chatId: chat.id,
                                         model: .ids(mesageId: messageID, hongbaoId: redpacketId))
            context.navigator(type: .open, body: body, params: nil)
        }
    }
}

final class RedPacketSystemCellComponentBinder<C: RedPacketSystemCellContext>: ComponentBinder<C> {
    let props = RedPacketSystemCellComponent<C>.Props()
    let style = ASComponentStyle()

    lazy var _component: RedPacketSystemCellComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: RedPacketSystemCellComponent<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? RedPacketSystemCellViewModel<C> else {
            assertionFailure()
            return
        }
        props.chatComponentTheme = vm.chatComponentTheme
        props.text = vm.text
        props.highlightText = vm.hightlightText
        props.tapLinkAction = { [weak vm] in
            vm?.tapAction()
        }
        component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = RedPacketSystemCellComponent(props: props, style: style, context: context)
    }
}

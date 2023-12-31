//
//  MyAIMockSystemCellViewModel.swift
//  LarkChat
//
//  Created by ByteDance on 2023/5/22.
//

import Foundation
import LarkModel
import LarkAIInfra
import LarkMessageBase
import LarkMessengerInterface
import RustPB
import TangramService
import LarkContainer
import RichLabel
import AsyncComponent
import LarkMessageCore

public class MyAIMockSystemCellViewModel<C: PageContext>: CellViewModel<C> {
    public let config: MyAIMockSystemCellConfigType
    public var labelAttrText: NSMutableAttributedString {
        switch config {
        case .text(let text):
            return .init(string: text, attributes: [.foregroundColor: chatComponentTheme.systemTextColor,
                                                    .font: UIFont.ud.body2])
        case .attrText(let attrText):
            return .init(attributedString: attrText)
        case .textWithLine(let text):
            return .init(string: text, attributes: [.foregroundColor: chatComponentTheme.systemTextColor,
                                                    .font: UIFont.ud.body2])
        }
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    public init(context: C, config: MyAIMockSystemCellConfigType) {
        self.config = config
        switch config {
        case .text, .attrText:
            super.init(context: context, binder: MyAIMockSystemCellComponentBinder(context: context))
        case .textWithLine:
            super.init(context: context, binder: MyAIMockSystemCellWithLineComponentBinder(context: context))
        }
        self.calculateRenderer()
    }

    override public var identifier: String {
        return "MyAIMockSystemCellViewModelIdentifier"
    }
}

final class MyAIMockSystemCellComponentBinder<C: PageContext>: ComponentBinder<C> {
    let props = SystemCellComponent<C>.Props()
    let style = ASComponentStyle()

    lazy var _component: SystemCellComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MyAIMockSystemCellViewModel<C> else {
            assertionFailure()
            return
        }
        props.labelAttrText = vm.labelAttrText
        props.chatComponentTheme = vm.chatComponentTheme
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = SystemCellComponent(props: props, style: style, context: context)
    }
}

final class MyAIMockSystemCellWithLineComponentBinder<C: PageContext>: ComponentBinder<C> {
    let props = AIMockLineSystemCellComponentProps()
    let style = ASComponentStyle()

    lazy var _component: AIMockLineSystemCellComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MyAIMockSystemCellViewModel<C> else {
            assertionFailure()
            return
        }
        if case .textWithLine(let centerText) = vm.config {
            props.centerText = centerText
        } else {
            props.centerText = nil
        }
        props.chatComponentTheme = vm.chatComponentTheme
        props.textColor = vm.chatComponentTheme.systemTextColor
        props.styleColor = vm.chatComponentTheme.systemTextColor
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = AIMockLineSystemCellComponent(props: props, style: style, context: context)
    }
}

public enum MyAIMockSystemCellConfigType {
    case text(_ text: String)
    case attrText(_ attrText: NSAttributedString)
    /// 两侧有渐变线的mock系统消息
    case textWithLine(_ text: String)
}

public extension MyAIChatModeConfig.GreetingMessageType {
    func toMyAIMockSystemCellConfigType() -> MyAIMockSystemCellConfigType {
        switch self {
        case .`default`:
            return .text(BundleI18n.LarkChat.MyAI_IM_Server_StartCollab_Text)
        case .plainText(let text):
            //这个case目前方案不会走了，暂时没有提供文案，先随便写的
            return .text(BundleI18n.LarkChat.MyAI_IM_Server_StartCollab_Text + text)
        case .iconText, .url:
            //这个case目前方案不会走了，暂时没有提供文案，先随便写的
            assertionFailure("not Implemented")
            return .text(BundleI18n.LarkChat.MyAI_IM_Server_StartCollab_Text)
        }
    }
}

public extension PageContext {
    public func unfoldMyAIChatModeThread(chatModeId: Int64, threadId: String) {
        try? self.resolver.resolve(assert: MyAIChatModeMessagesManager.self, cache: true).unfoldMyAIChatModeThread(chatModeId: chatModeId, threadId: threadId)
    }
    public func foldMyAIChatModeThread(chatModeId: Int64) {
        try? self.resolver.resolve(assert: MyAIChatModeMessagesManager.self, cache: true).foldMyAIChatModeThread(chatModeId: chatModeId)
    }
    public func loadMoreMyAIChatModeThread(chatModeId: Int64, threadId: String) {
        try? self.resolver.resolve(assert: MyAIChatModeMessagesManager.self, cache: true).loadMoreMyAIChatModeThread(chatModeId: chatModeId, threadId: threadId)
    }
}

//
//  MessageEngineUnknownContentFactory.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/22.
//

import LarkModel
import AsyncComponent
import LarkMessageBase
import UniverseDesignColor

final class MessageEngineUnknownContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewMessageSubViewModel<M, D, C> {
    override var identifier: String {
        return "MessageEngineDefaultContent"
    }

    override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        return ContentConfig(hasMargin: true, selectedEnable: false,
                             threadStyleConfig: threadStyleConfig)
    }

    func getSummarize() -> String {
        // 话题转发卡片，对齐其他两端，降级为「xxx的话题」
        if let content = metaModel.message.content as? MergeForwardContent,
           content.isFromPrivateTopic,
           self.context.getStaticFeatureGating("messenger.message.new_thread_forward_card"),
           let firstMessage = content.messages.first {
            let name = content.fromChatChatters?[firstMessage.fromId]?.name ?? (content.chatters[firstMessage.fromId]?.name ?? "")
            return BundleI18n.LarkMessageCore.Lark_IM_Thread_UsernameThreadCard_Title(name)
        }
        let lynxcardRenderFG = self.context.getStaticFeatureGating("lynxcard.client.render.enable")
        return MessageSummarizeUtil.getSummarize(message: message, lynxcardRenderFG: lynxcardRenderFG)
    }
}

final class MessageEngineUnknownContentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewComponentBinder<M, D, C> {
    private var props = UILabelComponentProps()
    private var style = ASComponentStyle()
    private lazy var _component: UILabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }
    let unknownContentViewModel: MessageEngineUnknownContentViewModel<M, D, C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        unknownContentViewModel: MessageEngineUnknownContentViewModel<M, D, C>?
    ) {
        self.unknownContentViewModel = unknownContentViewModel
        super.init(key: key, context: context, viewModel: unknownContentViewModel, actionHandler: nil)
    }

    override func syncToBinder(key: String?) {
        props.text = unknownContentViewModel?.getSummarize() ?? ""
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.textColor = UIColor.ud.textTitle
        props.font = UIFont.ud.body2
        props.numberOfLines = 0
        style.backgroundColor = .clear
        self._component = UILabelComponent<C>(props: props, style: style, context: context)
    }
}

final public class MessageEngineUnknownContentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return true
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageEngineUnknownContentBinder(
            context: context,
            unknownContentViewModel: MessageEngineUnknownContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
        )
    }
}

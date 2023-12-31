//
//  ChatFeatureIntroductionCellViewModel.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/11/3.
//

import Foundation
import AsyncComponent
import LarkMessageBase

final class ChatFeatureIntroductionCellViewModel: ChatCellViewModel {
    override var identifier: String {
        return "message-featureIntroduction"
    }

    let copyWriting: String
    let hasHeader: Bool

    init(copyWriting: String, hasHeader: Bool, context: ChatContext) {
        self.copyWriting = copyWriting
        self.hasHeader = hasHeader
        super.init(
            context: context,
            binder: ChatFeatureIntroductionCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class ChatFeatureIntroductionCellComponentBinder: ComponentBinder<ChatContext> {
    private let props = ChatFeatureIntroductionCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ChatFeatureIntroductionCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: ChatContext? = nil) {
        _component = ChatFeatureIntroductionCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ChatFeatureIntroductionCellViewModel else {
            return
        }
        props.copyWriting = vm.copyWriting
        props.hasHeader = vm.hasHeader
        _component.props = props
    }
}

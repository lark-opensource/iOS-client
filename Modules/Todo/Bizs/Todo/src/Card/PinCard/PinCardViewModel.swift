//
//  PinCardViewModel.swift
//  LarkChat
//
//  Created by 白言韬 on 2020/12/14.
//

import Foundation
import LarkModel
import LarkMessageBase
import AsyncComponent
import UniverseDesignFont

 public protocol PinCardViewModelContext: ViewModelContext {
}

extension PageContext: PinCardViewModelContext { }

final class PinCardViewModel<
    M: CellMetaModel,
    D: CellMetaModelDependency,
    C: PinCardViewModelContext
>: MessageSubViewModel<M, D, C> {
    override var identifier: String {
        return "TodoPinCard"
    }

    override var contentConfig: ContentConfig? {
        var config = ContentConfig(
            hasMargin: false,
            backgroundStyle: .white,
            maskToBounds: true,
            supportMutiSelect: true
        )
        config.isCard = true
        return config
    }

    var content: TodoContent {
        return (message.content as? TodoContent) ?? .init(pbModel: .init())
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 400)
    }

    var title: String {
        if !content.pbModel.todoDetail.summary.isEmpty {
            return content.pbModel.todoDetail.summary
        } else {
            return I18N.Todo_Task_NoTitlePlaceholder
        }
    }

    var icon: UIImage {
        return Resources.Card.pin
    }

    var displayContent: [ComponentWithContext<C>] {
        let assigneeNames = content.pbModel.todoDetail.assignees.map(\.name)
        guard !assigneeNames.isEmpty else {
            return []
        }

        let props = UILabelComponentProps()
        var text = I18N.Todo_Task_AssigneesAre2
        text += assigneeNames.joined(separator: BundleI18n.Todo.Todo_Task_Comma)
        props.text = text
        props.font = UDFont.body2
        props.numberOfLines = 1
        props.textColor = UIColor.ud.textPlaceholder
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        return [UILabelComponent<C>(props: props, style: style)]
    }
}

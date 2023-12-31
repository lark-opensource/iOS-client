//
//  FlagListMessageComponentViewModel.swift
//  LarkFlag
//
//  Created by ByteDance on 2022/10/17.
//

import UIKit
import Foundation
import LarkMessageBase
import LKCommonsLogging
import LarkModel
import AsyncComponent
import EEFlexiable

class FlagListMessageMetaModel: CellMetaModel {
    let message: Message
    let chat: Chat
    var getChat: () -> Chat {
        return { self.chat }
    }

    init(message: Message, chat: Chat) {
        self.message = message
        self.chat = chat
    }
}

class FlagListMessageCellMetaModelDependencyImpl: CellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    init(contentPadding: CGFloat, contentPreferMaxWidth: @escaping (Message) -> CGFloat) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

final class FlagListMessageComponentViewModel: LarkMessageBase.MessageCellViewModel<FlagListMessageMetaModel, FlagListMessageCellMetaModelDependencyImpl, FlagListMessageContext> {
    static let logger = Logger.log(FlagListMessageComponentViewModel.self, category: "FlagListMessageComponentViewModel")

    init(metaModel: FlagListMessageMetaModel,
         context: FlagListMessageContext,
         contentFactory: FlagListMessageSubFactory,
         getContentFactory: @escaping (FlagListMessageMetaModel, FlagListMessageCellMetaModelDependencyImpl) -> MessageSubFactory<FlagListMessageContext>,
         subFactories: [SubType: FlagListMessageSubFactory],
         metaModelDependency: FlagListMessageCellMetaModelDependencyImpl) {
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: { contentComponent in
                return FlagListMessageCellBinder(context: context, contentComponent: contentComponent)
            },
            cellLifeCycleObseverRegister: nil
        )
        super.calculateRenderer()
    }

    var contentPreferMaxWidth: CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(message)
    }

    private lazy var _identifier: String = {
        return content.identifier + "_flag"
    }()

    override var identifier: String {
        return _identifier
    }

    override func dequeueReusableCell(_ tableView: UITableView, cellId: String) -> MessageCommonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MessageCommonCell ?? MessageCommonCell(style: .default, reuseIdentifier: identifier)
        cell.update(with: renderer, cellId: cellId)
        cell.tkDescription = { [weak self] in
            self?.buildDescription() ?? [:]
        }
        return cell
    }

    func renderCommonCell(cell: MessageCommonCell, cellId: String) {
        cell.update(with: renderer, cellId: cellId)
        cell.tkDescription = { [weak self] in
            self?.buildDescription() ?? [:]
        }
    }
}

// MARK: - Binder
class FlagListMessageCellBinder: ComponentBinder<FlagListMessageContext> {
    private let props: FlagListMessageCellProps
    private let style = ASComponentStyle()
    private var _component: FlagListMessageCellComponent

    override var component: ComponentWithContext<FlagListMessageContext> {
        return _component
    }

    init(key: String? = nil, context: FlagListMessageContext? = nil, contentComponent: ComponentWithContext<FlagListMessageContext>) {
        props = FlagListMessageCellProps(content: contentComponent)
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        _component = FlagListMessageCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? FlagListMessageComponentViewModel else {
            assertionFailure()
            return
        }
        props.contentComponent = vm.contentComponent
        _component.props = props
    }
}

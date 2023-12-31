//
//  RecalledContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/2.
//

import Foundation
import AsyncComponent
import RichLabel
import LarkMessageBase
import EEFlexiable
import LarkMessengerInterface
import LarkUIKit

final public class RecalledContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: RecalledContentContext>: NewComponentBinder<M, D, C> {
    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ASLayoutComponent<C> {
        return _component
    }

    private let richLabelProps = RichLabelProps()
    private lazy var contentComponent: RichLabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return RichLabelComponent(props: self.richLabelProps, style: style)
    }()

    public init(
        key: String? = nil,
        context: C? = nil,
        viewModel: RecalledContentViewModel<M, D, C>,
        actionHandler: RecalledMessageActionHandler<C>
    ) {
        super.init(key: key, context: context, viewModel: viewModel, actionHandler: actionHandler)
    }

    /// 数据绑定
    public override func syncToBinder(key: String? = nil) {
        guard let vm = self.viewModel as? RecalledContentViewModel<M, D, C>,
              let actionHandler = self.actionHandler as? RecalledMessageActionHandler<C> else {
            return
        }
        self.richLabelProps.preferMaxLayoutWidth = vm.preferMaxLayoutWidth
        self.richLabelProps.attributedText = vm.attributedString
        self.richLabelProps.tapableRangeList = [vm.atRange]
        self.richLabelProps.font = vm.labelFont
        self.richLabelProps.delegate = vm
        self.contentComponent.props = self.richLabelProps
        vm.recalledMessageActionDelegate = actionHandler
        // 需要自己设置一次maxWidth，防止绘制超出气泡
        self.contentComponent.style.maxWidth = CSSValue(cgfloat: vm.preferMaxLayoutWidth)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        // RichLabelComponent需要包一层，因为在ChatMessageCellComponent等处，会对最外层Component.style重新设置maxWidth，如果不包一层，
        // 最外层Component就是RichLabelComponent，而因为RichLabelComponent的特殊性，RichLabelComponent需要自己设置一次style.maxWidth
        // 防止渲染超出气泡，而这两处设置的值可能不相同，包一层是为了避免ChatMessageCellComponent等处修改RichLabelComponent.style
        self._component = ASLayoutComponent<C>(style: ASComponentStyle(), [self.contentComponent])
    }
}

final public class RecalledMessageActionHandler<C: ViewModelContext>: ComponentActionHandler<C>, RecalledMessageCellViewModelActionAbility {
    func openProfile(chatterID: String, messageChannelID: String) {
        let body = PersonCardBody(chatterId: chatterID,
                                  chatId: messageChannelID,
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
    }
}

//
//  ReEditComponentBinder.swift
//  LarkMessageCore
//
//  Created by bytedance on 6/23/22.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel

final class MultiEditComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MultiEditComponentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props: MultiEditStatusComponentProps
    private lazy var _component: MultiEditStatusComponent<C> = .init(props: .init(requestStatus: nil), style: .init(), context: nil)

    init(context: C, requestStatus: Message.EditMessageInfo.EditRequestStatus?) {
        props = MultiEditStatusComponentProps(requestStatus: requestStatus)
        super.init(context: context)
    }

    public override var component: MultiEditStatusComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = MultiEditStatusComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MultiEditComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.requestStatus = vm.requestStatus
        props.retryCallback = vm.retryCallBack
        _component.props = props
        style.marginTop = 4
    }
}

//
//  ChatCardCheckboxComponent.swift
//  Todo
//
//  Created by 白言韬 on 2021/5/18.
//

import AsyncComponent

// nolint: magic number
final class ChatCardCheckboxComponentProps: ASComponentProps {
    var checkState: CheckboxState = .enabled(isChecked: false)
    var enabledCheckAction: CheckboxEnabledAction?
    var disabledCheckAction: CheckboxDisabledAction?
    var isMilesone: Bool = false
}

final class ChatCardCheckboxComponent<C: Context>: ASComponent<ChatCardCheckboxComponentProps, EmptyState, Checkbox, C>, CheckboxDelegate {

    override func update(view: Checkbox) {
        super.update(view: view)
        view.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        view.delegate = self
        view.viewData = {
            var viewData = CheckBoxViewData()
            viewData.checkState = props.checkState
            viewData.isRotated = props.isMilesone
            return viewData
        }()
    }

    override var isComplex: Bool { true }

    func disabledAction(for checkbox: Checkbox) -> CheckboxDisabledAction {
        return props.disabledCheckAction ?? { }
    }

    func enabledAction(for checkbox: Checkbox) -> CheckboxEnabledAction {
        return props.enabledCheckAction ?? .immediate { }
    }

}

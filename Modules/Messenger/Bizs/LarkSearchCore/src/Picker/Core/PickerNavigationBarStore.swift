//
//  PickerNavigationBarStore.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/4/7.
//

import Foundation
import LarkModel

class PickerNavigationBarStore {
    struct State {
        struct Left {
            enum Style {
                case close
                case cancle
            }
            var style: Style = .close
        }
        struct Right {
            enum Style {
                case multi
                case sure
            }
            var style: Style = .sure
        }
        var left = Left()
        var right = Right()
    }

    var state = State()

    private var config: PickerFeatureConfig.MultiSelection
    init(featureConfig: PickerFeatureConfig) {
        self.config = featureConfig.multiSelection
        if config.isOpen {
            if config.isDefaultMulti {
                state.left.style = config.canSwitchToSingle ? .cancle : .close
                state.right.style = .sure
            } else {
                state.left.style = .close
                state.right.style = config.canSwitchToMulti ? .multi : .sure
            }
        } else {
            state.left.style = .close
            state.right.style = .sure
        }
    }

    func switchToMulti() {
        guard config.isOpen else { return }
        guard config.canSwitchToMulti else { return }
        state.left.style = config.canSwitchToSingle ? .cancle : .close
        state.right.style = .sure
    }

    func switchToSingle() {
        guard config.isOpen else { return }
        guard config.canSwitchToSingle else { return }
        state.left.style = .close
        state.right.style = .multi
    }
}

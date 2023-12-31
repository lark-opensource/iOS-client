//
//  SheetToolkitManager+FABButton.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/27.
//

import Foundation
import SKCommon
import SKBrowser
import SKResource
import UniverseDesignIcon

extension SheetToolkitManager {

    func updateKeyboardButtonIfShowToolkit(container: UIView?, show: Bool) {
        guard isShowingToolkit(), let view = container else { return }
        if show {
            attachKeyboardFAB(container: view, outsideVision: false)
        } else {
            removeKeyboardFAB()
        }
    }

    func displayKeyboardFAB(on container: UIView, show: Bool, outside: Bool) {
        if show {
            attachKeyboardFAB(container: container, outsideVision: outside)
        } else {
            removeKeyboardFAB()
        }
    }

    func attachKeyboardFAB(container: UIView, outsideVision: Bool) {
        if quickKeyboardBtn == nil || quickKeyboardBtn?.superview == nil {
            quickKeyboardBtn?.removeFromSuperview()
            let button = FloatSecondaryButton(id: .keyboard)
            button.addTarget(self, action: #selector(didPressKeyboardFAB), for: .touchUpInside)
            container.addSubview(button)
            quickKeyboardBtn = button
        }
        var rect = assistButtonHiddenRect
        if !outsideVision {
            switch currentFloatModel() {
            case .nearlyFull:
                rect = assistButtonMaxRect
            case .hidden:
                rect = assistButtonHiddenRect
            case .middle:
                rect = assistButtonDefaultRect
            }
        }
        quickKeyboardBtn?.frame = rect
    }

    func removeKeyboardFAB() {
        self.quickKeyboardBtn?.removeFromSuperview()
        self.quickKeyboardBtn = nil
    }

    @objc
    func didPressKeyboardFAB() {
        hideToolkitView()
        SheetTracker.report(event: .closeToolbox(action: 1), docsInfo: self.docsInfo)
        delegate?.didPressAccessoryKeyboard(quickKeyboardBtn, manager: self)
    }
}

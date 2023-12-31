//
// Created by maozhixiang.lip on 2022/10/27.
//

import Foundation
import UIKit
import Lynx
import UniverseDesignSwitch

class LynxSwitchElement: LynxUI<UIView> {
    private lazy var switchView = {
        let udSwitch = UDSwitch()
        udSwitch.valueChanged = { [weak self] value in
            self?.notifyValueChange(isOn: value)
        }
        return udSwitch
    }()

    static let name: String = "vc-switch"

    override var name: String { Self.name }

    override func createView() -> UIView? { switchView }

    @objc
    static func propSetterLookUp() -> [[String]] {
        [
            ["is-on", NSStringFromSelector(#selector(setIsOn(value:requestReset:)))],
            ["is-enabled", NSStringFromSelector(#selector(setIsEnabled(value:requestReset:)))]
        ]
    }

    @objc
    func setIsOn(value: NSNumber, requestReset: Bool) {
        guard self.switchView.isOn != value.boolValue else { return }
        switchView.setOn(value.boolValue, animated: false)
    }

    @objc
    func setIsEnabled(value: NSNumber, requestReset: Bool) {
        guard self.switchView.isEnabled != value.boolValue else { return }
        switchView.isEnabled = value.boolValue
    }

    func notifyValueChange(isOn: Bool) {
        let event = LynxDetailEvent(name: "ValueChange", targetSign: sign, detail: ["isOn": isOn])
        self.context?.eventEmitter?.send(event)
    }
}

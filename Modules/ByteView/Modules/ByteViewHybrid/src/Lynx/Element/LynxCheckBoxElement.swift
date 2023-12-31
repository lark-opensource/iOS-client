//
// Created by maozhixiang.lip on 2022/10/30.
//

import Foundation
import UniverseDesignCheckBox
import UIKit
import Lynx

class LynxCheckBoxElement: LynxUI<UIView> {
    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .single)
        checkBox.tapCallBack = { [weak self] _ in
            self?.onTapCheckBox()
        }
        return checkBox
    }()

    private func onTapCheckBox() {
        self.checkBox.isSelected.toggle()
        let event = LynxDetailEvent(
            name: "ValueChange",
            targetSign: sign,
            detail: ["isSelected": self.checkBox.isSelected]
        )
        self.context?.eventEmitter?.send(event)
    }

    @objc
    static func propSetterLookUp() -> [[String]] {
        [
            ["is-selected", NSStringFromSelector(#selector(setIsSelected(value:requestReset:)))],
            ["is-enabled", NSStringFromSelector(#selector(setIsEnabled(value:requestReset:)))],
            ["box-type", NSStringFromSelector(#selector(setBoxType(value:requestReset:)))],
            ["box-style", NSStringFromSelector(#selector(setBoxStyle(value:requestReset:)))]
        ]
    }

    static let name: String = "vc-checkbox"

    override var name: String { Self.name }

    override func createView() -> UIView {
        self.checkBox
    }

    @objc
    func setIsSelected(value: NSNumber, requestReset: Bool) {
        self.checkBox.isSelected = value.boolValue
    }

    @objc
    func setIsEnabled(value: NSNumber, requestReset: Bool) {
        self.checkBox.isEnabled = value.boolValue
    }

    @objc
    func setBoxType(value: String, requestReset: Bool) {
        var boxType: UDCheckBoxType = .single
        switch value {
        case "multiple": boxType = .multiple
        case "mixed": boxType = .single
        case "list": boxType = .list
        default: boxType = .single
        }
        self.checkBox.updateUIConfig(boxType: boxType, config: self.checkBox.config)
    }

    @objc
    func setBoxStyle(value: String, requestReset: Bool) {
        var config = self.checkBox.config
        config.style = value == "square" ? .square : .circle
        self.checkBox.updateUIConfig(boxType: self.checkBox.boxType, config: config)
    }
}

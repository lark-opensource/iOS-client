//
//  LynxSwitch.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/4/18.
//

import Foundation
import Lynx
import UIKit
import SnapKit
import UniverseDesignSwitch

class LynxSwitch: LynxUI<UIView> {
    private var switchIsOn = false
    // UDSwitch 竟然没暴露出来 isOn 属性？？？
    private lazy var switchView: UDSwitch = {
        let switchView = UDSwitch()
        switchView.isUserInteractionEnabled = false
        return switchView
    }()

    private lazy var disabledTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDisabledClick))
        return gesture
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleSwitchWillChange))
        return gesture
    }()

    private lazy var swipeGesture: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwitchWillChange))
        return gesture
    }()

    static let name = "ud-switch"
    override var name: String { Self.name }

    override func createView() -> UIView {
        let view = UIView()
        view.addSubview(switchView)
        switchView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addGestureRecognizer(disabledTapGesture)
        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(swipeGesture)
        return view
    }

    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["is-on", NSStringFromSelector(#selector(setIsOn(value:requestReset:)))],
            ["is-enabled", NSStringFromSelector(#selector(setIsEnabled(value:requestReset:)))]
        ]
    }

    @objc
    func setIsOn(value: NSNumber, requestReset: Bool) {
        switchIsOn = value.boolValue
        switchView.setOn(switchIsOn, animated: true, ignoreValueChanged: false)
        if switchIsOn {
            swipeGesture.direction = [.right]
        } else {
            swipeGesture.direction = [.left]
        }
    }

    @objc
    func setIsEnabled(value: NSNumber, requestReset: Bool) {
        let isOn = value.boolValue
        switchView.isEnabled = isOn
        tapGesture.isEnabled = isOn
        swipeGesture.isEnabled = isOn
        disabledTapGesture.isEnabled = !isOn
    }

    @objc
    private func handleSwitchWillChange() {
        let isOn = !switchIsOn
        let event = LynxDetailEvent(name: "valuewillchange", targetSign: sign, detail: ["isOn": isOn])
        context?.eventEmitter?.send(event)
    }

    @objc
    private func handleDisabledClick() {
        let event = LynxDetailEvent(name: "disabledclicked", targetSign: sign, detail: nil)
        context?.eventEmitter?.send(event)
    }
}

//
//  LynxRadioBox.swift
//  SKCommon
//
//  Created by majie.7 on 2022/5/10.
//

import Foundation
import Lynx
import UniverseDesignCheckBox
import UIKit

class LynxCheckBox: LynxUI<UIView> {
    private var checkBoxConfig = UDCheckBoxUIConfig(style: .circle)
    private var checkBoxType: UDCheckBoxType = .single
    
    private lazy var checkBox: UDCheckBox = {
        let view = UDCheckBox()
        view.isSelected = false
        view.isEnabled = false
        
        return view
    }()
    
    static let name = "ud-radio-box"
    override var name: String { Self.name }
    
    override func createView() -> UIView? {
        let view = UIView()
        view.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["is-checked", NSStringFromSelector(#selector(setCheckBoxCheckedStatus))],
            ["is-enabled", NSStringFromSelector(#selector(setCheckBoxEnableStatus))],
            ["clickable", NSStringFromSelector(#selector(setClickable))],
            ["type", NSStringFromSelector(#selector(setType))],
            ["style", NSStringFromSelector(#selector(setStyle))]
        ]
    }
    
    @objc
    func setCheckBoxCheckedStatus(_ value: NSNumber, requestReset: Bool) {
        let status = value.boolValue
        self.checkBox.isSelected = status
    }
    
    @objc
    func setCheckBoxEnableStatus(_ value: NSNumber, requestReset: Bool) {
        let status = value.boolValue
        self.checkBox.isEnabled = status
    }
    
    @objc
    func setClickable(_ value: NSNumber, requestReset: Bool) {
        checkBox.isUserInteractionEnabled = value.boolValue
    }
    
    @objc
    func setType(_ value: String, requestReset: Bool) {
        checkBoxType = UDCheckBoxType(id: value) ?? .single
        checkBox.updateUIConfig(boxType: checkBoxType, config: checkBoxConfig)
    }
    
    @objc
    func setStyle(_ value: String, requestReset: Bool) {
        let checkBoxStyle = UDCheckBoxUIConfig.Style(id: value) ?? .circle
        checkBoxConfig.style = checkBoxStyle
        checkBox.updateUIConfig(boxType: checkBoxType, config: checkBoxConfig)
    }
}

extension UDCheckBoxType {
    init?(id: String) {
        let mapper: [String: UDCheckBoxType] = [
            "single": .single,
            "multiple": .multiple
        ]
        guard let type = mapper[id] else {
            return nil
        }
        self = type
    }
}

extension UDCheckBoxUIConfig.Style {
    init?(id: String) {
        let mapper: [String: UDCheckBoxUIConfig.Style] = [
            "circle": .circle,
            "square": .square
        ]
        guard let type = mapper[id] else {
            return nil
        }
        self = type
    }
}

//
//  UniversalCardLynxCheckBox.swift
//  UniversalCardBase
//
//  Created by zhangjie.alonso on 2023/10/17.
//

import Foundation
import Lynx
import LKCommonsLogging
import ByteDanceKit
import UniverseDesignCheckBox
import UniverseDesignColor
import UniverseDesignShadow

public final class UniversalCardLynxCheckBox: LynxUIView {

    public static let name: String = "card-check-box"

    static let logger = Logger.oplog(UniversalCardLynxCheckBox.self, category: "UniversalCardLynxCheckBox")
    
    private enum ElementTag: String {
        case selectImg = "select_img"
        case checker = "checker"
    }
    private var tag: ElementTag? = nil
    var boxType: UDCheckBoxType?
    private var boxStyle: UDCheckBoxUIConfig.Style = .circle

    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox()
        checkBox.isEnabled = true
        return checkBox
    }()

    // 将属性和相应的设置属性函数关联
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
            ["checkBoxState", NSStringFromSelector(#selector(setState))]
        ]
    }

    @objc
    public override func createView() -> UIView? {
        return self.checkBox
    }

    @objc func setState(state: Any?, requestReset _: Bool) {
        guard let state = state as? [AnyHashable: Any] else  {
            Self.logger.error("CheckBoxState error")
            return
        }

        guard let isSelected = state["isSelected"] as? Bool else {
            Self.logger.info("CheckBox update isSelected miss value")
            return
        }
        self.checkBox.isSelected = isSelected
        
        if let isEnabled = state["isEnabled"] as? Bool {
            self.checkBox.isEnabled = isEnabled
        }
        //只有非选中态才会有错误提示态
        guard let boxType = boxType, !isSelected else {
            return
        }
        if let showRequired = state["showRequired"] as? Bool,
           showRequired {
            self.checkBox.updateUIConfig(boxType: boxType, config: boxRequireConfig())
        } else {
            self.checkBox.updateUIConfig(boxType: boxType, config: boxDefaultConfig())
        }
    }

    @objc func setProps(props: Any?, requestReset _: Bool) {
        guard let props = props as? [AnyHashable: Any] else  {
            Self.logger.error("CheckBoxProps error")
            return
        }
        if let propTag = props["tag"] as? String {
            self.tag = ElementTag(rawValue: propTag.lowercased())
        }
        if self.tag != ElementTag.checker {
            self.checkBox.layer.ud.setShadow(type: .s1Down)
        }
        if let style = props["squareShape"] as? Bool {
            self.boxStyle = style ? .square : .circle
        }
        if let isMultiSelect = props["multiSelect"] as? Bool, isMultiSelect {
            self.boxType = .multiple
            self.checkBox.updateUIConfig(boxType: .multiple, config: boxDefaultConfig())
        } else {
            self.boxType = .single
            self.checkBox.updateUIConfig(boxType: .single, config: boxDefaultConfig())
        }
        self.checkBox.isEnabled = props["actionEnable"] as? Bool ?? true
        self.checkBox.isUserInteractionEnabled = false
    }

    private func boxDefaultConfig() -> UDCheckBoxUIConfig {
        if let tag = tag, tag == ElementTag.checker {
            return UDCheckBoxUIConfig(borderEnabledColor: UIColor.ud.neutralColor7,
                                      borderDisabledColor: UIColor.ud.neutralColor6,
                                      selectedBackgroundDisableColor: UIColor.ud.fillDisabled,
                                      unselectedBackgroundDisableColor: UIColor.ud.neutralColor4,
                                      unselectedBackgroundEnabledColor: UIColor.ud.udtokenComponentOutlinedBg,
                                      style: boxStyle)
        }
        return UDCheckBoxUIConfig(borderEnabledColor: UIColor.ud.staticWhite,
                                  borderDisabledColor: UIColor(hexString:"#EFF0F1"),
                                  selectedBackgroundDisableColor: UIColor(hexString:"#BBBFC4"),
                                  unselectedBackgroundDisableColor: UIColor(hexString:"#BBBFC4"),
                                  unselectedBackgroundEnabledColor: UIColor.ud.staticBlack.withAlphaComponent(0.15),
                                  style: boxStyle)
        
    }
    
    private func boxRequireConfig() -> UDCheckBoxUIConfig {
        if let tag = tag, tag == ElementTag.checker {
            return UDCheckBoxUIConfig(borderEnabledColor: UIColor.ud.neutralColor7,
                                      borderDisabledColor: UIColor.ud.neutralColor6,
                                      selectedBackgroundDisableColor: UIColor.ud.fillDisabled,
                                      unselectedBackgroundDisableColor: UIColor.ud.neutralColor4,
                                      unselectedBackgroundEnabledColor: UIColor.ud.udtokenComponentOutlinedBg,
                                      style: boxStyle)
        }
        return UDCheckBoxUIConfig(borderEnabledColor: UDColor.getValueByBizToken(token: "function-danger-content-default") ?? .red ,
                                  selectedBackgroundDisableColor: UIColor(hexString:"#BBBFC4"),
                                  unselectedBackgroundDisableColor: UIColor(hexString:"#BBBFC4"),
                                  unselectedBackgroundEnabledColor: UIColor.ud.staticBlack.withAlphaComponent(0.15),
                                  style: boxStyle)
    }
}

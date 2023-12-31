//
//  DebugDefines.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/4/11.
//  
#if BETA || ALPHA || DEBUG
import Foundation
import SKUIKit
import UniverseDesignToast
import SKFoundation
import SKInfra

public enum WatermarkPolicy: String, CaseIterable {
    case withLark = "跟随lark"
    case forceOn
    case forceOff

    static var current: WatermarkPolicy {
        let policy: WatermarkPolicy = WatermarkPolicy(rawValue: CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.watermarkPolicy) ?? "") ?? .withLark
        return policy
    }
}

class WatermarkPickDataSource: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    let from: UIViewController
    init(from: UIViewController) {
        self.from = from
        super.init()
    }
    var onSelectAction: (() -> Void)?
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return WatermarkPolicy.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return WatermarkPolicy.allCases[row].rawValue
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let policy = WatermarkPolicy.allCases[row]
        CCMKeyValue.globalUserDefault.set(policy.rawValue, forKey: UserDefaultKeys.watermarkPolicy)
        pickerView.removeFromSuperview()
        UDToast.showSuccess(with: "水印策略: \(policy.rawValue)", on: from.view)
        onSelectAction?()
    }
}
#endif

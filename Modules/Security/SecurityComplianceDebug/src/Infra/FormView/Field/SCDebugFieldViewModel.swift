//
//  SCDebugFieldViewModel.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation
import UIKit
import EENavigator
import UniverseDesignDialog

class SCDebugFieldViewModel: Codable {
    // 需要的 cell 类型
    var cellID: String
    // 键
    var key: String?
    // 值
    var value: String?
    // 值类型约束，主要用于表单填写提示
    var valueType: ValueType
    // 是否支持在表单中删除该字段
    var isEditable: Bool = false
    // 是否必填，影响到placeHolder
    var isRequired: Bool = true
    // choiceBox 使用
    var choiceList: [String]?

    init(cellID: String, 
         key: String? = nil,
         value: String? = nil,
         valueType: ValueType = .string,
         isEditable: Bool = false,
         isRequired: Bool = true,
         choiceList: [String]? = nil) {
        self.cellID = cellID
        self.key = key
        self.value = value
        self.valueType = valueType
        self.isEditable = isEditable
        self.isRequired = isRequired
        self.choiceList = choiceList
    }
}

extension SCDebugFieldViewModel {
    enum ValueType: String, CaseIterable, Codable {
        case int
        case string
        case int64
        case bool
    }

    var realValue: Any? {
        guard let value else { return value }
        switch valueType {
        case .int:
            return Int(value)
        case .string:
            return value
        case .int64:
            return Int64(value)
        case .bool:
            return Bool(value)
        }
    }

    var placeholder: String {
        isRequired ? "必填字段": "选填字段"
    }

    func showDialogIfValueIsInvalid() {
        // 由于该方法在cell中调用，cell的初始化方法为系统调用，不方便拿resolver，使用单例获取fromVC
        guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
        guard let _ = realValue else {
            let dialog = UDDialog()
            dialog.setTitle(text: "类型不匹配")
            dialog.setContent(text: "字段输入内容类型与要求不匹配,类型应为 \(valueType)")
            dialog.addPrimaryButton(text: "OK")
            Navigator.shared.present(dialog, from: fromVC)
            return
        }
    }
}

extension Array where Element: SCDebugFieldViewModel {
    subscript(searchKey: String) -> SCDebugFieldViewModel? {
        first(where: {
            guard let key = $0.key else { return false }
            return searchKey == key
        })
    }

    subscript(safeAccess index: Int) -> SCDebugFieldViewModel? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}


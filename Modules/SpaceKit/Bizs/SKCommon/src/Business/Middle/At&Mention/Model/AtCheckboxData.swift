//
//  AtCheckboxData.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/8.
//  


import Foundation

// 选择 at 人上方出现带有 checkbox 的横条。
public struct AtCheckboxData {
    public enum CheckboxType: Int {
        case taskExcutor = 1
    }
    
    public var checkBoxType: CheckboxType
    public var text: String
    public var isSelected: Bool
    
    public init(checkBoxType: CheckboxType, text: String, isSelected: Bool) {
        self.checkBoxType = checkBoxType
        self.text = text
        self.isSelected = isSelected
    }
}

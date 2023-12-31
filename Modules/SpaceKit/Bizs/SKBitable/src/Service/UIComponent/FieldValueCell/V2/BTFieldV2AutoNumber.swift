//
//  BTFieldV2AutoNumber.swift
//  SKBitable
//
//  Created by zoujie on 2023/8/12.
//  


import Foundation
import UniverseDesignColor
struct BTFieldUIDataAutoNumber: BTFieldUIData {
    private(set) var attributedText = NSAttributedString()

    init(autoNumberValue: [BTAutoNumberModel] = []) {
        self.autoNumberValue = autoNumberValue
        updateAttributedText()
    }
    
    // MARK: - private
    
    private let autoNumberValue: [BTAutoNumberModel]
    
    private mutating func updateAttributedText() {
        let numbers = autoNumberValue.map(\.number)
        let concatenatedString = numbers.reduce("", { (partialResult, newStr) -> String in
            if partialResult.isEmpty {
                return "\(newStr)"
            } else {
                return "\(partialResult),\(newStr)"
            }
        })
        let attrs = BTFV2Const.TextAttributes.fieldValue
        let attrText = NSAttributedString(string: concatenatedString, attributes: attrs)
        attributedText = attrText
    }
}

final class BTFieldV2AutoNumber: BTFieldV2InlineReadOnly {

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        textView.editPermission = model.editable
        textView.attributedText = model.autoNumberUIData.attributedText
    }
}

//
// Created by zoujie.andy on 2022/4/24.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UniverseDesignColor

final class BTAutoNumberField: BTInlineReadOnlyTextField {

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        textView.editPermission = model.editable

        let numbers = fieldModel.autoNumberValue.map(\.number)
        let concatenatedString = numbers.reduce("", { (partialResult, newStr) -> String in
            if partialResult.isEmpty {
                return "\(newStr)"
            } else {
                return "\(partialResult),\(newStr)"
            }
        })
        let font = BTFieldLayout.Const.getFont(isPrimaryField: model.isPrimaryField)
        let textColor = model.isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        var attrs = BTUtil.getFigmaHeightAttributes(font: font, alignment: .left)
        attrs[.foregroundColor] = textColor
        let attrText = NSAttributedString(string: concatenatedString, attributes: attrs)
        textView.attributedText = attrText
    }
}

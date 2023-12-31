//
//  BTFieldV2FormulaAndLookup.swift
//  SKBitable
//
//  Created by zhysan on 2023/8/7.
//

import SKFoundation
import UniverseDesignColor
import UniverseDesignFont

struct BTFieldUIDataFormulaAndLookup: BTFieldUIData {
    struct Const {
        static let textColor = UDColor.textTitle
        static let textFont = UDFont.body0
    }
}

class BTFieldV2FormulaAndLookup: BTFieldV2BaseText {
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        textView.editPermission = false
        
        let textColor = BTFieldUIDataFormulaAndLookup.Const.textColor
        let font = BTFieldUIDataFormulaAndLookup.Const.textFont
        textView.attributedText = BTUtil.convert(model.textValue, font: font, plainTextColor: textColor, forTextView: textView)
    }
}

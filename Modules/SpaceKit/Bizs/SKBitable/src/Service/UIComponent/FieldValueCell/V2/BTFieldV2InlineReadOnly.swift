//
//  BTFieldV2InlineReadOnly.swift
//  SKBitable
//
//  Created by zoujie on 2023/8/12.
//  

import SKBrowser
import SKUIKit
import SKResource
import UniverseDesignColor

class BTFieldV2InlineReadOnly: BTFieldV2BaseText {

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        textView.editPermission = false
        let textColor = fieldModel.isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        let font = BTFieldLayout.Const.getFont(isPrimaryField: fieldModel.isPrimaryField)
        textView.attributedText = BTUtil.convert(model.textValue, font: font, plainTextColor: textColor,forTextView: textView)
        if fieldModel.isPrimaryField {
            textView.showsVerticalScrollIndicator = true
        }
    }
}

//
// Created by duanxiaochen.7 on 2021/3/15.
// Affiliated with SKBitable.
//
// Description: 该类型字段不支持在 field cell 内部进行编辑，而必须像 option 字段那样弹出新面板编辑。与 base text field 表现不同，故命名 inline read only
// 该文件只处理显示逻辑，编辑逻辑需要在子类内处理

import SKBrowser
import SKUIKit
import SKResource
import UniverseDesignColor

class BTInlineReadOnlyTextField: BTBaseTextField {

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        textView.editPermission = false
        setupStyleInStage()
        let textColor = fieldModel.isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        let font = BTFieldLayout.Const.getFont(isPrimaryField: fieldModel.isPrimaryField)
        textView.attributedText = BTUtil.convert(model.textValue, font: font, plainTextColor: textColor,forTextView: textView)
        if fieldModel.isPrimaryField {
            textView.showsVerticalScrollIndicator = true
        }
    }
}

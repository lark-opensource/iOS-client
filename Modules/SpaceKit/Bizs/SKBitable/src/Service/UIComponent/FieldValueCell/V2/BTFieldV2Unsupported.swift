//
//  BTFieldCells.swift
//  DocsSDK
//
//  Created by maxiao on 2019/12/9.
//
import SKCommon
import SKResource
import UniverseDesignColor

/// 不支持的字段类型
final class BTFieldV2Unsupported: BTFieldV2BaseText {
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        
        let str = BundleI18n.SKResource.Doc_Block_NoSupportFieldType
        var attrs = BTUtil.getFigmaHeightAttributes(font: BTFV2Const.Font.fieldValue, alignment: .left)
        attrs[.foregroundColor] = UDColor.textPlaceholder
        let attrStr = NSAttributedString(string: str, attributes: attrs)
        textView.attributedText = attrStr
        
        textView.isEditable = false
    }
}

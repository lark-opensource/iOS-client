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
final class BTUnsupportedField: BTBaseField {
    
    private lazy var contentLabel = UILabel().construct { it in
        it.font = UIFont.systemFont(ofSize: 14)
        it.textColor = UDColor.textPlaceholder
        it.text = BundleI18n.SKResource.Doc_Block_NoSupportFieldType
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        containerView.backgroundColor = UDColor.udtokenInputBgDisabled
    }
    
    override func setupLayout() {
        super.setupLayout()
        containerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { it in
            it.left.equalToSuperview().offset(BTFieldLayout.Const.containerPadding)
            it.right.equalToSuperview().offset(-BTFieldLayout.Const.containerPadding)
            it.centerY.equalToSuperview()
        }
    }
}

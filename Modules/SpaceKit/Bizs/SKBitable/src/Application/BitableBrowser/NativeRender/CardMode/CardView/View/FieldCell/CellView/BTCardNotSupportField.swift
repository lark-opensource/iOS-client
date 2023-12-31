//
//  BTCardNotSupportField.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/17.
//

import Foundation
import SKFoundation

final class BTCardNotSupportField: BTFieldBaseCell {
    
    let emptyValue = BTCardEmptyValueView()
    
    override func setupUI() {
        super.setupUI()
        valueViewWrapper.addArrangedSubview(emptyValue)
        emptyValue.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func renderValue(with model: BTCardFieldCellModel, layoutMode: BTFieldBaseCell.LayoutMode, containerWidth: CGFloat) {
        super.renderValue(with: model, layoutMode: layoutMode, containerWidth: containerWidth)
        DocsLogger.btInfo("[BTCardNotSupportField] can not render \(model.fieldUIType)")
    }
}


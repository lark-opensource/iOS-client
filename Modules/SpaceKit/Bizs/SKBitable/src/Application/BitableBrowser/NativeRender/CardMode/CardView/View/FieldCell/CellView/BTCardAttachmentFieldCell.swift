//
//  BTCardAttachmentFieldCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/2.
//

import Foundation

final class BTCardAttachmentFieldCell: BTFieldBaseCell {
    
    private lazy var valueView: BTCardAttachmentValueView = {
        let view = BTCardAttachmentValueView()
        return view
    }()
    
    override func setupUI() {
        super.setupUI()
        valueViewWrapper.addArrangedSubview(valueView)
        valueView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func renderValue(with model: BTCardFieldCellModel, layoutMode: BTFieldBaseCell.LayoutMode, containerWidth: CGFloat) {
        super.renderValue(with: model, layoutMode: layoutMode, containerWidth: containerWidth)
        valueView.setData(model, containerWidth: containerWidth)
    }
}

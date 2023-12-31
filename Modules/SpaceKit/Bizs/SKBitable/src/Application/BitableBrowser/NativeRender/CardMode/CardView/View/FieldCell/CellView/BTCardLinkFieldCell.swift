//
//  BTCardLinkFieldCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation

final class BTCardLinkFieldCell: BTFieldBaseCell {
    
    private lazy var valueView: BTCardLinkValueView = {
        let view = BTCardLinkValueView()
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

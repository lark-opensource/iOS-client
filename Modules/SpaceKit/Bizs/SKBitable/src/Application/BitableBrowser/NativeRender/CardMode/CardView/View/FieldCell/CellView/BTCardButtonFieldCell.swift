//
//  BTCardButtonFieldCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation

final class BTCardButtonFieldCell: BTFieldBaseCell {
    
    private lazy var valueView: BTCardButtonValueView = {
        let view = BTCardButtonValueView()
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

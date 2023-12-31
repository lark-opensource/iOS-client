//
//  BTCardDateFieldCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation

final class BTCardDateFieldCell: BTFieldBaseCell {
    
    private lazy var dateValueView: BTCardDateValueView = {
        let view = BTCardDateValueView()
        return view
    }()
    
    override func setupUI() {
        super.setupUI()
        valueViewWrapper.addArrangedSubview(dateValueView)
        dateValueView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func renderValue(with model: BTCardFieldCellModel, layoutMode: BTFieldBaseCell.LayoutMode, containerWidth: CGFloat) {
        super.renderValue(with: model, layoutMode: layoutMode, containerWidth: containerWidth)
        dateValueView.setData(model, containerWidth: containerWidth)
    }
    
}

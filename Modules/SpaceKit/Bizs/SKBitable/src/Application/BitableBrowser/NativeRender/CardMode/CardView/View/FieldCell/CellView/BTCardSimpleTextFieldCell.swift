//
//  BTCardSimpleTextFieldCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation

/// 对应 链接/数字/自动编号/扫码/位置/货币/电话号码/邮箱
final class BTCardSimpleTextFieldCell: BTFieldBaseCell {
    
    private lazy var valueView: BTCardSimpleTextValueView = {
        let view = BTCardSimpleTextValueView()
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

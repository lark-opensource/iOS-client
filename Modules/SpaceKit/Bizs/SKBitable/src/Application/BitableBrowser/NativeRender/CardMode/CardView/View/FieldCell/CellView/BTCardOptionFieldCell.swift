//
//  BTCardOptionFieldCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/31.
//

import Foundation
import SKBrowser

final class BTCardOptionFieldCell: BTFieldBaseCell {
    
    private lazy var capsulesView: BTSingleLineCapsuleView = {
        let view = BTSingleLineCapsuleView(with: .singleLineCapsule)
        return view
    }()
    
    override func setupUI() {
        super.setupUI()
        valueViewWrapper.addArrangedSubview(capsulesView)
        capsulesView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(BTCapsuleUIConfiguration.singleLineCapsule.lineHeight)
            make.centerY.equalToSuperview()
        }
    }
    
    override func renderValue(with model: BTCardFieldCellModel, layoutMode: BTFieldBaseCell.LayoutMode, containerWidth: CGFloat) {
        super.renderValue(with: model, layoutMode: layoutMode, containerWidth: containerWidth)
        capsulesView.setData(model, containerWidth: containerWidth)
    }
}

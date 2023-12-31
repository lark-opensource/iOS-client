//
//  BitableCatalogueGroupHeader.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/23.
//  


import UIKit

final class BTCatalogueGroupCell: BTCatalogueBaseCell {

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setClickAction(_ handler: @escaping () -> Void) {
        super.setClickAction { [weak self] in
            guard let self = self else { return }
            if let data = self.data,
               data.canExpand,
               !data.isSelected {
                // 折叠状态下，点击时，提前修改圆角
                self.update(roundCorners: .top)
            }
            handler()
        }
    }
}

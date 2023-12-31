//
//  FavoriteUnknownDetailCell.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

final class FavoriteUnknownDetailCell: FavoriteDetailCell {

    override class var identifier: String {
        return FavoriteUnknownViewModel.identifier
    }

    let unknownView = UnknownCellView(frame: .zero)

    override public func setupUI() {
        super.setupUI()

        self.contentView.addSubview(unknownView)
        unknownView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
    }
}

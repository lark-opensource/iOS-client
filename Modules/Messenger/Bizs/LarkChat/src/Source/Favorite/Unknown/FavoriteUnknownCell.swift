//
//  FavoriteUnknownCell.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

final class FavoriteUnknownCell: FavoriteListCell {
    override class var identifier: String {
        return FavoriteUnknownViewModel.identifier
    }

    let unknownView = UnknownCellView(frame: .zero)

    override public func setupUI() {
        super.setupUI()

        self.contentWraper.addSubview(unknownView)
        unknownView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
    }
}

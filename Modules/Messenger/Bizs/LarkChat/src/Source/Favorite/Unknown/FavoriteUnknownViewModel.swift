//
//  FavoriteUnknownViewModel.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

final class FavoriteUnknownViewModel: FavoriteCellViewModel {
    override class var identifier: String {
        return String(describing: FavoriteUnknownViewModel.self)
    }

    override var identifier: String {
        return FavoriteUnknownViewModel.identifier
    }
}

//
//  LarkInterface+Favorite.swift
//  LarkInterface
//
//  Created by liuwanlin on 2019/1/3.
//

import Foundation
import EENavigator

public struct FavoriteListBody: CodablePlainBody {
    public static let pattern = "//client/favorite/list"

    public init() {}
}

public struct FavoriteDetailBody: CodablePlainBody {

    public static let pattern = "//client/favorite/open_detail"

    public let favoriteId: String

    public let favoriteType: String?

    public init(favoriteId: String, favoriteType: String?) {
        self.favoriteId = favoriteId
        self.favoriteType = favoriteType
    }
}

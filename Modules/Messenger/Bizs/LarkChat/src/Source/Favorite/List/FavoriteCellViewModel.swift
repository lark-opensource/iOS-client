//
//  FavoriteCellViewModel.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import LarkModel
import LarkCore
import LarkExtensions
import RustPB
import LarkFeatureGating
import LarkContainer

public protocol FavoriteContent {
    var source: String { get }
    var detailLocation: String { get }
    var detailTime: String { get }
}

public final class UnknownFavoriteContent: FavoriteContent {
    public var source: String {
        return ""
    }
    public var detailLocation: String {
        return ""
    }
    public var detailTime: String {
        return ""
    }
}

public class FavoriteCellViewModel: NSObject, UserResolverWrapper {
    public let userResolver: UserResolver
    public class var identifier: String {
        assertionFailure("need override in subclass")
        return String(describing: FavoriteCellViewModel.self)
    }
    public var identifier: String {
        assertionFailure("need override in subclass")
        return FavoriteCellViewModel.identifier
    }

    public var favorite: RustPB.Basic_V1_FavoritesObject
    public var content: FavoriteContent
    public var dataProvider: FavoriteDataProvider

    public private(set) lazy var shortTime: String = {
        TimeInterval(self.favorite.createTime)
            .lf.cacheFormat("pin_s", formater: { $0.lf.formatedDate(onlyShowDay: false) })
    }()

    public private(set) lazy var source: String = content.source

    public var detailLocation: String {
        return content.detailLocation
    }
    public var detailTime: String {
        return content.detailTime
    }

    let shouldDetectFile: Bool

    public var isRisk: Bool {
        guard shouldDetectFile else { return false }
        if let content = content as? MessageFavoriteContent {
            return !content.message.riskObjectKeys.isEmpty
        }
        return false
    }

    public init(userResolver: UserResolver, favorite: RustPB.Basic_V1_FavoritesObject, content: FavoriteContent, dataProvider: FavoriteDataProvider) {
        self.userResolver = userResolver
        self.shouldDetectFile = userResolver.fg.staticFeatureGatingValue(with: "messenger.file.detect")
        self.favorite = favorite
        self.content = content
        self.dataProvider = dataProvider
        super.init()
    }

    public func supportDelete() -> Bool {
        return true
    }

    public func supportForward() -> Bool {
        return true
    }

    public func willDisplay() {
    }

    public func didEndDisplay() {
    }
}

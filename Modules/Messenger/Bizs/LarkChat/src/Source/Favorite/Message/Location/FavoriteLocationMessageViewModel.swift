//
//  FavoriteLocationMessageViewModel.swift
//  LarkFavorite
//
//  Created by Fangzhou Liu on 2019/6/12.
//  Copyright © 2019 Bytedance Inc. All rights reserved.
//

import Foundation
import LarkModel

final class FavoriteLocationMessageViewModel: FavoriteMessageViewModel {
    override class var identifier: String {
        return String(describing: FavoriteLocationMessageViewModel.self)
    }

    override var identifier: String {
        return FavoriteLocationMessageViewModel.identifier
    }

    var messageContent: LocationContent? {
        return self.message.content as? LocationContent
    }

    override public var needAuthority: Bool {
        return false
    }
}

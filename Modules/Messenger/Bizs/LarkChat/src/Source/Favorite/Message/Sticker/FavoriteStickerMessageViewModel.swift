//
//  FavoriteStickerMessageViewModel.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkContainer
import LarkMessengerInterface

final class FavoriteStickerMessageViewModel: FavoriteMessageViewModel {

    override class var identifier: String {
        return String(describing: FavoriteStickerMessageViewModel.self)
    }

    override var identifier: String {
        return FavoriteStickerMessageViewModel.identifier
    }

    var messageContent: StickerContent? {
        return self.message.content as? StickerContent
    }

    func showSticker(withDispatcher dispatcher: RequestDispatcher, imageView: UIImageView) {
        dispatcher.send(PreviewAssetActionMessage(
            imageView: imageView,
            source: .sticker(message),
            downloadFileScene: .favorite,
            extra: [
                FileBrowseFromWhere.FileFavoriteKey: self.favorite.id
            ])
        )
    }

    override public var needAuthority: Bool {
        return false
    }
}

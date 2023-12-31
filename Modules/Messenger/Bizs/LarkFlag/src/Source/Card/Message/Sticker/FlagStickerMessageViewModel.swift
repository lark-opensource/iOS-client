//
//  FlagStickerMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkContainer

final class FlagStickerMessageViewModel: FlagMessageCellViewModel {

    override class var identifier: String {
        return String(describing: FlagStickerMessageViewModel.self)
    }

    override var identifier: String {
        return FlagStickerMessageViewModel.identifier
    }

    var messageContent: StickerContent? {
        return self.message.content as? StickerContent
    }

    func showSticker(withDispatcher dispatcher: RequestDispatcher, imageView: UIImageView) {
        dispatcher.send(PreviewAssetActionMessage(imageView: imageView, source: .sticker(message)))
    }

    override public var needAuthority: Bool {
        return false
    }
}

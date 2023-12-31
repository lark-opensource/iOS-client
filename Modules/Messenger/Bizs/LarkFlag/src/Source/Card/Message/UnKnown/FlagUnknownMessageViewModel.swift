//
//  FlagUnknownMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel

final class FlagUnknownMessageViewModel: FlagMessageCellViewModel {
    override class var identifier: String {
        return String(describing: FlagUnknownMessageViewModel.self)
    }
    override var identifier: String {
        return FlagUnknownMessageViewModel.identifier
    }
    var messageContent: MessageContent? {
        return self.message.content
    }

    override public var needAuthority: Bool {
        return true
    }
}

//
//  FlagLocationMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel

final class FlagLocationMessageViewModel: FlagMessageCellViewModel {
    override class var identifier: String {
        return String(describing: FlagLocationMessageViewModel.self)
    }

    override var identifier: String {
        return FlagLocationMessageViewModel.identifier
    }

    var messageContent: LocationContent? {
        return self.message.content as? LocationContent
    }

    override public var needAuthority: Bool {
        return false
    }
}

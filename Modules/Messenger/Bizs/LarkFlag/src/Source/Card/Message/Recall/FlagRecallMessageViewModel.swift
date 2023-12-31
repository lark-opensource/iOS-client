//
//  FlagRecallMessageViewModel.swift
//  LarkFlag
//
//  Created by Fan Hui on 2022/5/31.
//

import Foundation
import LarkModel
import LarkContainer
import LarkCore
import RustPB
import EENavigator
import LarkMessageCore

final class FlagRecallMessageViewModel: FlagMessageCellViewModel {

    override class var identifier: String {
        return String(describing: FlagRecallMessageViewModel.self)
    }

    override var identifier: String {
        return FlagRecallMessageViewModel.identifier
    }

    override public var needAuthority: Bool {
        return false
    }
}

//
//  MenuActions.swift
//  LarkChat
//
//  Created by liuwanlin on 2018/3/21.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkContainer
import LKCommonsTracker
import LarkMessengerInterface
import LarkMessageBase

// MARK: - text
open class CopyActionMessage: Request {
    public typealias Response = EmptyResponse

    public var message: Message
    public var selectedType: CopyMessageSelectedType
    /// 选择copy类型
    public var copyType: CopyMessageType

    public init(message: Message, selectedType: CopyMessageSelectedType, copyType: CopyMessageType) {
        self.message = message
        self.selectedType = selectedType
        self.copyType = copyType
    }
}

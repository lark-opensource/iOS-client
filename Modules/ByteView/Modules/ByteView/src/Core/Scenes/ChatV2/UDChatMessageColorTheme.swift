//
//  UDChatMessageColorTheme.swift
//  ByteView
//
//  Created by bytedance on 2021/11/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignColor

extension UDColor.Name {
    static let imMessageBgBubblesBlue = UDColor.Name("imtoken-message-bg-bubbles-blue")
}

struct UDChatMessageColorTheme {
    static var imMessageBgBubblesBlue: UIColor {
        return UDColor.getValueByKey(.imMessageBgBubblesBlue) ?? UDColor.rgb(0xCCE0FF) & UDColor.primaryFillSolid03
    }
}

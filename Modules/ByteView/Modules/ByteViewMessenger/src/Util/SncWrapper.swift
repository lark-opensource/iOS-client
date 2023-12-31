//
//  SncWrapper.swift
//  ByteViewMessenger
//
//  Created by imac-pro on 2023/2/27.
//

import Foundation
import LarkEMM
import LarkSensitivityControl

final class ClipboardSncWrapper {
    @discardableResult static func set(text: String?, with token: String) -> Bool {
        do {
            let config = PasteboardConfig(token: Token(token))
            try SCPasteboard.generalUnsafe(config).string = text
            return true
        } catch {
            Logger.getLogger("Privacy", prefix: "ByteViewMessenger").warn("Cannot copy string: token \(token) is disabled.")
            return false
        }
    }
}

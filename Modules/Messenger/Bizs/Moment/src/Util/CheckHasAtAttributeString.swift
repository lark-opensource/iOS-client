//
//  CheckHasAtAttributeString.swift
//  Moment
//
//  Created by zc09v on 2021/5/27.
//

import UIKit
import Foundation
import LarkCore
import LarkBaseKeyboard

extension NSAttributedString {
    var hasAtUser: Bool {
        var result: Bool = false
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { (attributes, _, _) in
            if attributes[AtTransformer.UserIdAttributedKey] != nil {
                result = true
            }
        }
        return result
    }
}

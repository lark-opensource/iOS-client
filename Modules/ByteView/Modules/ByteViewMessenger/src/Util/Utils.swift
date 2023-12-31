//
//  Utils.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/19.
//

import Foundation
import ByteViewCommon

class Utils {

    static func formatMeetingNumber(_ meetingNumber: String) -> String {
        let s = meetingNumber
        guard s.count >= 9 else {
            return ""
        }
        let index1 = s.index(s.startIndex, offsetBy: 3)
        let index2 = s.index(s.endIndex, offsetBy: -3)
        return "\(s[..<index1]) \(s[index1..<index2]) \(s[index2..<s.endIndex])"
    }
}

extension UITraitCollection {
    var isRegular: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var isCompact: Bool {
        return !isRegular
    }
}

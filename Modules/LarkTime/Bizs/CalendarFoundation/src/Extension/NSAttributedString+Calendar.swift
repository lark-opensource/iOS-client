//
//  NSAttributedString+Calendar.swift
//  Calendar
//
//  Created by zhouyuan on 2019/5/28.
//

import UIKit
import Foundation

extension NSAttributedString: CalendarExtensionCompatible {}

extension CalendarExtension where BaseType: NSAttributedString {
    public func sizeOfString(constrainedToWidth width: CGFloat) -> CGSize {
        // swiftlint:disable:next force_cast
        return self.base
            .boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                          options: .usesLineFragmentOrigin,
                          context: nil).size
    }
}

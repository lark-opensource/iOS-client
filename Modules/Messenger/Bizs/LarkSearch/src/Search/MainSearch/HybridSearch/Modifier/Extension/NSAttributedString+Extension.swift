//
//  NSAttributedString+Extension.swift
//  TextFiledTest
//
//  Created by SuPeng on 8/7/19.
//  Copyright © 2019 SuPeng. All rights reserved.
//

import UIKit
import Foundation

extension NSAttributedString {
    var range: NSRange {
        return NSRange(location: 0, length: length)
    }
}

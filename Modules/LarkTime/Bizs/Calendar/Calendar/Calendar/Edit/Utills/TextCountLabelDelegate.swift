//
//  TextCounterDelegate.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/28/23.
//

import Foundation
import UIKit

// progress
// sample: - XX / maxLength
protocol TextCounterDelegate: AnyObject {
    var maxLength: Int { get set }
    var countLabel: UILabel { get set }

    func counterRefresh(with num: Int)
}

extension TextCounterDelegate {
    func counterRefresh(with num: Int) {
        // 根据所属区间更新显示
        let text = NSMutableAttributedString(string: "\(num)" + "/\(maxLength)")
        let splitIndex = "\(num)".count
        let currentNumColor: UIColor

        if num == 0 {
            currentNumColor = .ud.textPlaceholder
        } else if num <= maxLength {
            currentNumColor = .ud.textTitle
        } else {
            currentNumColor = .ud.functionDangerContentDefault
        }

        text.addAttributes([.foregroundColor: currentNumColor],
                           range: NSRange(location: 0, length: splitIndex + 1))
        text.addAttributes([.foregroundColor: UIColor.ud.textPlaceholder],
                           range: NSRange(location: splitIndex, length: text.length - splitIndex))
        countLabel.attributedText = text
    }
}

//
//  UIScrollView+Calendar.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/31.
//

import Foundation
import UIKit

extension UIScrollView {
    /// 是否滚动到顶部  在iPhone X / 7 上面  到insetTop = 52.5时，就算scrollView在顶部，
    /// contentOffset.y = -52.333333333
    public var isAtTop: Bool {
        return abs(contentOffset.y + contentInset.top) < 0.3
    }
}

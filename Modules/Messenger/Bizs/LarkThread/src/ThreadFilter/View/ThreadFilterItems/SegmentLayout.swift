//
//  SegmentLayout.swift
//  LarkThread
//
//  Created by bytedance on 2020/12/25.
//

import UIKit
import Foundation

enum SegmentLayout {
    static var selectedFont: UIFont { UIFont.ud.body1 }
    static var unselectedFont: UIFont { UIFont.ud.body2 }
    static var itemSpacing: CGFloat { 24 }
    static var lineHeight: CGFloat { 3 }
    static var lineWidth: CGFloat { 12.auto() }
    static var lineBottomMargin: CGFloat { 6 }
    static var lineTopMargin: CGFloat { tabsHeight - lineHeight - lineBottomMargin }
    static var redDotSize: CGFloat { 6.auto() }
    static var vMargin: CGFloat { 12 }
    static var tabsHeight: CGFloat { selectedFont.rowHeight + vMargin * 2 }
    static var tabsInset: CGFloat { 18 }
}

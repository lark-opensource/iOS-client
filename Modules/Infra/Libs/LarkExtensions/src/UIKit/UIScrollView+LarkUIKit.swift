//
//  UIScrollView+LarkUIKit.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/4/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import UIKit

public enum UIScrollViewEdge { case top, bottom }

public extension LarkUIKitExtension where BaseType: UIScrollView {
    func scrollToTop(animated: Bool) {
        self.base.setContentOffset(CGPoint(x: 0, y: -self.base.contentInset.top), animated: animated)
    }

    //// 新加的边缘相关
    func isAtBottom(gap: CGFloat = 0) -> Bool {
        return self.isScrolledToEdge(edge: .bottom, gap: gap)
    }

    //// 新加的边缘相关
    func isAtTop(gap: CGFloat = 10) -> Bool {
        return self.isScrolledToEdge(edge: .top, gap: gap)
    }

    func scrollToBottom(animated: Bool) {
        if self.isAtBottom() {
            return
        }
        self.scrollToEdge(position: .bottom, animated: animated)
    }

    func scrollToEdge(position: UIScrollViewEdge, animated: Bool) {
        let offset = verticalContentOffsetForEdge(edge: position)
        let offsetPoint = CGPoint(x: self.base.contentOffset.x, y: offset)
        self.base.setContentOffset(offsetPoint, animated: animated)
    }

    func isScrolledToEdge(edge: UIScrollViewEdge, gap: CGFloat = 0) -> Bool {
        let offset = self.base.contentOffset.y
        let offsetForEdge = verticalContentOffsetForEdge(edge: edge)
        switch edge {
        case .top: return (offset + gap) <= offsetForEdge
        case .bottom: return (offset + gap) >= offsetForEdge
        }
    }

    private func verticalContentOffsetForEdge(edge: UIScrollViewEdge) -> CGFloat {
        switch edge {
        case .top: return 0 - self.base.contentInset.top
        case .bottom: return self.base.contentSize.height + self.base.contentInset.bottom - self.base.bounds.height
        }
    }
}

//
//  UIScrollViewExtensions.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/8/13.
//

import Foundation
import ByteViewCommon

extension VCExtension where BaseType: UIScrollView {
    var bottomEdgeContentOffset: CGFloat {
        let adjustedContentInset = base.adjustedContentInset
        return max(-adjustedContentInset.top, base.contentSize.height - base.bounds.height + adjustedContentInset.bottom)
    }

    func scrollToBottom(animated: Bool = false) {
        base.setContentOffset(CGPoint(x: base.contentOffset.x, y: bottomEdgeContentOffset), animated: animated)
    }
}

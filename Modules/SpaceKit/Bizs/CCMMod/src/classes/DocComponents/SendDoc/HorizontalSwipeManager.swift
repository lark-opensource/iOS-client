//
//  HorizontalSwipeManager.swift
//  CCMMod
//
//  Created by majie.7 on 2023/3/16.
//

import Foundation

protocol HorizontalSwipeManagerDelegate {
    func swipeAction()
}

class HorizontalSwipeManager {
    // 当前支持横滑的view frame宽度
    var frameWidth: CGFloat
    var delegate: HorizontalSwipeManagerDelegate?
    
    // 能够完整展示内容的宽度
    var contentWidth: CGFloat = 0.0
    // 当前滑动偏移量
    var offset: CGFloat = 0.0
    // 已滑动
    var isSwiped: Bool {
        offset != 0.0
    }
    // 能够支持滑动
    var canSwiped: Bool {
        overFrameWidth > 0
    }
    // 滑到头了
    var isEnd: Bool {
        offset >= overFrameWidth - 16
    }
    
    var overFrameWidth: CGFloat {
        contentWidth - frameWidth
    }
    
    init(frameWidtn: CGFloat = 0.0) {
        self.frameWidth = frameWidtn
    }
    
    func updateFrameWidth(_ width: CGFloat) {
        self.frameWidth = width
    }
    
    func updateContentWidth(_ width: CGFloat) {
        if !isSwiped {
            // 未滑动，直接更新当前一屏的最大contentSize
            contentWidth = width
        } else {
            // 处于滑动中，只能更新比当前更大的width，防止缩小跳变
            if width > contentWidth {
                contentWidth = width
            }
        }
    }
    
    func updateOffset(_ offset: CGFloat) {
        if offset <= 0 {
            // 滑动偏到起始位置时，初始值为0
            self.offset = 0
        } else if offset > overFrameWidth {
            // 如果滑动偏移量大于超出屏幕的最大宽度，则表示滑动到头了，直接给最大值
            self.offset = overFrameWidth
        } else {
            self.offset = offset
        }
    }
}

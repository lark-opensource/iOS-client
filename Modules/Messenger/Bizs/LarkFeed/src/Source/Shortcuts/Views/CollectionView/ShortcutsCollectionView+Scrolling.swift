//
//  ShortcutsCollectionView+Scrolling.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

// MARK: 布局操作. 外部的scroll滑动时需要执行的
import UIKit
import Foundation
extension ShortcutsCollectionView {
    // 动态布局子view
    func snapLayout(offsetY: CGFloat, y: CGFloat) {
        // 随着didscroll，调整自身的y值，保持吸顶
        var rect = self.frame
        rect.origin.y = y
        self.frame = rect

        // loading贴着collection的底部
        var loadingViewRect = loadingView.frame
        // 始终保持在rect2贴底，且向上负height的位置开始，最多可以下拉2倍height的距离，就固定Y方向的offset
        loadingViewRect.origin.x = 0
        loadingViewRect.origin.y = self.frame.maxY - ShortcutLayout.loadingHeight + min(2 * ShortcutLayout.loadingHeight, abs(offsetY))
        loadingView.frame = loadingViewRect
        // 下拉到一定高度后，就不再继续放大效果，保持固定
        let progress = abs(offsetY) / ShortcutLayout.shortcutsLoadingExpansionTrigger
        loadingView.percentage = min(progress, 1)
        expandMoreView.setRotate(process: min(progress, 1), animationDuration: 0, shouldReverse: false)
    }

    // 静态布局子view
    func normalLayout() {
        // 三个点的效果，放在贴着collectionView的底部
        let loadingFrame = CGRect(x: 0,
                                  y: self.frame.maxY - ShortcutLayout.loadingHeight,
                                  width: self.bounds.size.width,
                                  height: ShortcutLayout.loadingHeight)
        loadingView.frame = loadingFrame
    }
}

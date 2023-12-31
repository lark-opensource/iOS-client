//
//  ReactionLayoutEngineImpl.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/9/8.
//

import UIKit
import Foundation

private func ceil_2digit(_ num: CGFloat) -> CGFloat {
    return ceil(num * 100) / 100
}
private func + (_ left: CGSize, _ right: UIEdgeInsets) -> CGSize {
    return CGSize(
        width: ceil_2digit(left.width + right.left + right.right),
        height: ceil_2digit(left.height + right.top + right.bottom)
    )
}
private func + (_ left: CGPoint, _ right: UIEdgeInsets) -> CGPoint {
    return CGPoint(x: ceil_2digit(left.x + right.left), y: ceil_2digit(left.y + right.top))
}

/// 布局引擎接口
protocol ReactionLayoutEngine {
    var preferMaxLayoutWidth: CGFloat { get set }
    var padding: UIEdgeInsets { get set }
    var semaphore: DispatchSemaphore { get }
    var subviews: [LayoutEngineItem] { get set }
    func layout(containerSize: CGSize) -> CGSize
}

/// 从上往下，从左往右顺序布局
final class ReactionLayoutEngineImpl: ReactionLayoutEngine {
    var preferMaxLayoutWidth: CGFloat = 0
    var padding: UIEdgeInsets = .zero
    var semaphore = DispatchSemaphore(value: 1)
    /// 要保证subviews是线程安全的，使用atomicSubviews封装下里面用锁保证线程安全
    private var atomicSubviews: [LayoutEngineItem] = []
    /// 使用读写锁保证容器线程安全
    private var rwLock = pthread_rwlock_t()

    /// LifeCycle
    init() {
        pthread_rwlock_init(&self.rwLock, nil)
    }
    deinit {
        pthread_rwlock_destroy(&self.rwLock)
    }

    /// 保证subviews线程安全
    var subviews: [LayoutEngineItem] {
        get {
            pthread_rwlock_rdlock(&rwLock)
            defer {
                pthread_rwlock_unlock(&rwLock)
            }
            return atomicSubviews
        }
        set {
            pthread_rwlock_wrlock(&rwLock)
            atomicSubviews = newValue
            pthread_rwlock_unlock(&rwLock)
        }
    }

    func layout(containerSize: CGSize) -> CGSize {
        if self.subviews.isEmpty { return .zero }
        /// fix containerSize
        var containerSize = containerSize
        containerSize.width = self.preferMaxLayoutWidth > 0 ? self.preferMaxLayoutWidth : CGFloat.greatestFiniteMagnitude
        containerSize.width -= (self.padding.left + self.padding.right)
        containerSize.height -= (self.padding.top + self.padding.bottom)

        /// 当前绘制行已占用的宽度
        var currRowWidth: CGFloat = 0
        /// 所有绘制行的总行高
        var allRowHeight: CGFloat = 0
        /// 所有绘制item中最大的高
        var maxItemHeight: CGFloat = 0
        /// 所有绘制行中最大的行宽
        var maxRowWidth: CGFloat = 0

        /// 每个item绘制的origin，实时计算
        var origin = CGPoint(x: 0, y: self.padding.top)

        self.semaphore.wait()
        for i in 0..<self.subviews.count {
            let subview = self.subviews[i]
            let availableMaxContentWidth = containerSize.width - subview.margin.left - subview.margin.right
            subview.featWidth(availableMaxContentWidth)
            /// 绘制该item实际需要的size，需要+margin
            /// subview.contentSize <= availableMaxContentWidth
            let currentItemSize = subview.contentSize + subview.margin
            origin.x = currRowWidth + self.padding.left
            currRowWidth += currentItemSize.width
            maxItemHeight = max(maxItemHeight, currentItemSize.height)
            /// 需要换行显示该item
            if currRowWidth > containerSize.width {
                currRowWidth -= currentItemSize.width
                maxRowWidth = max(maxRowWidth, currRowWidth)
                currRowWidth = currentItemSize.width
                allRowHeight += maxItemHeight
                origin.y += maxItemHeight
                origin.x = self.padding.left
            }
            /// 得到该item开始绘制的origin，去掉了margin
            self.subviews[i].origin = origin + subview.margin
        }
        self.semaphore.signal()

        allRowHeight += maxItemHeight
        maxRowWidth = max(maxRowWidth, currRowWidth)
        /// 需要处理padding，如：计算的宽高是(100, 100)，处理padding之后size为(94, 94)，此为我实际绘制所有内容需要的size
        return CGSize(
            width: maxRowWidth + self.padding.left + self.padding.right,
            height: allRowHeight + self.padding.top + self.padding.bottom
        )
    }
}

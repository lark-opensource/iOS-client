//
//  LKRichViewDelegate.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/9/18.
//

import UIKit
import Foundation

public protocol LKRichViewDelegate: AnyObject {
    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache)
    func getTiledCache(_ view: LKRichView) -> LKTiledCache?
    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool)
    /// LKRichView内部逻辑，触发resignFirstResponder时如果是选中态则会退出选中态，业务方可以自定义保持选中态
    /// return false：依然退出选中态，return true：保持选中态
    func keepVisualModeWhenResignFirstResponder(_ view: LKRichView) -> Bool
    func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView)
    func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView)
    func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView)
    func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView)
}

public extension LKRichViewDelegate {
    func keepVisualModeWhenResignFirstResponder(_ view: LKRichView) -> Bool { return false }
}

public enum DisplayMode {
    case async // 异步渲染
    case sync // 同步渲染
    case auto // 同步渲染，超大时分片异步渲染
}

public struct LKTiledCache {
    public struct CheckSum {
        public let userInterfaceStyle: Int
        public let isTiledCacheValid: Bool
    }
    // check sum
    public let checksum: CheckSum
    // CGImage & Frame
    public var tiledLayerInfos: [(CGImage, CGRect)] = []
    // attachment等通过subView的方式添加，需要缓存task
    public var displayTasks: [(UIView) -> Void] = []

    init(checksum: CheckSum, tiledLayerInfos: [(CGImage, CGRect)], displayTasks: [(UIView) -> Void]) {
        self.checksum = checksum
        self.tiledLayerInfos = tiledLayerInfos
        self.displayTasks = displayTasks
    }

    public init(tiledLayerInfos: [(CGImage, CGRect)], displayTasks: [(UIView) -> Void]) {
        self.checksum = CheckSum(userInterfaceStyle: 0, isTiledCacheValid: false)
        self.tiledLayerInfos = tiledLayerInfos
        self.displayTasks = displayTasks
    }
}

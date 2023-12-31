//
//  RichViewSelectionModule.swift
//  LKRichView
//
//  Created by qihongye on 2021/9/2.
//

import Foundation
import UIKit

public enum RichViewMode: UInt8 {
    case normal
    case visual
}

enum RichViewCMDMode: UInt8 {
    /// normal
    case normal
    /// Touch
    case touch
    /// Drag by pointer.
    case drag
    /// Hover by pointer.
    case hover
}

/// 1、构建selection layer，中间的选中区域
/// 2、更新开始/结束的大头针frame
/// 3、更新放大镜frame
public struct SelectionModule {
    private var mode: RichViewMode = .normal
    /// iPad touch、拖拽、hover事件
    private var cmdMode: RichViewCMDMode = .normal
    private var canPerformOtherEvent: Bool = false
    private var isSuperResponseEvent: Bool = false
    public private(set) var selectedRects: [CGRect] = []
    private var writingMode: WritingMode = .horizontalTB
    private var selectionLayer: CAShapeLayer?

    /// 如果activeCursor为null，说明LKRichView当前：1、不处于选中状态，2、处于选中状态但用户没选中开始/结束光标移动
    var activeCursor: Cursor?

    let startCursor: Cursor
    let endCursor: Cursor

    init(startCursor: Cursor, endCursor: Cursor) {
        self.startCursor = startCursor
        self.endCursor = endCursor
    }

    func maybeInVisualMode() -> Bool {
        return self.mode == .visual || self.cmdMode == .hover
    }

    func visualModeChecking() -> Bool {
        return self.mode != .visual && self.cmdMode == .hover
    }

    func getCMDMode() -> RichViewCMDMode {
        return cmdMode
    }

    public func getMode() -> RichViewMode {
        return mode
    }

    /// 进入/退出选中状态
    mutating func enter(mode: RichViewMode) {
        self.mode = mode
        if mode != .visual {
            selectedRects = []
            activeCursor = nil
            selectionLayer?.removeFromSuperlayer()
            selectionLayer = nil
        }
    }

    /// Is `super.hitTest` return non-null value.
    mutating func performOtherEvent(_ hitTested: Bool) {
        self.canPerformOtherEvent = hitTested
    }

    mutating func hitTest(with event: UIEvent?) {
        if let event = event {
            if isEventHover(event) {
                cmdMode = .hover
            } else if isEventTouch(event) {
                cmdMode = .touch
            }
            return
        }
        cmdMode = .normal
    }

    func getSelectionLayer() -> CAShapeLayer? {
        return selectionLayer
    }

    /// 根据activeCursor.rect更新放大镜位置
    func updateTextMagnifier(_ magnifier: Magnifier, richView: LKRichView) {
        guard let activeCursor = activeCursor else {
            return
        }
        let offset: CGFloat = 3
//        if #available(iOS 15, *), magnifier is TextMagnifierForIOS15 {
//            offset = -5
//        } else {
//            offset = 3
//        }
        switch activeCursor.type {
        case .start:
            magnifier.sourceScanCenter = CGPoint(
                x: activeCursor.rect.minX,
                y: activeCursor.rect.minY + activeCursor.rect.height / 2
            )
            magnifier.magnifierView.center = richView.convert(
                CGPoint(
                    x: activeCursor.rect.minX,
                    y: activeCursor.rect.maxY
                        - activeCursor.renderLayer.frame.height
                        - magnifier.magnifierView.frame.height / 2 + offset),
                // nil：相对于UIWindow
                to: nil
            )
        case .end:
            magnifier.sourceScanCenter = CGPoint(
                x: activeCursor.rect.maxX,
                y: activeCursor.rect.minY + activeCursor.rect.height / 2
            )
            magnifier.magnifierView.center = richView.convert(
                CGPoint(
                    x: activeCursor.rect.maxX,
                    y: activeCursor.rect.maxY
                        - activeCursor.renderLayer.frame.height
                        - magnifier.magnifierView.frame.height / 2 + offset),
                // nil：相对于UIWindow
                to: nil
            )
        }
        magnifier.updateRenderer()
    }

    // 在 UIKit 坐标系下
    mutating func exchangeActiveCursor() {
        guard let activeCursor = self.activeCursor else {
            return
        }
        switch activeCursor.type {
        case .start:
            startCursor.rect.origin = endCursor.rect.origin
            startCursor.rect.size.height = endCursor.rect.size.height
            startCursor.location.point = endCursor.location.point
            self.activeCursor = endCursor
        case .end:
            endCursor.rect.origin = startCursor.rect.origin
            endCursor.rect.size.height = startCursor.rect.size.height
            endCursor.location.point = startCursor.location.point
            self.activeCursor = startCursor
        }
    }

    func updateActiveCursour(point: CGPoint) {
        guard let activeCursor = activeCursor,
              let startRect = selectedRects.first,
              let endRect = selectedRects.last else {
            return
        }
        switch activeCursor.type {
        case .start:
            activeCursor.rect.origin = CGPoint(
                x: startRect.minX - activeCursor.rect.width / 2, y: startRect.minY
            )
            activeCursor.rect.size.height = startRect.height
            activeCursor.location.point = CGPoint(x: activeCursor.rect.x, y: point.y)
            endCursor.rect.origin = CGPoint(x: endRect.maxX, y: endRect.y)
            endCursor.rect.size.height = endRect.height
        case .end:
            activeCursor.rect.origin = CGPoint(
                x: endRect.maxX - activeCursor.rect.width / 2, y: endRect.minY
            )
            activeCursor.rect.size.height = endRect.height
            activeCursor.location.point = CGPoint(x: activeCursor.rect.x, y: point.y)
            startCursor.rect.origin = CGPoint(x: startRect.x, y: startRect.y)
            startCursor.rect.size.height = startRect.height
        }
    }

    /// TODO: @qhy, WritingMode适配
    mutating func setSelectedRects(_ rects: [CGRect], writingMode: WritingMode) {
        self.writingMode = writingMode
        /// Only deal with `horizontalTB` writingMode.

        selectedRects = rects
    }

    mutating func renderSelectionFromStartToEnd(selectionColor: UIColor) {
        let selectionLayer = self.selectionLayer ?? CAShapeLayer()
        selectionLayer.fillColor = selectionColor.cgColor
        let path = CGMutablePath()
        selectedRects.forEach { path.addPath(CGPath(rect: $0, transform: nil)) }
        selectionLayer.path = path
        self.selectionLayer = selectionLayer
    }
}

/// Check UIEvent is pointer hover
/// Notice: This is for iPad.
/// - Returns: return result
@inline(__always)
func isEventHover(_ event: UIEvent) -> Bool {
    if #available(iOS 13.4, *) {
        return event.type == .hover
    } else {
        return false
    }
}

/// Check UIEvent is pointer touch
/// Notice: This is for iPad.
/// - Returns: return result
@inline(__always)
func isEventTouch(_ event: UIEvent) -> Bool {
    if #available(iOS 13.4, *) {
        return event.type == .touches && event.buttonMask.rawValue != 0
    } else {
        return false
    }
}

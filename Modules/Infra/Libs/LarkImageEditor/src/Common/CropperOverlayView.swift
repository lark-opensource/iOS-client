//
//  CropperOverlayView.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/5.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

protocol CropperOverlayViewDelegate: AnyObject {
    func cropperOverlayViewBeginDragging(_ view: CropperOverlayView)
    func cropperOverlayViewDragging(_ view: CropperOverlayView, frame: CGRect)
    func cropperOverlayViewEndDragging(_ view: CropperOverlayView, frame: CGRect)
}

final class CropperOverlayView: UIView {
    private enum DragType {
        case dragInFree
        case dragInRatio(ratio: CGFloat)
    }
    private var dragType: DragType = .dragInFree

    weak var delegate: CropperOverlayViewDelegate?

    let hollow: CropperHollowView
    private var config: CropperConfigure

    var isDragging: Bool = false

    private var squareScale: Bool {
        return config.squareScale
    }

    private var minCropSize: CGSize {
        return config.minCropSize
    }

    private let insets: UIEdgeInsets

    var isEnabled: Bool = true {
        didSet {
            panGesture.isEnabled = isEnabled
        }
    }

    private var panGesture: UIPanGestureRecognizer!

    private var startRect: CGRect = .zero

    private var activeCropAreaPart: CropAreaPart = .none

    init(frame: CGRect, hollowFrame: CGRect, insets: UIEdgeInsets, config: CropperConfigure = .default) {
        self.config = config
        self.insets = insets

        hollow = CropperHollowView(frame: frame)
        hollow.update(rect: hollowFrame)

        super.init(frame: frame)

        addSubview(hollow)
        hollow.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        self.addGestureRecognizer(panGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.point(inside: point, with: event) && getCropAreaPart(point: point) != .none ? self : nil
    }

    @objc
    private func didPan(_ panGes: UIPanGestureRecognizer) {
        let point = panGes.location(in: self)
        switch panGes.state {
        case .began:
            activeCropAreaPart = getCropAreaPart(point: point)
            startRect = hollow.rect
            if activeCropAreaPart != .none {
                delegate?.cropperOverlayViewBeginDragging(self)
                isDragging = true
            }
        case .changed:
            let translation = panGes.translation(in: self)
            let rect: CGRect
            switch dragType {
            case .dragInFree:
                rect = squareScale ?
                    sizeForSquare(startRect: startRect, translation: translation) :
                    sizeForRect(startRect: startRect, translation: translation)
            case .dragInRatio(let ratio):
                rect = sizeForRectWithRatio(ratio, startRect: startRect, translation: translation)
            }
            delegate?.cropperOverlayViewDragging(self, frame: rect)
            hollow.update(rect: rect)
        case .cancelled, .ended:
            if activeCropAreaPart != .none {
                delegate?.cropperOverlayViewEndDragging(self, frame: hollow.rect)
                isDragging = false
            }
            activeCropAreaPart = .none
        default: break
        }
    }

    func upateMask(isShow: Bool) {
        let color = isShow ? UIColor.ud.staticBlack.withAlphaComponent(0.5) : UIColor.clear
        hollow.fillColor = color
    }

    private func sizeForSquare(startRect: CGRect, translation: CGPoint) -> CGRect {
        var rect = startRect

        var delta: CGFloat = 0
        if activeCropAreaPart == .topEdge {
            delta = caculateDeltaForSquare(-translation.y)
            rect.origin.y -= delta
            rect.origin.x -= delta / 2
        } else if activeCropAreaPart == .bottomEdge {
            delta = caculateDeltaForSquare(translation.y)
            rect.origin.x -= delta / 2
        } else if activeCropAreaPart == .leftEdge {
            delta = caculateDeltaForSquare(-translation.x)
            rect.origin.x -= delta
            rect.origin.y -= delta / 2
        } else if activeCropAreaPart == .rightEdge {
            delta = caculateDeltaForSquare(translation.x)
            rect.origin.y -= delta / 2
        } else if activeCropAreaPart == .topLeftCorner {
            delta = caculateDeltaForSquare((-translation.x - translation.y) / 2)
            rect.origin.x -= delta
            rect.origin.y -= delta
        } else if activeCropAreaPart == .topRightCorner {
            delta = caculateDeltaForSquare((translation.x - translation.y) / 2)
            rect.origin.y -= delta
        } else if activeCropAreaPart == .bottomLeftCorner {
            delta = caculateDeltaForSquare((-translation.x + translation.y) / 2)
            rect.origin.x -= delta
        } else if activeCropAreaPart == .bottomRightCorner {
            delta = caculateDeltaForSquare((translation.x + translation.y) / 2)
        }
        rect.size.width += delta
        rect.size.height += delta

        return rect
    }

    private func caculateDeltaForSquare(_ delta: CGFloat) -> CGFloat {
        let range = deltaRangeForSquare()
        if delta < range.lowerBound {
            return range.lowerBound
        }
        if delta > range.upperBound {
            return range.upperBound
        }
        return delta
    }

    private func deltaRangeForSquare() -> ClosedRange<CGFloat> {
        let minSize = minCropSize.width

        let expand2 = startRect.width - minSize
        var expand1: CGFloat = 0
        if activeCropAreaPart == .topEdge {
            expand1 = min(
                (startRect.minX - insets.left) * 2,
                (self.bounds.width - insets.right - startRect.maxX) * 2,
                startRect.minY - insets.top
            )
        } else if activeCropAreaPart == .bottomEdge {
            expand1 = min(
                (startRect.minX - insets.left) * 2,
                (self.bounds.width - insets.right - startRect.maxX) * 2,
                self.bounds.height - insets.bottom - startRect.maxY
            )
        } else if activeCropAreaPart == .leftEdge {
            expand1 = min(
                startRect.minX - insets.left,
                (startRect.minY - insets.top) * 2,
                (self.bounds.height - insets.bottom - startRect.maxY) * 2
            )
        } else if activeCropAreaPart == .rightEdge {
            expand1 = min(
                self.bounds.width - insets.right - startRect.maxX,
                (startRect.minY - insets.top) * 2,
                (self.bounds.height - insets.bottom - startRect.maxY) * 2
            )
        } else if activeCropAreaPart == .topLeftCorner {
            expand1 = min(
                startRect.minX - insets.left,
                startRect.minY - insets.top
            )
        } else if activeCropAreaPart == .topRightCorner {
            expand1 = min(
                self.bounds.width - insets.right - startRect.maxX,
                startRect.minY - insets.top
            )
        } else if activeCropAreaPart == .bottomLeftCorner {
            expand1 = min(
                startRect.minX - insets.left,
                self.bounds.height - insets.bottom - startRect.maxY
            )
        } else if activeCropAreaPart == .bottomRightCorner {
            expand1 = min(
                self.bounds.width - insets.right - startRect.maxX,
                self.bounds.height - insets.bottom - startRect.maxY
            )
        }

        return -expand2...expand1
    }

    private func sizeForRect(startRect: CGRect, translation: CGPoint) -> CGRect {
        var rect = startRect
        if activeCropAreaPart.contains(.topEdge) {
            let delta = caculateDeltaForRect(.topEdge, delta: -translation.y)
            rect.origin.y = startRect.origin.y - delta
            rect.size.height = startRect.size.height + delta
        }
        if activeCropAreaPart.contains(.rightEdge) {
            let delta = caculateDeltaForRect(.rightEdge, delta: translation.x)
            rect.size.width = startRect.size.width + delta
        }
        if activeCropAreaPart.contains(.bottomEdge) {
            let delta = caculateDeltaForRect(.bottomEdge, delta: translation.y)
            rect.size.height = startRect.size.height + delta
        }
        if activeCropAreaPart.contains(.leftEdge) {
            let delta = caculateDeltaForRect(.leftEdge, delta: -translation.x)
            rect.origin.x = startRect.origin.x - delta
            rect.size.width = startRect.size.width + delta
        }

        return rect
    }

    private func sizeForRectWithRatio(_ ratio: CGFloat, startRect: CGRect, translation: CGPoint) -> CGRect {
        var rect = startRect
        var deltaX: CGFloat = 0
        var deltaY: CGFloat = 0
        if activeCropAreaPart.contains(.topLeftCorner) {
            deltaY = caculateDeltaForRect(.topEdge, delta: -translation.y)
            if deltaY < 0 {
                deltaX = deltaY * ratio
                rect.origin.x = startRect.origin.x - deltaX
                rect.origin.y = startRect.origin.y - deltaY
                rect.size.width = startRect.size.width + deltaX
                rect.size.height = startRect.size.height + deltaY
            }
        } else if activeCropAreaPart.contains(.bottomLeftCorner) {
            deltaX = caculateDeltaForRect(.leftEdge, delta: -translation.x)
            deltaY = deltaX / ratio
            rect.origin.x = startRect.origin.x - deltaX
            rect.size.width = startRect.size.width + deltaX
            rect.size.height = startRect.size.height + deltaY
        } else if activeCropAreaPart.contains(.topRightCorner) {
            deltaY = caculateDeltaForRect(.topEdge, delta: -translation.y)
            if deltaY < 0 {
                deltaX = deltaY * ratio
                rect.origin.y = startRect.origin.y - deltaY
                rect.size.width = startRect.size.width + deltaX
                rect.size.height = startRect.size.height + deltaY
            }
        } else if activeCropAreaPart.contains(.bottomRightCorner) {
            deltaY = caculateDeltaForRect(.bottomEdge, delta: translation.y)
            if deltaY < 0 {
                deltaX = deltaY * ratio
                rect.size.width = startRect.size.width + deltaX
                rect.size.height = startRect.size.height + deltaY
            }
        } else if activeCropAreaPart.contains(.topEdge) {
            deltaY = caculateDeltaForRect(.topEdge, delta: -translation.y)
            if deltaY < 0 {
                deltaX = deltaY * ratio
                rect.origin.x = startRect.origin.x - deltaX / 2
                rect.origin.y = startRect.origin.y - deltaY
                rect.size.width = startRect.size.width + deltaX
                rect.size.height = startRect.size.height + deltaY
            }
        } else if activeCropAreaPart.contains(.bottomEdge) {
            deltaY = caculateDeltaForRect(.bottomEdge, delta: translation.y)
            if deltaY < 0 {
                deltaX = deltaY * ratio
                rect.origin.x = startRect.origin.x - deltaX / 2
                rect.size.width = startRect.size.width + deltaX
                rect.size.height = startRect.size.height + deltaY
            }
        } else if activeCropAreaPart.contains(.leftEdge) {
            deltaX = caculateDeltaForRect(.leftEdge, delta: -translation.x)
            deltaY = deltaX / ratio
            rect.origin.x = startRect.origin.x - deltaX
            rect.origin.y = startRect.origin.y - deltaY / 2
            rect.size.width = startRect.size.width + deltaX
            rect.size.height = startRect.size.height + deltaY
        } else if activeCropAreaPart.contains(.rightEdge) {
            deltaX = caculateDeltaForRect(.rightEdge, delta: translation.x)
            deltaY = deltaX / ratio
            rect.origin.y = startRect.origin.y - deltaY / 2
            rect.size.width = startRect.size.width + deltaX
            rect.size.height = startRect.size.height + deltaY
        }
        return rect
    }

    func enableRatioDragging(_ ratio: CGFloat?) {
        if let ratio = ratio {
            dragType = .dragInRatio(ratio: ratio)
        } else {
            dragType = .dragInFree
        }
    }

    private func caculateDeltaForRect(_ part: CropAreaPart, delta: CGFloat) -> CGFloat {
        let range = deltaRangeForRect(part)
        if delta < range.lowerBound {
            return range.lowerBound
        }
        if delta > range.upperBound {
            return range.upperBound
        }
        return delta
    }

    private func deltaRangeForRect(_ part: CropAreaPart) -> ClosedRange<CGFloat> {
        var expand1: CGFloat = 0
        var expand2: CGFloat = 0
        if part == .topEdge {
            expand1 = startRect.minY - insets.top
            expand2 = startRect.height - minCropSize.height
        } else if part == .bottomEdge {
            expand1 = bounds.height - insets.bottom - startRect.maxY
            expand2 = startRect.height - minCropSize.height
        } else if part == .leftEdge {
            expand1 = startRect.minX - insets.left
            expand2 = startRect.width - minCropSize.width
        } else if part == .rightEdge {
            expand1 = bounds.width - insets.right - startRect.maxX
            expand2 = startRect.width - minCropSize.width
        }

        return -expand2...expand1
    }

    private func getCropAreaPart(point: CGPoint) -> CropAreaPart {
        if hollow.topEdgeFrame.contains(point) {
            return .topEdge
        }
        if hollow.bottomEdgeFrame.contains(point) {
            return .bottomEdge
        }
        if hollow.leftEdgeFrame.contains(point) {
            return .leftEdge
        }
        if hollow.rightEdgeFrame.contains(point) {
            return .rightEdge
        }
        if hollow.topLeftCornerFrame.contains(point) {
            return .topLeftCorner
        }
        if hollow.topRightCornerFrame.contains(point) {
            return .topRightCorner
        }
        if hollow.bottomLeftCornerFrame.contains(point) {
            return .bottomLeftCorner
        }
        if hollow.bottomRightCornerFrame.contains(point) {
            return .bottomRightCorner
        }
        return .none
    }
}

struct CropAreaPart: OptionSet {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // swiftlint:disable operator_usage_whitespace
    static let none       = CropAreaPart(rawValue: 1 << 0)
    static let topEdge    = CropAreaPart(rawValue: 1 << 1)
    static let leftEdge   = CropAreaPart(rawValue: 1 << 2)
    static let bottomEdge = CropAreaPart(rawValue: 1 << 3)
    static let rightEdge  = CropAreaPart(rawValue: 1 << 4)
    // swiftlint:enable operator_usage_whitespace

    static let all: CropAreaPart = [.topEdge, .rightEdge, .bottomEdge, .leftEdge]

    static let topLeftCorner: CropAreaPart     = [.topEdge, .leftEdge]
    static let topRightCorner: CropAreaPart    = [.topEdge, .rightEdge]
    static let bottomRightCorner: CropAreaPart = [.bottomEdge, .rightEdge]
    static let bottomLeftCorner: CropAreaPart  = [.bottomEdge, .leftEdge]
}

//
//  AnnotationGestureDetector.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/30.
//

import UIKit
import Foundation
import LKCommonsLogging

public final class AnnotationGestureDetector: NSObject, UIGestureRecognizerDelegate {
    static let logger = Logger.log(AnnotationGestureDetector.self, category: "LarkOCR")

    var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    var panGesture: PanGestureRecognizer = PanGestureRecognizer()

    // 结果回调，返回选中结果以及是否是最终结果，拖拽中返回 false
    public var resultProvider: ([AnnotationBox], Bool) -> Void

    // 手势识别范围，提升手势开始判断的范围
    public var gestureHitScope: CGFloat = 3

    public var result: [AnnotationBox] = [] {
        didSet {
            self.resultProvider(result, true)
        }
    }
    private var tmpResults: [AnnotationBox] = []
    private var isPanning: Bool = false
    private var isPanningSelect: Bool = true

    public init(resultProvider: @escaping ([AnnotationBox], Bool) -> Void) {
        self.resultProvider = resultProvider
        super.init()

        self.tapGesture.delegate = self
        self.panGesture.delegate = self
        self.panGesture.maximumNumberOfTouches = 1

        self.tapGesture.addTarget(self, action: #selector(self.handleTapAction(gesture:)))
        self.panGesture.addTarget(self, action: #selector(self.handlePanAction(gesture:)))
    }

    public func addGestureTo(view: UIView) {
        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(panGesture)
    }

    @objc
    func handleTapAction(gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else {
            return
        }
        Self.logger.info("hanle tap action")
        let point = gesture.location(in: view)
        var selected = false
        // 优先按照原始点判断
        var showResults = self.result.map({ box -> AnnotationBox in
            var box = box
            if box.path.contains(point) && !selected {
                box.isSelected = !box.isSelected
                selected = true
            }
            return box
        })
        if !selected {
            // 如果没有选中则按照扩散点判断
            let points = self.touchBeginPoints(point: point)
            showResults = self.result.map({ box -> AnnotationBox in
                var box = box
                if !selected,
                   points.contains(where: { p in
                       return box.path.contains(p)
                   }) {
                    box.isSelected = !box.isSelected

                }
                return box
            })
        }
        self.result = showResults
    }

    @objc
    func handlePanAction(gesture: PanGestureRecognizer) {
        guard let view = gesture.view else {
            return
        }

        switch gesture.state {
        case .began, .changed:
            self.isPanning = true
            guard let touchBeginPoint = gesture.touchBeginPoint else {
                return
            }
            let point = gesture.location(in: view)
            let rect = CGRect(
                origin: touchBeginPoint,
                size: CGSize(
                    width: point.x - touchBeginPoint.x,
                    height: point.y - touchBeginPoint.y
                )
            )
            // 手势开始 初始化拖选状态
            if gesture.state == .began {
                let points = self.touchBeginPoints(point: touchBeginPoint)
                guard let firstIndex = self.result.firstIndex (where: { box -> Bool in
                    return points.contains { p in
                        return box.path.contains(p)
                    }
                }) else {
                    // 如果没有识别索引 则取消本次操作
                    gesture.isEnabled = false
                    gesture.isEnabled = true
                    return
                }
                let box = self.result[firstIndex]
                self.isPanningSelect = !box.isSelected
                Self.logger.info("hanle pan action begin")
            }
            let showResults = self.getResutByRect(rect: rect)
            self.tmpResults = showResults
            self.resultProvider(showResults, false)
        default:
            self.isPanning = false
            self.isPanningSelect = true
            if self.tmpResults.count == self.result.count {
                self.result = self.tmpResults
            }
            self.tmpResults = []
            Self.logger.info("hanle pan action end")
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = gestureRecognizer.view else {
            return false
        }
        if self.result.isEmpty {
            return false
        }
        if gestureRecognizer == self.tapGesture {
            let point = self.tapGesture.location(in: view)
            let points = self.touchBeginPoints(point: point)
            return self.result.contains { box in
                return points.contains { p in
                    return box.path.contains(p)
                }
            }
        }
        if gestureRecognizer == self.panGesture {
            if let point = self.panGesture.touchBeginPoint {
                let points = self.touchBeginPoints(point: point)
                let result = self.result.contains { box in
                    return points.contains { p in
                        return box.path.contains(p)
                    }
                }
                return result
            }
        }

        return false
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return false
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return true
    }

    // 根据 gestureHitScope 返回触摸点的扩散集合 用户扩大识别区域
    private func touchBeginPoints(point: CGPoint) -> [CGPoint] {
        var points = [point]
        if self.gestureHitScope > 0 {
            [(1, 1), (1, -1), (-1, 1), (-1, -1)].forEach { (x, y) in
                points.append(.init(
                    x: point.x + x * self.gestureHitScope,
                    y: point.y + y * self.gestureHitScope)
                )
            }
        }
        return points
    }

    private func getResutByRect(rect: CGRect) -> [AnnotationBox] {
        return self.result.enumerated().map({ i, box -> AnnotationBox in
            var tempBox = box
            if tempBox.path.bounds.intersects(rect) {
                tempBox.isSelected = self.isPanningSelect
                // 重置拖选区域 box 状态
                if box.isSelected {
                    self.result[i].isSelected = false
                }
            }
            return tempBox
        })
    }

    private func getResutByRectAndOrder(rect: CGRect, firstIndex: Int) -> [AnnotationBox] {
        let endMinIndex = self.result.firstIndex(where: { box -> Bool in
            return box.path.bounds.intersects(rect)
        }) ?? firstIndex
        let endMaxIndex = self.result.lastIndex(where: { box -> Bool in
            return box.path.bounds.intersects(rect)
        }) ?? firstIndex

        let minIndex = min(firstIndex, endMinIndex)
        let maxIndex = max(firstIndex, endMaxIndex)

        return self.result.enumerated().map { i, box in
            var tempBox = box
            // 重置拖选区域 box 状态
            if box.isSelected {
                self.result[i].isSelected = false
            }

            if i >= minIndex && i <= maxIndex {
                tempBox.isSelected = self.isPanningSelect
            }
            return tempBox
        }
    }
}

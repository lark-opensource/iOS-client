//
//  ImageEditAddTextView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/7/31.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkExtensions

protocol ImageEditAddTextViewDelegate: AnyObject {
    func addTextView(_ addTextView: ImageEditAddTextView, didTap highLightLabel: ImageEditAddTextLabel)
    func addTextViewCurrentColor(_ addTextView: ImageEditAddTextView) -> ColorPanelType
}

final class ImageEditAddTextView: ImageEditBaseView {
    weak var delegate: ImageEditAddTextViewDelegate?

    var labels: [ImageEditAddTextLabel] = []

    private let tapGesture = UITapGestureRecognizer()

    private let imageEditEventSubject: PublishSubject<ImageEditEvent>

    init(imageEditEventSubject: PublishSubject<ImageEditEvent>) {
        self.imageEditEventSubject = imageEditEventSubject
        super.init(frame: CGRect.zero)

        addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(blankTapGestureDidInvoke(tapGesture:)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var scrollViewCenter: CGPoint {
        if let zoomView = zoomView {
            return zoomView.zoomView.convert(zoomView.zoomView.bounds.center, to: self)
        }
        return bounds.center
    }

    var highlightedLabel: ImageEditAddTextLabel? {
        return labels.first(where: { $0.highlighted })
    }

    // MARK: Gesture
    @objc
    private func blankTapGestureDidInvoke(tapGesture: UITapGestureRecognizer) {
        if highlightedLabel != nil {
            unhighlightAllLabels()
        } else {
            guard let currentColor = delegate?.addTextViewCurrentColor(self) else { return }
            let point = tapGesture.location(in: self)
            let label = ImageEditAddTextLabel(editText: ImageEditText(text: nil, color: currentColor))
            add(label: label, at: point)
        }
    }

    @objc
    private func labelTapGestureDidInvoke(tapGesture: UITapGestureRecognizer) {
        guard let label = tapGesture.view as? ImageEditAddTextLabel else { return }
        if label.highlighted {
            delegate?.addTextView(self, didTap: label)
        } else {
            highlight(label: label)
        }
    }

    @objc
    func panDidInvoked(_ panGesture: UIPanGestureRecognizer) {
        // 此方法处理从 ImageEditFunctionBottomView 透传出来的手势，避免将文字移动到 BottomView 区域内不可再交互的问题
        let touchPoint = panGesture.location(in: panGesture.view)
        if let convertedPoint = panGesture.view?.convert(touchPoint, to: self),
           let label = labels.first(where: { $0.frame.contains(convertedPoint - panGesture.translation(in: self)) }) {
            // 查找到相应的
            handlePanGesture(panGesture, forLabel: label)
        }
    }

    @objc
    private func labelPanGestureDidInvoke(panGesture: UIPanGestureRecognizer) {
        guard let label = panGesture.view as? ImageEditAddTextLabel else { return }
        handlePanGesture(panGesture, forLabel: label)
    }

    private func handlePanGesture(_ panGesture: UIPanGestureRecognizer, forLabel label: ImageEditAddTextLabel) {
        highlight(label: label)
        switch panGesture.state {
        case .began:
            let center = label.center
            imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { [weak self, weak label] (_) in
                guard let self = self, let label = label else { return }
                self.updateCenterPoint(center, forLabel: label)
            })
        case .changed, .possible:
            let vector = panGesture.translation(in: self)
            let centerPoint = CGPoint(x: label.center.x + vector.x, y: label.center.y + vector.y)
            updateCenterPoint(centerPoint, forLabel: label)
            panGesture.setTranslation(CGPoint.zero, in: self)
        case .cancelled, .ended, .failed:
            break
        @unknown default:
            break
        }
    }

    @objc
    private func labelCloseGestureDidInvoke(tapGesture: UITapGestureRecognizer) {
        guard let label = tapGesture.view?.superview as? ImageEditAddTextLabel else { return }
        remove(label: label)
    }

    @objc
    private func labelResizeGestureDidInvoke(panGesture: UIPanGestureRecognizer) {
        guard let label = panGesture.view?.superview as? ImageEditAddTextLabel else { return }
        highlight(label: label)

        let location = panGesture.location(in: self)

        switch panGesture.state {
        case .began:
            let transform = label.transform
            imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (_) in
                label.transform = transform
            })
        case .changed:
            label.transform = .identity
            label.scale = 1
            let originFrame = label.frame

            let translation = label.center - originFrame.center
            let newLocation = location - translation

            let originDistance = distanceBetween(point1: originFrame.bottomRight, point2: originFrame.center)
            let currentDistance = distanceBetween(point1: newLocation, point2: originFrame.center)
            var scaleRatio = currentDistance / originDistance
            if scaleRatio < 0.7 { scaleRatio = 0.7 }
            label.scale = scaleRatio

            let vec1 = originFrame.bottomRight - originFrame.center
            let vec2 = newLocation - originFrame.center
            let radians = angelBetween(vec1: vec1, vec2: vec2)
            let rotaionRatio = CGAffineTransform(rotationAngle: radians)

            label.transform = rotaionRatio
        case .cancelled, .ended, .failed, .possible:
            imageEditEventSubject.onNext(ImageEditEvent(event: "pic_edit_text_size"))
        @unknown default:
            assertionFailure()
        }
    }

    private func distanceBetween(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let deltaX = point1.x - point2.x
        let deltaY = point1.y - point2.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }

    /// 两个向量夹角，弧度制
    private func angelBetween(vec1: CGPoint, vec2: CGPoint) -> CGFloat {
        return atan2(-vec1.x, -vec1.y) - atan2(-vec2.x, -vec2.y)
    }

    // MARK: public
    func add(editText: ImageEditText) {
        let label = ImageEditAddTextLabel(editText: editText)
        add(label: label, at: scrollViewCenter)
    }

    @discardableResult
    func add(label: ImageEditAddTextLabel, at point: CGPoint) -> ImageEditAddTextLabel {
        imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (target) in
            target.remove(label: label)
        })
        label.sizeToFit()
        label.tapGesture.addTarget(self, action: #selector(labelTapGestureDidInvoke(tapGesture:)))
        label.panGesture.addTarget(self, action: #selector(labelPanGestureDidInvoke(panGesture:)))
        label.closeTapGesture.addTarget(self, action: #selector(labelCloseGestureDidInvoke(tapGesture:)))
        label.resizePanGesture.addTarget(self, action: #selector(labelResizeGestureDidInvoke(panGesture:)))
        [label.tapGesture, label.panGesture, label.closeTapGesture, label.resizePanGesture]
            .forEach { tapGesture.require(toFail: $0) }
        labels.append(label)
        addSubview(label)
        updateCenterPoint(point, forLabel: label)
        return label
    }

    @discardableResult
    func remove(label: ImageEditAddTextLabel) -> ImageEditAddTextLabel {
        imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (target) in
            target.add(label: label, at: label.center)
        })
        labels.removeAll(where: { $0 === label })
        label.removeFromSuperview()
        return label
    }

    @discardableResult
    func highlight(label: ImageEditAddTextLabel) -> ImageEditAddTextLabel {
        labels.forEach { $0.highlighted = false }
        label.highlighted = true
        return label
    }

    func unhighlightAllLabels() {
        labels.forEach { $0.highlighted = false }
    }

    func update(color: ColorPanelType) {
        if let highlightedLabel = highlightedLabel {
            update(color: color, for: highlightedLabel)
        }
    }

    func update(color: ColorPanelType, for label: ImageEditAddTextLabel) {
        var editText = label.editText
        editText.color = color
        update(editText: editText, for: label)
    }

    func update(editText: ImageEditText, for label: ImageEditAddTextLabel, canUndo: Bool = true) {
        hasEverOperated = true

        let oldText = label.editText
        if canUndo, oldText != editText {
            imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (target) in
                target.update(editText: oldText, for: label, canUndo: false)
            })
        }
        let preCenter = label.center
        label.editText = editText
        label.sizeToFit()
        updateCenterPoint(preCenter, forLabel: label)
    }

    func canHandle(point: CGPoint) -> Bool {
        for label in labels {
            if label.frame.contains(point) {
                return true
            }
        }
        return false
    }

    override func becomeActive() {
        // Add text view 连续becomActive会有问题
        guard !isActive else { return }
        super.becomeActive()

        if labels.isEmpty {
            guard let currentColor = delegate?.addTextViewCurrentColor(self) else { return }
            add(editText: ImageEditText(text: nil, color: currentColor))
        }
        _ = labels.last.flatMap { highlight(label: $0) }
    }

    override func becomeDeactive() {
        super.becomeDeactive()
        unhighlightAllLabels()
    }

    // 更新 Label 的中心位置，并避免超出边界
    private func updateCenterPoint(_ centerPoint: CGPoint, forLabel label: ImageEditAddTextLabel) {
        var clampedPoint = centerPoint
        if !bounds.contains(centerPoint) {
            clampedPoint.x = min(max(centerPoint.x, bounds.minX), bounds.maxX)
            clampedPoint.y = min(max(centerPoint.y, bounds.minY), bounds.maxY)
        }
        label.center = clampedPoint
    }
}

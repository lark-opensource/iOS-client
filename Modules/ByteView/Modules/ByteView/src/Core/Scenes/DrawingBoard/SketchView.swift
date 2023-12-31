//
//  SketchView.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/15.
//

import Foundation
import UIKit
import Whiteboard

class SketchView: UIView, WhiteboardTouchDelegate {

    private var viewModel: SketchViewModel!

    var touchScaleX: CGFloat = 1.0
    var touchScaleY: CGFloat = 1.0

    var zoomScale: CGFloat = 1.0 {
        didSet {
            updateTextScale()
        }
    }

    var drawing = false
    var lastPointInBoard: CGPoint?

    // MARK: - paintboard

    var sketchRect: CGRect {
        CGRect(origin: .zero, size: self.viewModel.drawboard.canvasSize)
    }

    private func posInsideSketch(pos: CGPoint) -> Bool {
        sketchRect.contains(pos)
    }

    func whiteboardTouchLocation(touch: UITouch) -> CGPoint {
        let pos = touch.location(in: self)
        let boardPoint = CGPoint(x: (pos.x * touchScaleX).rounded(), y: (pos.y * touchScaleY).rounded())
        return boardPoint
    }

    func whiteboardTouchesBegan(location: CGPoint) {
        if self.window == nil {
            ByteViewSketch.logger.error("SketchView is receiving touch events when not attatched to a window")
        }
        if posInsideSketch(pos: location) {
            viewModel.paintTool.pointBegan(location)
            drawing = true
        }
        lastPointInBoard = location
    }

    func whiteboardTouchesMoved(locations: [CGPoint]) {
        locations.forEach(handlingTouch(_:))
    }

    func whiteboardTouchesEnded(location: CGPoint) {
        if let lastPointInBoard = lastPointInBoard,
            let clipedEndPoint = sketchRect.intersection(with: lastPointInBoard,
                                                         endPoint: location).1,
            drawing {
            viewModel.paintTool.pointsMoved([clipedEndPoint])
            viewModel.paintTool.pointEnded(clipedEndPoint)
            drawing = false
        } else if drawing {
            viewModel.paintTool.pointEnded(location)
            drawing = false
        }
        lastPointInBoard = nil
    }

    func whiteboardTouchesCancelled() {
        viewModel.paintTool.pointCancelled()
    }

    private func handlingTouch(_ location: CGPoint) {
        guard let lastPointInBoard = lastPointInBoard else {
            return
        }
        let clipedPoints = self.sketchRect.intersection(with: lastPointInBoard,
                                                        endPoint: location)
        if let clipedStartPoint = clipedPoints.0, !drawing {
            drawing = true
            viewModel.paintTool.pointBegan(clipedStartPoint)
            self.lastPointInBoard = location
            return
        }
        if let clipedEndPoint = clipedPoints.1, drawing {
            viewModel.paintTool.pointsMoved([clipedEndPoint])
            viewModel.paintTool.pointEnded(clipedEndPoint)
            drawing = false
            return
        }
        if posInsideSketch(pos: location), drawing {
            viewModel.paintTool.pointsMoved([location])
        }
        self.lastPointInBoard = location
    }

    func bindViewModel(sketch: SketchViewModel) {
        viewModel = sketch
        layer.addSublayer(sketch.drawboard.rootLayer)
        viewModel.drawboard.setBindView(view: self)
        for decorateLayer in viewModel.decorateLayers {
            decorateLayer.anchorPoint = CGPoint(x: 0, y: 0)
            decorateLayer.bounds = CGRect(origin: .zero, size: viewModel.drawboard.canvasSize)
            layer.addSublayer(decorateLayer)
        }
    }

    func updateTextScale() {
        guard zoomScale != 0 else {
            return
        }
        let transform = CGAffineTransform(scaleX: touchScaleX / zoomScale, y: touchScaleY / zoomScale)
        viewModel.drawboard.textScale = transform
    }

    func updateTouchTransform() {
        if self.bounds.width == 0 {
            self.touchScaleX = 0
        } else {
            self.touchScaleX = viewModel.drawboard.rootLayer.bounds.width / self.bounds.width
        }

        if self.bounds.height == 0 {
            self.touchScaleY = 0
        } else {
            self.touchScaleY = viewModel.drawboard.rootLayer.bounds.height / self.bounds.height
        }

        self.updateTextScale()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateTouchTransform()

        let scaleX = self.bounds.size.width / viewModel.drawboard.rootLayer.bounds.size.width
        let scaleY = self.bounds.size.height / viewModel.drawboard.rootLayer.bounds.size.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

        let updateAction: () -> Void = {
            self.viewModel.drawboard.rootLayer.setAffineTransform(transform)
            for decorateLayer in self.viewModel.decorateLayers {
                decorateLayer.bounds = CGRect(origin: .zero, size: self.viewModel.drawboard.canvasSize)
                decorateLayer.setAffineTransform(transform)
            }
        }

        if let animation = self.layer.animation(forKey: "bounds.size") {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animation.duration)
            CATransaction.setAnimationTimingFunction(animation.timingFunction)
            updateAction()
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updateAction()
            CATransaction.commit()
        }
    }
}

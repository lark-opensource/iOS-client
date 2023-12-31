//
//  ArrowPaintTool.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/3.
//

import Foundation

class ArrowPaintTool: PaintTool {

    weak var delegate: PaintToolDelegate?

    let sketch: RustSketch
    var style: ArrowPaintStyle = .default

    var paintStatus: SketchPaintStatus = .idle

    var origin: CGPoint?
    var dx: CGFloat = 0
    var dy: CGFloat = 0

    init(sketch: RustSketch) {
        self.sketch = sketch
    }

    var activeShape: SketchShape? {
        guard let origin = self.origin else {
            return nil
        }
        return ArrowDrawable(id: .none,
                             start: origin,
                             end: CGPoint(x: origin.x + dx, y: origin.y + dy),
                             style: style, userIdentifier: "")
    }

    func pointBegan(_ point: CGPoint) {
        guard paintStatus == .idle else {
            return
        }
        paintStatus = .painting
        origin = point
    }

    func pointsMoved(_ points: [CGPoint]) {
        guard paintStatus == .painting else {
            return
        }
        guard let origin = origin,
            let point = points.last else {
            return
        }
        dx = point.x - origin.x
        dy = point.y - origin.y

        delegate?.activeShapeChanged(tool: self)
    }

    func pointEnded(_ point: CGPoint) {
        guard paintStatus == .painting else {
            return
        }

        guard let origin = self.origin else {
            return
        }

        let (unit, drawable) = sketch.addArrow(origin: origin,
                                               end: point,
                                               style: style)
        if !drawable.id.isEmpty {
            delegate?.onNewShape(shape: drawable)
            delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
            delegate?.transport(operationUnits: [unit])
        }
        reset()
    }

    func pointCancelled() {
        guard paintStatus == .painting else {
            return
        }
        reset()
        return
    }

    func interrupt(saveDrawingShape: Bool) {
        guard paintStatus == .painting else {
            return
        }
        if saveDrawingShape,
            let origin = self.origin {
            let (unit, drawable) = sketch.addArrow(origin: origin,
                                                   end: CGPoint(x: origin.x + dx, y: origin.y + dy),
                                                   style: style)
            if !drawable.id.isEmpty {
                delegate?.onNewShape(shape: drawable)
                delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
                delegate?.transport(operationUnits: [unit])
            }
        }
        reset()
    }

    func reset() {
        paintStatus = .idle
        origin = nil
        dx = 0
        dy = 0
        delegate?.activeShapeChanged(tool: self)
    }

}

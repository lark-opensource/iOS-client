//
//  EraserTool.swift
//  ByteView
//
//  Created by helijian.666 on 2023/7/10.
//

import Foundation

class EraserTool: PaintTool {
    weak var delegate: PaintToolDelegate?

    let sketch: RustSketch
    var style: ArrowPaintStyle = .default

    var paintStatus: SketchPaintStatus = .idle

    var origin: CGPoint?

    var canEraserOthers: (() -> Bool)?

    init(sketch: RustSketch) {
        self.sketch = sketch
    }

    var activeShape: SketchShape? {
        nil
    }

    func pointBegan(_ point: CGPoint) {
        guard paintStatus == .idle else {
            return
        }
        paintStatus = .painting
        origin = point
        let canEraserOthers = canEraserOthers?() ?? false
        sketch.canEraseOthers = canEraserOthers
        if let transportData = sketch.startEraser(point: point) {
            delegate?.transport(operationUnits: [transportData])
            delegate?.shapesRemoved(with: transportData.removeData.ids)
            delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
        }
    }

    func pointsMoved(_ points: [CGPoint]) {
        guard paintStatus == .painting else {
            return
        }
        guard origin != nil, points.last != nil else {
            return
        }
        if let transportData = sketch.appendEraser(points: points) {
            delegate?.transport(operationUnits: [transportData])
            delegate?.shapesRemoved(with: transportData.removeData.ids)
            delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
        }
    }

    func pointEnded(_ point: CGPoint) {
        guard paintStatus == .painting else {
            return
        }
        guard origin != nil else {
            return
        }
        sketch.endEraser()
        reset()
    }

    func pointCancelled() {
        guard paintStatus == .painting else {
            return
        }
        reset()
    }

    func interrupt(saveDrawingShape: Bool) {
        guard paintStatus == .painting else {
            return
        }
        reset()
    }

    func reset() {
        paintStatus = .idle
        origin = nil
        SketchTracks.trackEraseAction()
    }
}

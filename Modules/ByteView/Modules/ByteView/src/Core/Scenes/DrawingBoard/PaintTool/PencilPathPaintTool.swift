//
//  PencilPathPaintTool.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/11/20.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import UIKit

private class PaintSession {

   /// |          | pencil_start | pencil_append | timer_tick| pencil_finish | interrupt |
   /// | -------- | ------------ | ------------- | --------- | ------------- | --------- |
   /// | initial  | synced       | -             | -         | -             | -         |
   /// | synced   | -            | invalid       | -         | finished      | finished  |
   /// | invalid  | -            | invalid       | synced    | finished      | finished  |
   /// | finished | -            | -             | -         | -             | -         |

    enum State {
        case initial
        case synced
        case invalid(Timer)
        case finished
    }

    weak var delegate: PaintToolDelegate?

    let sketch: RustSketch

    var state: State
    let tickInterval: TimeInterval
    var pencilPathDrawable: PencilPathDrawable?

    init(tickInterval: TimeInterval,
         sketch: RustSketch) {
        state = .initial
        self.sketch = sketch
        self.tickInterval = tickInterval
    }

    func onPencilStart(style: PencilPaintStyle, points: [CGPoint]) {
        guard case .initial = self.state else {
            return
        }
        ByteViewSketch.logger.info("PencilSession pencilStart")
        self.state = .synced
        sketch.startPencilWith(style: style)
        sketch.appendPencil(drawable: &self.pencilPathDrawable, points: points)
    }

    func onPencilAppend(points: [CGPoint]) {
        switch self.state {
        case .initial:
            return
        case .synced:
            let timer = Timer.scheduledTimer(withTimeInterval: self.tickInterval,
                                             repeats: false) { [weak self] timer in
                                                self?.onTimerTick(timer)
            }
            self.state = .invalid(timer)
            fallthrough
        case .invalid:
            sketch.appendPencil(drawable: &self.pencilPathDrawable, points: points)
        case .finished:
            return
        }
    }

    func onTimerTick(_ timer: Timer) {
        guard timer.isValid,
            case .invalid(let mTimer) = self.state,
            mTimer === timer else {
                return
        }
        self.state = .synced
        if delegate?.needsFitting != false,
           let unit = sketch.fitPencil() {
            delegate?.transport(operationUnits: [unit])
        }
    }

    func onPencilFinish() {
        switch self.state {
        case .initial, .finished:
            return
        case .invalid(let timer):
            timer.invalidate()
            fallthrough
        case .synced:
            ByteViewSketch.logger.info("PencilSession pencilFinish \(self.pencilPathDrawable)")
            self.state = .finished
            var units: [SketchOperationUnit] = []
            if delegate?.needsFitting != false,
               let unit0 = sketch.fitPencil() {
                units.append(unit0)
            }

            if let (unit1, shape) = sketch.finishPencil() {
                units.append(unit1)
                self.delegate?.transport(operationUnits: units)
                self.delegate?.onNewShape(shape: shape)
                self.delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
            }

            self.pencilPathDrawable = nil
        }
    }

    func onPencilInterrupted(saveDrawingPath: Bool) {
        switch self.state {
        case .initial, .finished:
            return
        case .invalid(let timer):
            timer.invalidate()
            fallthrough
        case .synced:
            ByteViewSketch.logger.info("PencilSession pencilInterrupted saveDrawingPath: \(saveDrawingPath), \(self.pencilPathDrawable)")
            self.state = .finished
            var units: [SketchOperationUnit] = []
            if delegate?.needsFitting != false,
               let unit0 = sketch.fitPencil() {
                units.append(unit0)
            }
            if let (unit1, shape) = sketch.finishPencil(),
                saveDrawingPath {
                units.append(unit1)
                delegate?.transport(operationUnits: units)
                self.delegate?.onNewShape(shape: shape)
                self.delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
            }
            self.pencilPathDrawable = nil
        }
    }

    deinit {
        switch state {
        case .invalid(let timer):
            timer.invalidate()
            fallthrough
        case .synced:
            ByteViewSketch.logger.warn("PencilSession \(self.pencilPathDrawable) deinit in \(state)")
            var units: [SketchOperationUnit] = []
            if delegate?.needsFitting != false,
               let unit0 = sketch.fitPencil() {
                units.append(unit0)
            }
            if let (unit1, shape) = sketch.finishPencil() {
                units.append(unit1)
                delegate?.transport(operationUnits: units)
                delegate?.onNewShape(shape: shape)
                self.delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
            }
        case .initial, .finished:
            break
        }
    }
}

extension PencilPaintStyle {
    static var `default` = PencilPaintStyle(color: UIColor.ud.colorfulRed,
                                            pencilType: .default)
}

class PencilPathPaintTool: PaintTool {

    private var session: PaintSession?

    let sketch: RustSketch

    var paintStyle: PencilPaintStyle = .default

    weak var delegate: PaintToolDelegate?

    var activeShape: SketchShape? {
        session?.pencilPathDrawable
    }

    init(sketch: RustSketch) {
        self.sketch = sketch
    }

    func pointBegan(_ point: CGPoint) {
        self.session = PaintSession(tickInterval: TimeInterval(sketch.settings.pencilConfig.fittingInterval / 1000),
                                    sketch: sketch)
        self.session?.delegate = self.delegate
        session?.onPencilStart(style: paintStyle, points: [point])
    }

    func pointsMoved(_ points: [CGPoint]) {
        session?.onPencilAppend(points: points)
        delegate?.activeShapeChanged(tool: self)
    }

    func pointEnded(_ point: CGPoint) {
        session?.onPencilAppend(points: [point])
        session?.onPencilFinish()
        delegate?.activeShapeChanged(tool: self)
    }

    func pointCancelled() {
        session?.onPencilFinish()
        delegate?.activeShapeChanged(tool: self)
    }

    func interrupt(saveDrawingShape: Bool) {
        session?.onPencilInterrupted(saveDrawingPath: saveDrawingShape)
        delegate?.activeShapeChanged(tool: self)
    }
}

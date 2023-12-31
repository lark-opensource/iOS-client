//
//  UndoShapeTool.swift
//  ByteView
//
//  Created by Prontera on 2019/12/5.
//

import Foundation
import UIKit

class UndoShapeTool {
    weak var delegate: PaintToolDelegate?

    let sketch: RustSketch

    init(sketch: RustSketch) {
        self.sketch = sketch
    }

    func undoShape() {
        if let (operation, removedIds, addShapes) = sketch.undoShape() {
            transport(operation: operation)
            if !removedIds.isEmpty {
                self.delegate?.shapesRemoved(with: removedIds)
            }
            if !addShapes.isEmpty {
                self.delegate?.shapesAdded(with: addShapes)
            }
        }
        delegate?.changeUndoStatus(canUndo: sketch.getUndoStatus())
    }

    private func transport(operation: SketchOperationUnit) {
        delegate?.transport(operationUnits: [operation])
    }
}

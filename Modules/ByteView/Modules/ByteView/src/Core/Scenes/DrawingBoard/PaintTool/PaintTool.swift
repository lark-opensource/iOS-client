//
//  PaintTool.swift
//  BoardPainter
//
//  Created by 刘建龙 on 2019/11/20.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import UIKit

enum SketchPaintStatus {
    case idle
    case painting
}

protocol PaintTool {
    var activeShape: SketchShape? { get }
    var delegate: PaintToolDelegate? { get set }

    func pointBegan(_ point: CGPoint)
    func pointsMoved(_ points: [CGPoint])
    func pointEnded(_ point: CGPoint)
    func pointCancelled()

    func interrupt(saveDrawingShape: Bool)
}

protocol PaintToolDelegate: AnyObject {
    // in main thread for sure
    func onNewShape(shape: SketchShape)
    func activeShapeChanged(tool: PaintTool)
    func shapesRemoved(with shapeIDs: [ShapeID])
    func shapesAdded(with shapes: [SketchShape])
    func changeUndoStatus(canUndo: Bool)
    func transport(operationUnits: [SketchOperationUnit])
    var needsFitting: Bool { get }
}

//
//  WbiteboardRenderer.swift
//  ByteView
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import QuartzCore
import WbLib

protocol WbiteboardRenderer {
    var rootLayer: NoActionRootLayer { get }
    var canvasSize: CGSize { get set }
    func add(drawable: WhiteboardShape, isTemp: Bool, drawableType: DrawableType) -> Bool
    func update(wbShape: WhiteboardShape, cmdUpdateType: CmdUpdateType, drawableType: DrawableType)
    func remove(byShapeID id: ShapeID)
    func updatePath(id: String, path: CGMutablePath)
    func isContainsLayerById(id: String) -> Bool
    func removeAll()
}

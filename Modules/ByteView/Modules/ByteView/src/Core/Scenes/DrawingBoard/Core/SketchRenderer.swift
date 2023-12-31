//
//  SketchRenderer.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/3/13.
//

import Foundation
import QuartzCore

public protocol SketchRenderer {
    var rootLayer: CALayer { get }
    var canvasSize: CGSize { get set }

    var drawables: [ShapeID: SketchShape] { get }

    func add(drawable: SketchShape) -> Bool
    func update(pencil: PencilPathDrawable)
    func remove(byShapeID id: ShapeID) -> SketchShape?
    func removeAll()
    func setBindView(_ view: UIView)
    func buildTextLayer(drawable: NicknameDrawable) -> CATextLayer?
}

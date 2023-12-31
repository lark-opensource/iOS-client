//
//  DrawBoard.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/11/21.
//

import Foundation
import CoreGraphics
import QuartzCore
import RxRelay

class DrawBoard {

    var renderer: SketchRenderer

    var canvasSize: CGSize {
        get {
            renderer.canvasSize
        }
        set {
            renderer.canvasSize = newValue
        }
    }

    var textScale: CGAffineTransform = .identity {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for textLayer in self.nicknameLayers.values {
                textLayer.setAffineTransform(textScale)
            }
            CATransaction.commit()
        }
    }

    var rootLayer: CALayer {
        renderer.rootLayer
    }

    // 本次入会后自己绘制的图形
    private var localShapeIDs = Set<String>()

    private var nicknameLayers: [ShapeID: CATextLayer] = [:]

    var showNickName: Bool = true

    init(renderer: SketchRenderer) {
        self.renderer = renderer
    }

    func setBindView(view: UIView) {
        renderer.setBindView(view)
    }

    func addLocal(drawable: SketchShape) {
        ByteViewSketch.logger.info("add local drawable \(drawable)")
        localShapeIDs.insert(drawable.id)
        add(drawable: drawable)
    }

    func addRemote(drawable: SketchShape) -> Bool {
        guard !localShapeIDs.contains(drawable.id) else {
            return false
        }
        ByteViewSketch.logger.info("add remote drawable \(drawable)")
        return add(drawable: drawable)
    }

    func updateRemote(pencil: PencilPathDrawable) {
        guard !localShapeIDs.contains(pencil.id) else {
            return
        }
        update(pencil: pencil)
    }

    @discardableResult
    private func add(drawable: SketchShape) -> Bool {
        guard renderer.add(drawable: drawable) else {
            ByteViewSketch.logger.warn("ignore duplicated drawable: \(drawable)")
            return false
        }
        return true
    }

    private func update(pencil: PencilPathDrawable) {
        if !renderer.drawables.keys.contains(pencil.id) {
            ByteViewSketch.logger.info("add \(pencil)")
        }
        renderer.update(pencil: pencil)
    }

    private func addNickname(drawable: NicknameDrawable) {
        if let layer = renderer.buildTextLayer(drawable: drawable) {
            layer.setAffineTransform(textScale)
            ByteViewSketch.logger.info("add drawable: \(drawable)")

            nicknameLayers[drawable.id] = layer
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            rootLayer.addSublayer(layer)
            CATransaction.commit()

            fadeNicknameLayer(layer, shapeID: drawable.id)
        }
    }

    func updateNickname(drawable: NicknameDrawable) {
        if let layer = nicknameLayers[drawable.id] {
            let size = layer.bounds.size
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.position = CGPoint(x: drawable.leftCenter.x + size.width / 2, y: drawable.leftCenter.y)
            layer.opacity = 1
            CATransaction.commit()

            fadeNicknameLayer(layer, shapeID: drawable.id)
        } else {
            self.addNickname(drawable: drawable)
        }
    }

    func removeNicknameLayer(byShapeID id: ShapeID) {
        if let layer = nicknameLayers.removeValue(forKey: id) {
            ByteViewSketch.logger.info("remove nickName: \(id)")
            layer.removeFromSuperlayer()
        }
    }

    private func fadeNicknameLayer(_ layer: CATextLayer, shapeID: ShapeID) {
        CATransaction.begin()
        let animationFadeOut = CABasicAnimation(keyPath: "opacity")
        animationFadeOut.fromValue = 1
        animationFadeOut.toValue = 0
        animationFadeOut.duration = 3
        animationFadeOut.isRemovedOnCompletion = false
        animationFadeOut.fillMode = .forwards
        CATransaction.setCompletionBlock { [weak self] in
            self?.removeNicknameLayer(byShapeID: shapeID)
        }
        layer.add(animationFadeOut, forKey: nil)
        CATransaction.commit()
    }

    @discardableResult
    func remove(byShapeID id: ShapeID) -> SketchShape? {
        ByteViewSketch.logger.info("remove by shapeID: \(id)")
        localShapeIDs.remove(id)
        return renderer.remove(byShapeID: id)
    }

    func reorderDrawables(orderedIDs: [ShapeID]) -> Set<ShapeID> {
        var removedIDSet = Set<ShapeID>(renderer.drawables.keys)
        removedIDSet.subtract(orderedIDs)
        for removed in removedIDSet {
            remove(byShapeID: removed)
        }
        return removedIDSet
    }

    func removeAllDrawables() {
        ByteViewSketch.logger.info("remove all drawables")
        localShapeIDs.removeAll()
        renderer.removeAll()
    }

    func addAllDrawables(drawables: [SketchShape]) {
        ByteViewSketch.logger.info("add all drawables:\(drawables.map { $0.id })")
        removeAllDrawables()
        drawables.forEach { _ = self.add(drawable: $0) }
    }
}

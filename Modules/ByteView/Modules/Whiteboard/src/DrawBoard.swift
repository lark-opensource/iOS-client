//
//  Whiteboard.swift
//  ByteView
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import CoreGraphics
import QuartzCore

class DrawBoard {

    var renderer: WbiteboardRenderer
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
    var showNickName: Bool = true
    let layerBuilder = LayerBuilder()

    // 本次入会后自己绘制的图形
    private var localShapeIDs = Set<String>()
    private var nicknameLayers: [ShapeID: CATextLayer] = [:]
    // 该NameTag上次更新是否需要fade动画（目的是当一笔画完，同一用户3s内又开始画，直接复用之前的layer)
    private var lastShouldFade: [ShapeID: Bool] = [:]

    init(renderer: WbiteboardRenderer) {
        self.renderer = renderer
    }

    func addLocal(drawable: WhiteboardShape) {
        logger.info("add local drawable \(drawable)")
        localShapeIDs.insert(drawable.id)
        add(drawable: drawable, drawableType: .vector)
    }

    @discardableResult
    func add(drawable: WhiteboardShape, isTemp: Bool = false, drawableType: DrawableType) -> Bool {
        guard renderer.add(drawable: drawable, isTemp: isTemp, drawableType: drawableType) else {
            logger.warn("ignore duplicated drawable: \(drawable)")
            return false
        }
        return true
    }

    func update(wbShape: WhiteboardShape, cmdUpdateType: CmdUpdateType, drawableType: DrawableType) {
        if !renderer.isContainsLayerById(id: wbShape.id) {
            logger.info("add \(wbShape)")
        }
        renderer.update(wbShape: wbShape, cmdUpdateType: cmdUpdateType, drawableType: drawableType)
    }

    func updatePath(id: String, path: CGMutablePath) {
        renderer.updatePath(id: id, path: path)
    }

    func changeBackgroundColor(_ color: UIColor) {
        rootLayer.backgroundColor = color.cgColor
    }

    private func addNickname(drawable: NicknameDrawable) {
        if let layer = layerBuilder.buildNicknameTextLayer(drawable: drawable) {
            layer.setAffineTransform(textScale)
            logger.info("add drawable: \(drawable)")
            nicknameLayers[drawable.id] = layer
            rootLayer.addSublayer(layer)
            lastShouldFade[drawable.id] = false
        }
    }

    func updateNickname(drawable: NicknameDrawable, shouldFade: Bool) {
        if let layer = nicknameLayers[drawable.id] {
            layer.position = CGPoint(x: drawable.position.x, y: drawable.position.y)
            layer.opacity = 1
            if lastShouldFade[drawable.id] == true {
                layer.removeAllAnimations()
            }
            lastShouldFade[drawable.id] = shouldFade
            if shouldFade {
                fadeNicknameLayer(layer, shapeID: drawable.id)
            }
        } else {
            self.addNickname(drawable: drawable)
        }
    }

    func removeNicknameLayer(byShapeID id: ShapeID) {
        if let layer = nicknameLayers.removeValue(forKey: id) {
            logger.info("remove nickName: \(id)")
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

    func remove(byShapeID id: ShapeID) {
        logger.info("remove by shapeID: \(id)")
        localShapeIDs.remove(id)
        renderer.remove(byShapeID: id)
    }

    func removeAllDrawables() {
        logger.info("remove all drawables")
        localShapeIDs.removeAll()
        renderer.removeAll()
    }

    func addAllDrawables(drawables: [WhiteboardShape]) {
        logger.info("add all drawables:\(drawables.map { $0.id })")
        removeAllDrawables()
        drawables.forEach { _ = self.add(drawable: $0, drawableType: .vector) }
    }
}

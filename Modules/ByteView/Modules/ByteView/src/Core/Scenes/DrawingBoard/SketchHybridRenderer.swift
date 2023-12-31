//
//  SketchRenderer.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/1/14.
//

import Foundation
import CoreGraphics

#if DEBUG
private let rasterizeBatchSize = 20
private let preservedVectorCnt = 20
#else
private let rasterizeBatchSize = 50
private let preservedVectorCnt = 500
#endif

private extension CATransaction {
    static func runWithoutAction<T>(body: () throws -> T) rethrows -> T {
        CATransaction.begin()
        defer { CATransaction.commit() }
        CATransaction.setDisableActions(true)
        return try body()
    }
}

private extension SketchShape {
    var isEnded: Bool {
        if let pencil = self as? PencilPathDrawable,
            !pencil.finish {
            return false
        }
        return true
    }
}

class SketchHybridRenderer: NSObject, SketchRenderer {

    var canvasSize: CGSize = CGSize(width: 1024, height: 768) {
        didSet {
            rootLayer.bounds = CGRect(origin: .zero, size: canvasSize)
            invalidContent()
        }
    }

    private var content: CGImage?
    private let layerBuilder = LayerBuilder()

    let rootLayer: CALayer

    var drawables: [ShapeID: SketchShape] = [:]

    var shapeLayers: [ShapeID: CAShapeLayer] = [:]

    var vectorShapeIDs: [ShapeID] = []
    var rasterizedShapeIDs: [ShapeID] = []

    init(canvasSize: CGSize) {
        self.canvasSize = canvasSize
        self.rootLayer = CALayer()
        self.rootLayer.anchorPoint = .zero
        self.rootLayer.frame = CGRect(origin: .zero, size: canvasSize)

        super.init()

        self.rootLayer.delegate = self
    }

    deinit {
        self.rootLayer.delegate = nil
    }

    func setBindView(_ view: UIView) {
        layerBuilder.setBindView(view: view)
    }

    func buildTextLayer(drawable: NicknameDrawable) -> CATextLayer? {
        return layerBuilder.buildTextLayer(drawable: drawable)
    }

    func add(drawable: SketchShape) -> Bool {
        guard !drawables.keys.contains(drawable.id) else {
            return false
        }

        vectorShapeIDs.append(drawable.id)

        drawables[drawable.id] = drawable
        if let layer = layerBuilder.buildLayer(drawable: drawable) {
            shapeLayers[drawable.id] = layer
            CATransaction.runWithoutAction {
                rootLayer.addSublayer(layer)
            }
        }
        if drawable.isEnded {
            rootLayer.setNeedsDisplay()
        }
        return true
    }

    func remove(byShapeID id: ShapeID) -> SketchShape? {
        if let idx = vectorShapeIDs.firstIndex(of: id) {
            vectorShapeIDs.remove(at: idx)
            let layer = shapeLayers.removeValue(forKey: id)
            layer?.removeFromSuperlayer()
        } else if let idx = rasterizedShapeIDs.firstIndex(of: id) {
            rasterizedShapeIDs.remove(at: idx)
            shapeLayers.removeValue(forKey: id)
            invalidContent()
        }
        return drawables.removeValue(forKey: id)
    }

    func removeAll() {
        shapeLayers.forEach { $0.value.removeFromSuperlayer() }
        shapeLayers = [:]
        drawables = [:]
        vectorShapeIDs = []
        rasterizedShapeIDs = []
        invalidContent()
    }

    func update(pencil: PencilPathDrawable) {
        updatePencilLayer(pencil)
        let id = pencil.id
        if vectorShapeIDs.contains(id) {
            // do nothing
        } else if rasterizedShapeIDs.contains(id) {
            invalidContent()
        } else {
            vectorShapeIDs.append(id)
            if let layer = shapeLayers[id] {
                CATransaction.runWithoutAction {
                    rootLayer.addSublayer(layer)
                }
            }
        }
        if pencil.finish {
            rootLayer.setNeedsDisplay()
        }
    }

    private func updatePencilLayer(_ pencil: PencilPathDrawable) {
        drawables[pencil.id] = pencil
        if let layer = shapeLayers[pencil.id] {
            layer.path = pencil.path
        } else if let layer = layerBuilder.buildLayer(drawable: pencil) {
            shapeLayers[pencil.id] = layer
        }
    }

    func invalidContent() {
        content = nil
        rootLayer.setNeedsDisplay()
    }

    func update(oldContent: CGImage?, ids: [ShapeID]) -> CGImage? {
        // Avoid using image cache, if bitmap context takes up more than 32M memory
        // nolint-next-line: magic number
        guard canvasSize.width * canvasSize.height <= 4090 * 2160,
            let ctx = CGContext(data: nil,
                                  width: Int(canvasSize.width),
                                  height: Int(canvasSize.height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.genericRGBLinear) ?? CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                                    ByteViewSketch.logger.error("failed create BitmapContext canvasSize: \(canvasSize)")
                                    return nil
        }

        if let oldContent = oldContent {
            ctx.draw(oldContent, in: CGRect(origin: CGPoint(x: 0, y: canvasSize.height - CGFloat(oldContent.height)),
                                            size: CGSize(width: oldContent.width, height: oldContent.height)))
        }
        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.translateBy(x: 0.0, y: -canvasSize.height)
        for layer in ids.compactMap({ shapeLayers[$0] }) {
            layer.render(in: ctx)
        }
        return ctx.makeImage()
    }

    func buildContentIfNeeded() {
        let rasterizableCnt = self.vectorShapeIDs.firstIndex(where: { !drawables[$0]!.isEnded })
            ?? self.vectorShapeIDs.count

        let newRasterizedCnt = max(min(rasterizableCnt, self.vectorShapeIDs.count - preservedVectorCnt), 0)

        let newRasterizedIDs = Array(vectorShapeIDs[0..<newRasterizedCnt])
        if let content = self.content {
            guard newRasterizedCnt >= rasterizeBatchSize else {
                return
            }
            if let newContent = update(oldContent: content, ids: newRasterizedIDs) {
                self.content = newContent
                vectorShapeIDs.removeFirst(newRasterizedCnt)
                rasterizedShapeIDs.append(contentsOf: newRasterizedIDs)
                for layer in newRasterizedIDs.compactMap({ shapeLayers[$0] }) {
                    CATransaction.runWithoutAction {
                        layer.removeFromSuperlayer()
                    }
                }
            } else {
                ByteViewSketch.logger.error("failed to rasterized shapes \(newRasterizedIDs)")
            }
        } else {
            vectorShapeIDs.removeFirst(newRasterizedCnt)
            rasterizedShapeIDs.append(contentsOf: newRasterizedIDs)
            guard !rasterizedShapeIDs.isEmpty else {
                return
            }

            if let newContent = update(oldContent: nil, ids: rasterizedShapeIDs) {
                self.content = newContent
                for layer in newRasterizedIDs.compactMap({ shapeLayers[$0] }) {
                    CATransaction.runWithoutAction {
                        layer.removeFromSuperlayer()
                    }
                }
            } else {
                vectorShapeIDs.insert(contentsOf: rasterizedShapeIDs, at: 0)
                rasterizedShapeIDs.removeAll()
                for layer in vectorShapeIDs.compactMap({ shapeLayers[$0] }) {
                    layer.removeFromSuperlayer()
                    rootLayer.addSublayer(layer)
                }
            }
        }
    }
}

extension SketchHybridRenderer: CALayerDelegate {
    func display(_ layer: CALayer) {
        buildContentIfNeeded()
        CATransaction.runWithoutAction {
            layer.contents = content
        }
    }
}

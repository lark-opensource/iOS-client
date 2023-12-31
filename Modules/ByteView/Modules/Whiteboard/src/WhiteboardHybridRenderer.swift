//
//  WbiteboardRenderer.swift
//  ByteView
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import CoreGraphics
import UIKit

#if DEBUG
private let rasterizeBatchSize = 50
private let preservedVectorCnt = 500
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

class SketchHybridRenderer: NSObject, WbiteboardRenderer {

    var canvasSize: CGSize = CGSize(width: 1024, height: 768) {
        didSet {
            rootLayer.bounds = CGRect(origin: .zero, size: canvasSize)
            invalidContent()
        }
    }

    private var content: CGImage?
    private let layerBuilder = LayerBuilder()
    let rootLayer: NoActionRootLayer

    var shapeLayers: [ShapeID: CAShapeLayer] = [:]
    var textLayers: [ShapeID: CATextLayer] = [:]
    var rasterizedShapeIDs: [ShapeID] = []
    var vectorShapeIDs: [ShapeID] = []

    init(canvasSize: CGSize) {
        self.canvasSize = canvasSize
        self.rootLayer = NoActionRootLayer()
        self.rootLayer.masksToBounds = true
        self.rootLayer.anchorPoint = .zero
        self.rootLayer.frame = CGRect(origin: .zero, size: canvasSize)
        super.init()
        self.rootLayer.delegate = self
    }

    deinit {
        self.rootLayer.delegate = nil
    }

    func add(drawable: WhiteboardShape, isTemp: Bool, drawableType: DrawableType) -> Bool {
        guard !(shapeLayers.keys.contains(drawable.id) || textLayers.keys.contains(drawable.id)) else {
            return false
        }
        switch drawableType {
        case .text:
            if let layer = layerBuilder.buildRecognizeTextLayer(drawable: drawable) {
                textLayers[drawable.id] = layer
                rootLayer.addSublayer(layer)
            }
        case .vector:
            vectorShapeIDs.append(drawable.id)
            if let layer = layerBuilder.buildLayer(drawable: drawable) {
                shapeLayers[drawable.id] = layer
                rootLayer.addSublayer(layer)
            }
        default:
            logger.info("unsupported drawableType: \(drawableType)")
        }
        rootLayer.setNeedsDisplay()
        return true
    }

    func isContainsLayerById(id: String) -> Bool {
        return shapeLayers.keys.contains(id) || textLayers.keys.contains(id)
    }

    func remove(byShapeID id: ShapeID) {
        if let idx = vectorShapeIDs.firstIndex(of: id) {
            vectorShapeIDs.remove(at: idx)
            let layer = shapeLayers.removeValue(forKey: id)
            layer?.removeFromSuperlayer()
        } else if textLayers.index(forKey: id) != nil {
            let layer = textLayers.removeValue(forKey: id)
            layer?.removeFromSuperlayer()
        } else if let idx = rasterizedShapeIDs.firstIndex(of: id) {
            rasterizedShapeIDs.remove(at: idx)
            shapeLayers.removeValue(forKey: id)
            invalidContent()
        }
    }

    func removeAll() {
        shapeLayers.forEach { $0.value.removeFromSuperlayer() }
        shapeLayers = [:]
        textLayers.forEach { $0.value.removeFromSuperlayer() }
        textLayers = [:]
        vectorShapeIDs = []
        rasterizedShapeIDs = []
        invalidContent()
    }

    func updatePath(id: String, path: CGMutablePath) {
        if let layer = shapeLayers[id] {
            layer.path = path
        }
        rootLayer.setNeedsDisplay()
    }

    func update(wbShape: WhiteboardShape, cmdUpdateType: CmdUpdateType, drawableType: DrawableType) {
        switch cmdUpdateType {
        case .graphic:
            switch drawableType {
            case .vector:
                if let layer = shapeLayers[wbShape.id] { layer.removeFromSuperlayer() }
                if let newLayer = layerBuilder.buildLayer(drawable: wbShape) {
                    shapeLayers[wbShape.id] = newLayer
                    rootLayer.addSublayer(newLayer)
                }
            case .text:
                if let layer = textLayers[wbShape.id] { layer.removeFromSuperlayer() }
                if let newLayer = layerBuilder.buildRecognizeTextLayer(drawable: wbShape) {
                    textLayers[wbShape.id] = newLayer
                    rootLayer.addSublayer(newLayer)
                }
            default:
                return
            }
        case .path:
            guard drawableType == .vector else { return }
            if let vector = wbShape as? VectorShape, let layer = shapeLayers[vector.id] {
                layer.path = vector.path
            } else { return }
        default:
            return
        }
        rootLayer.setNeedsDisplay()
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
            logger.error("failed create BitmapContext canvasSize: \(canvasSize)")
            return nil
        }
        if let oldContent = oldContent {
            ctx.draw(oldContent, in: CGRect(origin: CGPoint(x: 0, y: 0),
                                            size: CGSize(width: oldContent.width, height: oldContent.height)))
        }

        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.translateBy(x: 0.0, y: -canvasSize.height)
        let newLayer = CALayer()
        newLayer.bounds = rootLayer.bounds
        for layer in shapeLayers.values {
            newLayer.addSublayer(layer)
        }
        newLayer.render(in: ctx)
        return ctx.makeImage()
    }

    func buildContentIfNeeded() {
        let rasterizableCnt = self.vectorShapeIDs.count
        let newRasterizedCnt = max(min(rasterizableCnt, self.shapeLayers.count - preservedVectorCnt), 0)
        let newRasterizedIDs = Array(vectorShapeIDs[0..<newRasterizedCnt])
        guard newRasterizedCnt >= rasterizeBatchSize else {
            return
        }
        if let content = self.content {
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
                logger.error("failed to rasterized shapes \(newRasterizedIDs)")
            }
        } else {
            vectorShapeIDs.removeFirst(newRasterizedCnt)
            rasterizedShapeIDs.append(contentsOf: newRasterizedIDs)
            guard !rasterizedShapeIDs.isEmpty else {
                return
            }
            if let newContent = update(oldContent: nil, ids: newRasterizedIDs) {
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

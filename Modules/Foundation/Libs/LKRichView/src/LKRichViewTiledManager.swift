//
//  LKRichViewTiledManager.swift
//  LKRichView
//
//  Created by 袁平 on 2021/10/22.
//

import UIKit
import Foundation
struct TiledContext {
    let isOpaque: Bool
    let backgroundColor: CGColor?
    let hostView: PaintInfoHostView
    let hostBounds: CGRect
    let debugOptions: ConfigOptions?
}

struct TiledInfo {
    var runBoxs: [RunBox]
    var area: UInt
}

struct LKRichViewTiledManager {
    /// 支持按Rect分片 & 按Line分片
    /// maxTiledSize：分片大小，并不是严格按照大小进行划分
    static func tiled(
        runBoxs: [RunBox],
        maxTiledSize: UInt,
        tiledContext: TiledContext,
        isCanceled: () -> Bool,
        displayTiled: (UIImage, CGRect) -> Void,
        tiledCompletion: () -> Void
    ) {
        let infos = runBoxs.flatMap({ $0.getTiledInfos() })
        // 当前分片能装下的TiledInfo
        var remainedLines = [TiledInfo]()
        var sumArea: UInt = 0
        for info in infos {
            if isCanceled() { return }
            if info.area >= maxTiledSize { // 单个TiledInfo大于maxTiledSize，按照Rect分片
                tiledByLines(lines: remainedLines, tiledContext: tiledContext, displayTiled: displayTiled)
                remainedLines = []
                sumArea = 0
                tiledByRect(
                    tiledInfo: info,
                    maxTiledSize: maxTiledSize,
                    tiledContext: tiledContext,
                    isCanceled: isCanceled,
                    displayTiled: displayTiled
                )
                continue
            }
            sumArea += info.area
            remainedLines.append(info)
            if sumArea >= maxTiledSize { // 按照Line分片
                tiledByLines(lines: remainedLines, tiledContext: tiledContext, displayTiled: displayTiled)
                remainedLines = []
                sumArea = 0
            }
        }

        // 处理最后一个分片情况
        if !remainedLines.isEmpty {
            tiledByLines(lines: remainedLines, tiledContext: tiledContext, displayTiled: displayTiled)
        }

        if !isCanceled() {
            // 分片结束
            tiledCompletion()
        }
    }

    private static func tiledByRect(
        tiledInfo: TiledInfo,
        maxTiledSize: UInt,
        tiledContext: TiledContext,
        isCanceled: () -> Bool,
        displayTiled: (UIImage, CGRect) -> Void
    ) {
        let rects = splitToRects(tiledInfo: tiledInfo, maxTiledSize: maxTiledSize)
        for rect in rects {
            if isCanceled() { return }
            let bitmap = createRenderBitmap(renderRect: rect, tiledContext: tiledContext) { context in
                let paintInfo = PaintInfo(context: context, rect: tiledContext.hostBounds, hostView: tiledContext.hostView, debugOptions: tiledContext.debugOptions)
                display(runBoxs: tiledInfo.runBoxs, renderRect: rect, paintInfo: paintInfo)
            }
            displayTiled(bitmap, rect.convertCoreText2UIViewCoordinate(tiledContext.hostBounds))
        }
    }

    /// - Parameters:
    ///     - lines: 待绘制的Lines
    ///     - tiledContext:
    ///     - displayTiled:
    private static func tiledByLines(
        lines: [TiledInfo],
        tiledContext: TiledContext,
        displayTiled: (UIImage, CGRect) -> Void
    ) {
        let runBoxs = lines.flatMap({ $0.runBoxs })
        let globalRect = renderRect(runBoxs: runBoxs)
        let bitmap = createRenderBitmap(renderRect: globalRect, tiledContext: tiledContext) { context in
            let paintInfo = PaintInfo(context: context, rect: tiledContext.hostBounds, hostView: tiledContext.hostView, debugOptions: tiledContext.debugOptions)
            display(runBoxs: runBoxs, renderRect: globalRect, paintInfo: paintInfo)
        }
        displayTiled(bitmap, globalRect.convertCoreText2UIViewCoordinate(tiledContext.hostBounds))
    }

    /// split by longer side
    private static func splitToRects(tiledInfo: TiledInfo, maxTiledSize: UInt) -> [CGRect] {
        let globalRect = renderRect(runBoxs: tiledInfo.runBoxs)
        let size = globalRect.size
        // 取长边分片
        let isWidthSolid = size.width < size.height
        let solidSize = min(size.width, size.height)
        var splitSize = max(size.width, size.height)
        let tiledSize = CGFloat(maxTiledSize) / solidSize
        var rects = [CGRect]()
        var x = globalRect.minX
        var y = globalRect.minY
        while splitSize > 0 {
            let preferSize = min(tiledSize, splitSize)
            let width = isWidthSolid ? size.width : preferSize
            let height = isWidthSolid ? preferSize : size.height
            let rect = CGRect(x: x, y: y, width: width, height: height)
            x = isWidthSolid ? x : x + preferSize
            y = isWidthSolid ? y + preferSize : y
            splitSize -= tiledSize
            rects.append(rect)
        }
        // CoreText坐标在左下角，当以Y轴分片时，Y轴需要翻转一下，防止视觉看到从下往上的顺序绘制
        if isWidthSolid {
            rects.reverse()
        }
        return rects
    }

    private static func renderRect(runBoxs: [RunBox]) -> CGRect {
        guard !runBoxs.isEmpty else { return .zero }
        let maxX = runBoxs.max(by: { $0.globalRect.maxX < $1.globalRect.maxX })?.globalRect.maxX ?? 0
        let minX = runBoxs.min(by: { $0.globalRect.minX < $1.globalRect.minX })?.globalRect.minX ?? 0
        let maxY = runBoxs.max(by: { $0.globalRect.maxY < $1.globalRect.maxY })?.globalRect.maxY ?? 0
        let minY = runBoxs.min(by: { $0.globalRect.minY < $1.globalRect.minY })?.globalRect.minY ?? 0
        return .init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private static func createRenderBitmap(renderRect: CGRect, tiledContext: TiledContext, _ block: (CGContext) -> Void) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: renderRect.size)
        return renderer.image(actions: { renderCtx in
            let context = renderCtx.cgContext
            if tiledContext.isOpaque {
                context.saveGState()
                let bgColor = tiledContext.backgroundColor ?? UIColor.white.cgColor
                context.setFillColor(bgColor.alpha < 1 ? UIColor.white.cgColor : bgColor)
                context.fill(renderRect)
                context.restoreGState()
            }
            block(context)
        })
    }

    private static func display(runBoxs: [RunBox], renderRect: CGRect, paintInfo: PaintInfo) {
        paintInfo.graphicsContext.saveGState()
        /// This line change canvas origin to global.
        /// 后面的renderObject的绘制本来分Tiled和非Tield，这两种绘制的相对坐标系不同，因此会导致底层感知坐标系变化。因此统一使用全局坐标系，这里
        /// 把坐标系映射成全局，画布偏移
        paintInfo.graphicsContext.translateBy(x: -renderRect.origin.x, y: renderRect.origin.y + renderRect.height)
        paintInfo.graphicsContext.scaleBy(x: 1, y: -1)
        runBoxs.forEach({ $0.draw(paintInfo) })
        paintInfo.graphicsContext.restoreGState()
    }
}

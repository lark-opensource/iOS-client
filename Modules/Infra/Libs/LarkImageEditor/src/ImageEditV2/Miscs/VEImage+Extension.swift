//
//  VEImage+Extension.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/18.
//

import UIKit
import Foundation
import TTVideoEditor
import CoreGraphics

extension VEImage {
    // 当前图片在屏幕上的frame
    var currentLayerFrameOnView: CGRect {
        let currentLayerFrame = queryCurrentLayerFrame(false, isLayerInCanvas: false)
        let pointX = min(min(currentLayerFrame.ld.x, currentLayerFrame.lu.x),
                         min(currentLayerFrame.rd.x, currentLayerFrame.ru.x))
        let pointY = min(min(makeVETransformY(currentLayerFrame.ld.y),
                             makeVETransformY(currentLayerFrame.lu.y)),
                         min(makeVETransformY(currentLayerFrame.rd.y),
                             makeVETransformY(currentLayerFrame.ru.y)))

        let maxX = max(max(currentLayerFrame.ld.x, currentLayerFrame.lu.x),
                       max(currentLayerFrame.rd.x, currentLayerFrame.ru.x))

        let maxY = max(max(makeVETransformY(currentLayerFrame.ld.y),
                           makeVETransformY(currentLayerFrame.lu.y)),
                       max(makeVETransformY(currentLayerFrame.rd.y),
                           makeVETransformY(currentLayerFrame.ru.y)))

        return .init(x: pointX, y: pointY, width: maxX - pointX, height: maxY - pointY)
    }

    // 将VE的CGPoint的y转化为屏幕的y值，原因是VE以左下角为原点
    func makeVETransformY(_ pointY: CGFloat) -> CGFloat {
        return preview.bounds.size.height - pointY
    }

    // 获取Sticker的size
    func getStickerBoxSize(with stickerID: Int32) -> CGSize {
        let box = getStickerBoundingBoxWitnIndex(stickerID, needScale: true)
        let currentLayerFrame = queryCurrentLayerFrame(false, isLayerInCanvas: false)
        let currentLayerWidth = currentLayerFrame.ru.x - currentLayerFrame.lu.x
        let currentLayerHeight = currentLayerFrame.ru.y - currentLayerFrame.rd.y
        return .init(width: CGFloat(abs((box.right - box.left))) * currentLayerWidth,
                     height: CGFloat(abs((box.bottom - box.top))) * currentLayerHeight)
    }

    // 设置Sticker的位置
    func setAndConvertPostionToSticker(id: Int32, point: CGPoint) -> (CGFloat, CGFloat) {
        let info = queryCurrentLayerFrame(false, isLayerInCanvas: false)
        let pointNorm = CGPoint(x: point.x / (info.ru.x - info.lu.x),
                                y: point.y / (info.lu.y - info.ld.y))
        stickerSetPositon(with: Int(id), point: pointNorm)
        return (pointNorm.x, pointNorm.y)
    }

    // 以图片左上角或左下角为原点，图片中心的位置
    var frameCenterOnFrame: CGPoint {
        let info = currentLayerFrameOnView
        return .init(x: info.width / 2, y: info.height / 2)
    }

    // sticker中心屏幕的坐标
    func getStickerCenterOnView(_ sticker: TextSticker) -> CGPoint {
        let frame = currentLayerFrameOnView
        let stickerCenter = CGPoint(x: sticker.centerNormX * frame.size.width,
                                    y: sticker.centerNormY * frame.size.height)
        return .init(x: stickerCenter.x + frame.minX, y: stickerCenter.y + frame.minY)
    }

    // sticker中心在preview的坐标
    func getStickerCenterOnFrame(_ sticker: TextSticker) -> CGPoint {
        let frame = currentLayerFrameOnView
        return .init(x: sticker.centerNormX * frame.size.width,
                     y: sticker.centerNormY * frame.size.height)
    }

    // 缩放到全屏
    func scaleToFullScreen(_ size: CGSize) -> CGFloat {
        let info = queryCurrentLayerFrame(false, isLayerInCanvas: false)
        let layerWidth = info.ru.x - info.lu.x
        let layerHeight = info.lu.y - info.ld.y
        let mid = CGPoint(x: (info.ru.x + info.lu.x) / 2,
                          y: (info.lu.y + info.ld.y) / 2)
        let targetScale = size.width / size.height < 0.75
            ? size.width / layerWidth : min(size.width / layerWidth,
                                            size.height / layerHeight)
        scale(withScale: .init(width: targetScale, height: targetScale),
                          anchor: mid)
        preview.frame = currentLayerFrameOnView
        let frameOrigin = currentLayerFrameOnView.origin
        translate(withOffset: .init(x: -frameOrigin.x, y: frameOrigin.y))

        return targetScale
    }

    // 图片原始尺寸和当前显示尺寸的比值
    var imageScale: CGFloat {
        let originImageSize = getCurrentLayerSize()
        let currentSize = preview.frame.size
        return currentSize.width / originImageSize.width
    }
}

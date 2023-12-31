//
//  ImageEditorBrushOperator.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/9.
//

import Foundation
import TTVideoEditor
import UIKit

final class ImageEditorBrushOperator: ImageEditorOperator {
    private var paintBeforePoint = CGPoint()
    private(set) var brushID = Int32(0)

    private func setBrushParams(with dict: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict,
                                                         options: JSONSerialization.WritingOptions(rawValue: 0)),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            assertionFailure("brush params init error")
            return
        }
        imageEditor.setStickerBrushParams(jsonString)
    }

    private func transformToVELineWidth(_ sliderWidth: CGFloat) -> CGFloat {
        let scale = (delegate?.currentImageScale ?? 1) * (delegate?.currentImageInitialScale ?? 1)
        return sliderWidth / scale
    }
}

// internal apis
extension ImageEditorBrushOperator {
    func handleBrushPanGesture(_ gesture: UIPanGestureRecognizer, afterEnded: (() -> Void)? = nil) {
        let tapPoint = gesture.location(in: gesture.view)
        var point = gesture.translation(in: gesture.view)
        switch gesture.state {
        case .began:
            paintBeforePoint = .zero
            imageEditor.processGesture(withPath: ImageEditorResourceManager.brushResourcePath,
                                       commandID: STICKER_BRUSH,
                                       type: TEIMAGE_GT_TOUCH_DOWN,
                                       point: tapPoint,
                                       offset: .zero,
                                       factor: 1,
                                       etc: 2)
        case .ended, .cancelled, .failed:
            imageEditor.processGesture(withPath: ImageEditorResourceManager.brushResourcePath,
                                       commandID: STICKER_BRUSH,
                                       type: TEIMAGE_GT_TOUCH_UP,
                                       point: tapPoint,
                                       offset: .zero,
                                       factor: 0,
                                       etc: 2)
            paintBeforePoint = .zero
            afterEnded?()
        case .changed:
            point.y *= -1
            let translate = CGPoint(x: point.x - paintBeforePoint.x, y: paintBeforePoint.y - point.y)
            paintBeforePoint = point
            imageEditor.processGesture(withPath: ImageEditorResourceManager.brushResourcePath,
                                       commandID: STICKER_BRUSH,
                                       type: TEIMAGE_GT_PAN,
                                       point: tapPoint,
                                       offset: translate,
                                       factor: 1,
                                       etc: 2)
        case .possible: break
        @unknown default: assertionFailure("should not come here")
        }
        delegate?.setRenderFlag()
    }

    func changeLineColor(with color: UIColor) {
        let rgba = color.rgba
        let brushParams: [String: Any] = ["brush_color": [rgba.red, rgba.green, rgba.blue, rgba.alpha]]
        setBrushParams(with: brushParams)
    }

    func setup() { setUpBrushCache() }

    func endStickerBrush() { imageEditor.endStickerBrush() }

    func setUpMosaicResourcePack(with currentSliderValue: CGFloat, isGuass: Bool) {
        endStickerBrush()
        imageEditor.setStickerBrushResource(isGuass ?
                                            ImageEditorResourceManager.mosaicGuassResourcePath
                                            : ImageEditorResourceManager.mosaicResourcePath)

        let mosaicParams: [String: Any] = ["brush_size": transformToVELineWidth(currentSliderValue),
                                           "base_resolution": 1,
                                           "brush_size_mode": 1]
        setBrushParams(with: mosaicParams)
        imageEditor.beginStickerBrus(brushID)
    }

    func setUpBrushCache() { brushID = imageEditor.addBrushSticker(ImageEditorResourceManager.cachePath) }

    func changeBrushWidth(with width: CGFloat) {
        let brushParams: [String: Any] = ["brush_size": transformToVELineWidth(width),
                                          "brush_size_mode": 1]
        setBrushParams(with: brushParams)
    }

    func setUpBrushResourcePack(with currentSeletedColor: UIColor, and currentSliderValue: CGFloat) {
        imageEditor.setStickerBrushResource(ImageEditorResourceManager.brushResourcePath)
        imageEditor.beginStickerBrus(brushID)

        let defaultRGBA = currentSeletedColor.rgba
        let brushParams: [String: Any] = ["brush_color": [defaultRGBA.red,
                                                          defaultRGBA.green,
                                                          defaultRGBA.blue,
                                                          defaultRGBA.alpha],
                                          "brush_size": transformToVELineWidth(currentSliderValue),
                                          "base_resolution": 1,
                                          "brush_size_mode": 1]
        setBrushParams(with: brushParams)
    }
}

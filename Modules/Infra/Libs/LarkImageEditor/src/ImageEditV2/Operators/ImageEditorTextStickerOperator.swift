//
//  ImageEditorTextStickerOperator.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/9.
//

import Foundation
import TTVideoEditor
import LarkExtensions
import UIKit

final class ImageEditorTextStickerOperator: ImageEditorOperator {
    private let extendBoarderWidth = CGFloat(40)
    private var pinchBeginScale = CGFloat(1)
    private(set) var currentSelectedStickerBorder: TextStickerBoarderView?
    private var allTextStickerBoarderViews: [TextStickerBoarderView] {
        imageEditor.preview.subviews.reversed().compactMap({ $0 as? TextStickerBoarderView })
    }

    private func updateBoarderView(_ boarderView: TextStickerBoarderView) {
        let stickerSize = imageEditor.getStickerBoxSize(with: boarderView.sticker.id)
        boarderView.bounds.size = .init(width: stickerSize.width + extendBoarderWidth,
                                        height: stickerSize.height + extendBoarderWidth)
        boarderView.center = imageEditor.getStickerCenterOnView(boarderView.sticker)
        boarderView.transform = CGAffineTransform(rotationAngle: boarderView.sticker.angle * .pi / 180)
    }

    private func moveSticker(_ sticker: TextSticker, to point: CGPoint) {
        sticker.center = point
        let (centerNormX, centerNormY) = imageEditor.setAndConvertPostionToSticker(
            id: sticker.id,
            point: sticker.center)
        sticker.centerNormX = centerNormX
        sticker.centerNormY = centerNormY
        delegate?.setRenderFlag()
    }

    // 移动文字贴纸到当前view的中心
    private func moveStickerToCurrentFoucus(_ sticker: TextSticker, currentView: UIView) {
        guard let currentImageScale = delegate?.currentImageScale else { return }
        let center = currentView.convert(currentView.center, to: imageEditor.preview)
        moveSticker(sticker, to: center)
        imageEditor.stickerSetScale(with: Int(sticker.id),
                                    scale: .init(width: 1 / currentImageScale,
                                                 height: 1 / currentImageScale))
    }

    private func adjustStickerPositonIfNeeded(stickerView: TextStickerBoarderView) {
        let sticker = stickerView.sticker
        let currentLayerFrame = imageEditor.currentLayerFrameOnView
        let stickerFrame = stickerView.frame
        let intersection = currentLayerFrame.intersection(stickerFrame)
        let stickerArea = stickerFrame.width * stickerFrame.height
        let intersectionArea = intersection.height * intersection.width

        if intersectionArea / stickerArea < 0.35 {
            let frameCount = 10
            let diff = imageEditor.frameCenterOnFrame - sticker.center
            let deltaX = diff.x / CGFloat(frameCount)
            let deltaY = diff.y / CGFloat(frameCount)
            DispatchQueue.main.asyncWithCount(frameCount, and: 1.0 / 60.0) { [weak self] in
                self?.moveSticker(sticker, to: .init(x: sticker.center.x + deltaX,
                                                     y: sticker.center.y + deltaY))
                self?.updateBoarderView(stickerView)
            }
        }
    }
}

// internal apis
extension ImageEditorTextStickerOperator {
    func setUpTextStickerParams(with editText: ImageEditorText) -> String? {
        let textColorRGBA = editText.textColor.color().rgba
        let shouldShowBackground = (editText.backgroundColor != nil)
        let backgroundColorRGBA = editText.backgroundColor?.color().rgba
        let params: [String: Any] = ["version": 1,
                                     "text": editText.text,
                                     "fontSize": editText.fontSize,
                                     "textColor": [textColorRGBA.red,
                                                   textColorRGBA.green,
                                                   textColorRGBA.blue,
                                                   textColorRGBA.alpha],
                                     "background": shouldShowBackground,
                                     "backgroundRoundCorner": shouldShowBackground,
                                     "backgroundWrapped": shouldShowBackground,
                                     "backgroundRoundRadius": 14,
                                     "backgroundColor": [backgroundColorRGBA?.red ?? 0 as Any,
                                                         backgroundColorRGBA?.green ?? 0 as Any,
                                                         backgroundColorRGBA?.blue ?? 0 as Any,
                                                         backgroundColorRGBA?.alpha ?? 0 as Any],
                                     "innerPadding": 0.35,
                                     "lineGap": 0.5,
                                     "lineMaxWidth": 1]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: params,
                                                         options: JSONSerialization.WritingOptions(rawValue: 0)),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            assertionFailure("sticker params init error")
            return nil
        }

        return jsonString
    }

    func setStickerAlpha(_ alpha: CGFloat, boarder: TextStickerBoarderView?) {
        guard let boarderView = boarder else { return }
        alpha == 0 ? boarderView.hidden() : boarderView.temporaryShow()
        imageEditor.stickerSetAlpha(with: boarderView.sticker.id, alpha: alpha)
        delegate?.setRenderFlag()
    }

    func createNewTextSticker(with editText: ImageEditorText, and jsonString: String,
                              boarderViewDelegate: TextStickerBoarderViewDelegate, currentView: UIView) {
        let stickerID = imageEditor.addTextSticker(jsonString)
        let newSticker = TextSticker(id: stickerID,
                                     editText: editText,
                                     center: imageEditor.frameCenterOnFrame)
        // VE默认加到图片的中心，这里移到scrollview的中心
        moveStickerToCurrentFoucus(newSticker, currentView: currentView)
        let boarderView = TextStickerBoarderView(with: newSticker)
        boarderView.delegate = boarderViewDelegate
        imageEditor.preview.addSubview(boarderView)
        updateBoarderView(boarderView)
        boarderView.temporaryShow()

        delegate?.setRenderFlag()
    }

    func updateTextSticker(with editText: ImageEditorText, of boarderView: TextStickerBoarderView,
                           and jsonString: String) {
        if editText.text.isEmpty {
            imageEditor.removeSticker(with: Int(boarderView.sticker.id))
            boarderView.removeFromSuperview()
            delegate?.setRenderFlag()
        } else {
            imageEditor.updateTextSticker(boarderView.sticker.id, json: jsonString)
            boarderView.sticker.editText = editText
            updateBoarderView(boarderView)
            setStickerAlpha(1, boarder: boarderView)
        }
    }

    func checkPointInStickerArea(_ point: CGPoint) {
        if let borderView = allTextStickerBoarderViews.first(where: { $0.frame.contains(point) }) {
            currentSelectedStickerBorder = borderView
        }
    }

    func removeAllBoarder() { allTextStickerBoarderViews.forEach { $0.removeFromSuperview() } }

    // 重设文字贴纸的位置，由于iPad转屏分屏后贴纸的坐标变了，需要重设
    func resetAllStickers() {
        allTextStickerBoarderViews.forEach {
            $0.sticker.center = imageEditor.getStickerCenterOnFrame($0.sticker)
            updateBoarderView($0)
        }
    }

    func handleStickerPinch(_ pinch: UIPinchGestureRecognizer, in boarderView: TextStickerBoarderView) {
        let currentSticker = boarderView.sticker
        boarderView.show()

        switch pinch.state {
        case .began: pinchBeginScale = pinch.scale
        case .changed:
            let scale = pinch.scale - pinchBeginScale + 1
            let newScale = currentSticker.scale * scale
            guard newScale < 3 && newScale > 1 / 3 else { return }
            imageEditor.stickerSetScale(with: Int(currentSticker.id),
                                        scale: .init(width: scale, height: scale))
            currentSticker.scale *= scale
            pinchBeginScale = pinch.scale
            updateBoarderView(boarderView)
            delegate?.setRenderFlag()
        case .ended, .cancelled, .failed:
            boarderView.temporaryShow()
        case .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleStickerRotation(_ rotation: UIRotationGestureRecognizer, in boarderView: TextStickerBoarderView) {
        let currentSticker = boarderView.sticker
        boarderView.show()

        switch rotation.state {
        case .changed:
            let degree = rotation.rotation * 180 / .pi
            rotation.rotation = 0
            currentSticker.angle += degree
            imageEditor.stickerSetRotation(with: currentSticker.id, rotation: -currentSticker.angle)
            updateBoarderView(boarderView)
            delegate?.setRenderFlag()
        case .ended, .cancelled, .failed:
            boarderView.temporaryShow()
        case .began, .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleStickerPan(_ pan: UIPanGestureRecognizer, inDeleteFrame: Bool) {
        guard let boarderView = currentSelectedStickerBorder else { return }
        let currentPanSticker = boarderView.sticker
        boarderView.show()

        switch pan.state {
        case .changed:
            let translationPoint = pan.translation(in: pan.view)
            pan.setTranslation(.zero, in: pan.view)
            let newCenter = CGPoint(x: currentPanSticker.center.x + translationPoint.x,
                                    y: currentPanSticker.center.y + translationPoint.y)
            moveSticker(currentPanSticker, to: newCenter)
            updateBoarderView(boarderView)
            delegate?.setRenderFlag()
        case .ended, .cancelled, .failed:
            if inDeleteFrame {
                imageEditor.removeSticker(with: Int(currentPanSticker.id))
                boarderView.removeFromSuperview()
            } else {
                adjustStickerPositonIfNeeded(stickerView: boarderView)
                boarderView.temporaryShow()
            }
            delegate?.setRenderFlag()
            currentSelectedStickerBorder = nil
        case .began, .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleStickerTap(in boarderView: TextStickerBoarderView, afterDoubleTap: () -> Void) {
        boarderView.isBoardHidden ? boarderView.temporaryShow() : afterDoubleTap()
        currentSelectedStickerBorder = nil
    }
}

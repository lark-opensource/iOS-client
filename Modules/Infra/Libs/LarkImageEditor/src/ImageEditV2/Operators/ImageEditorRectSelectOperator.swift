//
//  ImageEditorRectSelectOperator.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/11.
//

import UIKit
import Foundation
import TTVideoEditor
import LarkExtensions

final class ImageEditorRectSelectOperator: ImageEditorOperator {
    private let mosaicBoarderView = UIView()
    private var selectBeforePoint = CGPoint()
}

// internal apis
extension ImageEditorRectSelectOperator {
    func setup() {
        mosaicBoarderView.backgroundColor = .clear
        mosaicBoarderView.layer.borderWidth = 2
        mosaicBoarderView.layer.ud.setBorderColor(.ud.N00.withAlphaComponent(0.9))
        imageEditor.preview.addSubview(mosaicBoarderView)
        mosaicBoarderView.frame = .zero
    }

    func handleSelectPanGesture(_ gesture: UIPanGestureRecognizer, currentResourcePath: String,
                                afterEnded: ((Int32) -> Void)? = nil) {
        switch gesture.state {
        case .began:
            selectBeforePoint = gesture.location(in: imageEditor.preview)
        case .changed:
            let point = gesture.location(in: imageEditor.preview)
            mosaicBoarderView.frame = CGRect(x: min(point.x, selectBeforePoint.x), y: min(point.y, selectBeforePoint.y),
                                             width: abs(point.x - selectBeforePoint.x),
                                             height: abs(point.y - selectBeforePoint.y))
        case .ended, .cancelled, .failed:
            mosaicBoarderView.frame = .zero
            let currentSelectingStickerID = imageEditor.addSticker(withPath: currentResourcePath, param: [])
            let point = gesture.location(in: imageEditor.preview)
            let centerInFrame = (point + selectBeforePoint) / 2
            let currentSelectingStickerOriginSize = imageEditor.getStickerBoxSize(with: currentSelectingStickerID)
            _ = imageEditor.setAndConvertPostionToSticker(id: currentSelectingStickerID, point: centerInFrame)
            imageEditor.stickerSetScale(with: Int(currentSelectingStickerID),
                                        scale: .init(width: abs(point.x - selectBeforePoint.x)
                                                        / currentSelectingStickerOriginSize.width,
                                                     height: abs(point.y - selectBeforePoint.y)
                                                        / currentSelectingStickerOriginSize.height))
            delegate?.setRenderFlag()
            afterEnded?(currentSelectingStickerID)
        case .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }
}

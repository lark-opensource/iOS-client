//
//  TextStickerBoarderView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/19.
//

import UIKit
import Foundation

protocol TextStickerBoarderViewDelegate: AnyObject {
    func handleTextStickerPinch(_ pinch: UIPinchGestureRecognizer, in boarderView: TextStickerBoarderView)
    func handleTextStickerRotation(_ rotation: UIRotationGestureRecognizer, in boarderView: TextStickerBoarderView)
}

final class TextStickerBoarderView: StickerBoarderView {
    private(set) var sticker: TextSticker

    weak var delegate: TextStickerBoarderViewDelegate?

    init(with sticker: TextSticker) {
        self.sticker = sticker
        super.init()

        // Gesture
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchRecognizer.delegate = self
        addGestureRecognizer(pinchRecognizer)

        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture))
        rotationRecognizer.delegate = self
        addGestureRecognizer(rotationRecognizer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateSticker(_ sticker: TextSticker) { self.sticker = sticker }

    @objc
    private func handlePinch(_ pinch: UIPinchGestureRecognizer) { delegate?.handleTextStickerPinch(pinch, in: self) }

    @objc
    private func handleRotationGesture(_ rotation: UIRotationGestureRecognizer) {
        delegate?.handleTextStickerRotation(rotation, in: self)
    }
}

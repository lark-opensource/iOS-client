//
//  TagStickerBoarderView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/20.
//

import UIKit
import Foundation

protocol TagStickerBoarderViewDelegate: AnyObject {
    func handleTagStickerPinch(_ pinch: UIPinchGestureRecognizer)
    func handleTagStickerRotation(_ rotation: UIRotationGestureRecognizer)
}

final class TagStickerBoarderView: StickerBoarderView {
    private(set) var tagSticker: TagSticker

    weak var delegate: TagStickerBoarderViewDelegate?

    init(with tagSticker: TagSticker, type: BoarderViewType = .rect) {
        self.tagSticker = tagSticker
        super.init(with: type)

        // Gesture
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchRecognizer.delegate = self
        addGestureRecognizer(pinchRecognizer)

        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture))
        rotationRecognizer.delegate = self
        addGestureRecognizer(rotationRecognizer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc
    private func handlePinch(_ pinch: UIPinchGestureRecognizer) { delegate?.handleTagStickerPinch(pinch) }

    @objc
    private func handleRotationGesture(_ rotation: UIRotationGestureRecognizer) {
        delegate?.handleTagStickerRotation(rotation)
    }
}

//
//  ImageEditorUndoOperator.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/11.
//

import UIKit
import Foundation
import TTVideoEditor

final class ImageEditorUndoOperator: ImageEditorOperator {
    private var brushID = Int32(0)
    private var vectorID = Int32(0)

    private var mosaicStack = [(MosaicGestureType, Int32)]()
    private var tagViewStack = [TagStickerBoarderView]()
}

extension ImageEditorUndoOperator {
    enum UndoType {
        case line(lineCount: Int)
        case mosaic
        case tag
    }
}

// internal apis
extension ImageEditorUndoOperator {
    func setup(currentBrushID: Int32, currentVectorID: Int32) {
        brushID = currentBrushID
        vectorID = currentVectorID
    }

    func undoOnce(with type: UndoType) {
        switch type {
        case .line:
            imageEditor.undoRedoStickerBrush(true, entityIndex: brushID)
        case .mosaic:
            guard let (selectType, stickerID) = mosaicStack.popLast() else { return }
            switch selectType {
            case .smear:
                imageEditor.undoRedoStickerBrush(true, entityIndex: stickerID)
            case .rect:
                imageEditor.removeSticker(with: Int(stickerID))
            }
        case .tag:
            tagViewStack = tagViewStack.filter { $0.superview != nil }
            guard let lastTagView = tagViewStack.last else { return }
            imageEditor.removeVectorGraphics(withId: vectorID, geometryID: lastTagView.tagSticker.id)
            lastTagView.removeFromSuperview()
        }
        imageEditor.renderEffect()
        delegate?.setRenderFlag()
    }

    func undoAll(with type: UndoType) {
        imageEditor.endStickerBrush()
        switch type {
        case .line(let lineCount):
            for _ in 0..<lineCount { imageEditor.undoRedoStickerBrush(true, entityIndex: brushID) }
        case .mosaic:
            for (selectType, stickerID) in mosaicStack {
                switch selectType {
                case .smear:
                    imageEditor.undoRedoStickerBrush(true, entityIndex: stickerID)
                case .rect:
                    imageEditor.removeSticker(with: Int(stickerID))
                }
                imageEditor.removeSticker(with: Int(stickerID))
            }
            mosaicStack.removeAll()
        case .tag:
            tagViewStack = tagViewStack.filter { $0.superview != nil }
            tagViewStack.forEach {
                imageEditor.removeVectorGraphics(withId: vectorID, geometryID: $0.tagSticker.id)
                $0.removeFromSuperview()
            }
        }
        imageEditor.renderEffect()
        delegate?.setRenderFlag()
    }

    func saveMosaicStatus(_ status: (MosaicGestureType, Int32)) { mosaicStack.append(status) }

    func clearStatus() {
        mosaicStack.removeAll()
        tagViewStack.removeAll()
    }

    func saveTagStatus(_ status: TagStickerBoarderView) { tagViewStack.append(status) }
}

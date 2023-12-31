//
//  ImageEditorTagOperator.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/11.
//

import Foundation
import TTVideoEditor
import UIKit
import LarkExtensions
import RustPB

final class ImageEditorTagOperator: ImageEditorOperator {
    private(set) var vectorStickerID = Int32(0)
    private(set) var currentWidth = CGFloat(8)
    private(set) var currentColor = ColorPanelType.default
    private(set) var currentType = TagType.rect

    private var currentSelectedTagView: TagStickerBoarderView?
    private var panBeforePoint = CGPoint()
    private var pinchBeginScale = CGFloat(1)
    private var panTouchType = StickerBoarderView.TouchType.inRect

    private let extendBoarderWidth = CGFloat(8)

    private var allTagsInfo: [[String: Any]]? {
        guard let jsonData = imageEditor.getVectorCurrentGraphics(vectorStickerID).data(using: .utf8)
        else { return nil }
        return try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [[String: Any]]
    }

    private var allTagStickerBoarderViews: [TagStickerBoarderView] {
        imageEditor.preview.subviews.reversed().compactMap({ $0 as? TagStickerBoarderView })
    }

    private var allTagStickers: [TagSticker] { allTagStickerBoarderViews.map { $0.tagSticker } }

    private var lastTagID: String? {
        guard let tagsInfo = allTagsInfo else { return "" }
        return tagsInfo.last?["elementID"] as? String
    }

    private var resourcePackPath: String {
        switch currentType {
        case .rect: return ImageEditorResourceManager.rectVectorResourcePath
        case .circle: return ImageEditorResourceManager.circleVectorResourcePath
        case .arrow: return ImageEditorResourceManager.arrowVectorResourcePath
        }
    }

    private var tagParams: String? {
        switch currentType {
        case .rect: return rectParams
        case .circle: return circleParams
        case .arrow: return arrowParams
        }
    }

    private var rectParams: String? {
        let colorRGBA = currentColor.color().rgba
        let params: [String: Any] = ["rectRadius": 1,
                                     "strokeColor": [colorRGBA.red, colorRGBA.green, colorRGBA.blue, colorRGBA.alpha],
                                     "strokeWidth": currentWidth / imageEditor.imageScale,
                                     "fillColor": [0, 0, 0, 0],
                                     "rotation": 0]

        return dictToJSONString(params)
    }

    private var circleParams: String? {
        let colorRGBA = currentColor.color().rgba
        let params: [String: Any] = ["strokeColor": [colorRGBA.red, colorRGBA.green, colorRGBA.blue, colorRGBA.alpha],
                                     "strokeWidth": currentWidth / imageEditor.imageScale,
                                     "fillColor": [0, 0, 0, 0],
                                     "rotation": 0]

        return dictToJSONString(params)
    }

    private var arrowParams: String? {
        let colorRGBA = currentColor.color().rgba
        let params: [String: Any] = ["tailWidth": 6 / imageEditor.imageScale,
                                     "headWidth": 18 / imageEditor.imageScale,
                                     "arrowLength": 30 / imageEditor.imageScale,
                                     "headLength": 30 / imageEditor.imageScale,
                                     "arrowWidth": 40 / imageEditor.imageScale,
                                     "strokeColor": [colorRGBA.red, colorRGBA.green, colorRGBA.blue, colorRGBA.alpha],
                                     "roundRadius": 4]

        return dictToJSONString(params)
    }

    private func addVector() {
        guard let params = tagParams else { return }
        imageEditor.addVectorGraphics(withParams: vectorStickerID,
                                      path: resourcePackPath,
                                      params: params)
    }

    private func dictToJSONString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict,
                                                         options: JSONSerialization.WritingOptions(rawValue: 0)),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            assertionFailure("vector sticker params init error")
            return nil
        }

        return jsonString
    }

    private func getVectorGraphicsParams(with id: String) -> [String: Any]? {
        guard let jsonData = imageEditor.getVectorGraphicsParams(withId: vectorStickerID,
                                                                 geometryID: id).data(using: .utf8)
        else { return nil }

        return try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any]
    }

    private func getRectParams(with tagParams: [String: Any]) -> (CGPoint, CGSize, CGFloat)? {
        guard let strokeWidth = tagParams["strokeWidth"] as? CGFloat,
              let centerPosition = tagParams["centerPosition"] as? [CGFloat],
              let centerX = centerPosition.first,
              let centerY = centerPosition.last,
              let dimension = tagParams["rectDimension"] as? [CGFloat],
              let width = dimension.first,
              let height = dimension.last else { return nil }

        // VE返回的是图片的像素坐标，转换为我们需要的屏幕坐标
        return (.init(x: centerX, y: centerY) * imageEditor.imageScale,
                .init(width: abs(width), height: abs(height)) * imageEditor.imageScale,
                strokeWidth * imageEditor.imageScale)
    }

    private func getCircleParams(with tagParams: [String: Any]) -> (CGPoint, CGSize, CGFloat)? {
        guard let strokeWidth = tagParams["strokeWidth"] as? CGFloat,
              let centerPosition = tagParams["centerPosition"] as? [CGFloat],
              let centerX = centerPosition.first,
              let centerY = centerPosition.last,
              let dimension = tagParams["ellipseRadius"] as? [CGFloat],
              let width = dimension.first,
              let height = dimension.last else { return nil }

        // VE返回的是图片的像素坐标，转换为我们需要的屏幕坐标
        return (.init(x: centerX, y: centerY) * imageEditor.imageScale,
                .init(width: abs(width * 2), height: abs(height * 2)) * imageEditor.imageScale,
                strokeWidth * imageEditor.imageScale)
    }

    private func getArrowParams(with tagParams: [String: Any]) -> (CGPoint, CGPoint, CGFloat)? {
        guard let startPosition = tagParams["startPosition"] as? [CGFloat],
              let startX = startPosition.first,
              let startY = startPosition.last,
              let endPosition = tagParams["endPosition"] as? [CGFloat],
              let endX = endPosition.first,
              let endY = endPosition.last,
              let arrowWidth = tagParams["arrowWidth"] as? CGFloat
        else { return nil }

        // VE返回的是图片的像素坐标，转换为我们需要的屏幕坐标
        return (.init(x: startX, y: startY) * imageEditor.imageScale,
                .init(x: endX, y: endY) * imageEditor.imageScale, arrowWidth)
    }

    private func setupBoarderViewForRectOrCircle(isRect: Bool) {
        guard let lastID = lastTagID,
              let lastTagInfo = getVectorGraphicsParams(with: lastID) else { return }

        let (tagCenter, tagSize, tagStrokeWidth): (CGPoint, CGSize, CGFloat)
        if isRect {
            guard let (center, size, strokeWidth) = getRectParams(with: lastTagInfo) else { return }
            (tagCenter, tagSize, tagStrokeWidth) = (center, size, strokeWidth)
        } else {
            guard let (center, size, strokeWidth) = getCircleParams(with: lastTagInfo) else { return }
            (tagCenter, tagSize, tagStrokeWidth) = (center, size, strokeWidth)
        }

        setupBoarderView(with: lastID, and: isRect ? .rect : .circle, center: tagCenter,
                         size: tagSize, strokeWidth: tagStrokeWidth)
    }

    private func setupBoarderViewForArrow() {
        guard let currentImageScale = delegate?.currentImageScale,
              let lastID = lastTagID,
              let lastTagInfo = getVectorGraphicsParams(with: lastID),
              let (startPosition, endPosition, arrowWidth) = getArrowParams(with: lastTagInfo)
        else { return }

        let tagCenter = (startPosition + endPosition) / 2
        // 高度应该综合箭头的宽度和箭头的高度考虑
        let tagSize = CGSize(width: abs(endPosition.x - startPosition.x),
                             height: max(abs(endPosition.y - startPosition.y),
                                         arrowWidth * imageEditor.imageScale * currentImageScale))
        setupBoarderView(with: lastID, and: .arrow, center: tagCenter, size: tagSize, strokeWidth: 0)
    }

    private func setupBoarderView(with id: String, and type: TagType, center: CGPoint,
                                  size: CGSize, strokeWidth: CGFloat) {
        let tagSticker = TagSticker(id: id, type: type, center: center, size: size, color: currentColor,
                                    width: strokeWidth)
        let tagBoarderView = TagStickerBoarderView(with: tagSticker, type: type == .arrow ? .line : .rect)
        tagBoarderView.hidden()
        imageEditor.preview.addSubview(tagBoarderView)
        updateBoarderView(tagBoarderView)
    }

    private func setupBoarderViewForLastTag(delegate: TagStickerBoarderViewDelegate) {
        switch currentType {
        case .rect: setupBoarderViewForRectOrCircle(isRect: true)
        case .circle: setupBoarderViewForRectOrCircle(isRect: false)
        case .arrow: setupBoarderViewForArrow()
        }

        lastTag?.delegate = delegate
    }

    private func updateBoarderView(_ boarderView: TagStickerBoarderView) {
        guard let currentImageScale = delegate?.currentImageScale else { return }

        switch boarderView.tagSticker.type {
        case .circle, .rect:
            let offset = extendBoarderWidth + 8 + boarderView.tagSticker.width * (currentImageScale - 1)
            boarderView.bounds.size = .init(width: boarderView.tagSticker.size.width + offset,
                                            height: boarderView.tagSticker.size.height + offset)
            boarderView.center = boarderView.tagSticker.center
            boarderView.transform = CGAffineTransform(rotationAngle: boarderView.tagSticker.angle * .pi / 180)
        case .arrow:
            guard let lastTagInfo = getVectorGraphicsParams(with: boarderView.tagSticker.id),
                  let (startPosition, endPosition, arrowWidth) = getArrowParams(with: lastTagInfo)
            else { return }

            let tagSize = CGSize(width: abs(endPosition.x - startPosition.x),
                                 height: max(abs(endPosition.y - startPosition.y),
                                             arrowWidth * imageEditor.imageScale * currentImageScale))

            boarderView.frame.size = CGSize(width: tagSize.width + extendBoarderWidth,
                                            height: tagSize.height + extendBoarderWidth)
            boarderView.center = boarderView.tagSticker.center
            boarderView.updateLine(startPosition: imageEditor.preview.convert(startPosition, to: boarderView),
                                   endPosition: imageEditor.preview.convert(endPosition, to: boarderView))
        }
    }

    private func updateAllBoarderViews() { allTagStickerBoarderViews.forEach { updateBoarderView($0) } }

    private func updateTagParams(with tagID: String, and jsonString: String) {
        imageEditor.updateVectorGraphicsParams(withId: vectorStickerID, geometryID: tagID, geometryParams: jsonString,
                                               isMilestone: false)
        imageEditor.renderEffect()
        delegate?.setRenderFlag()
    }

    private func updateTagWidth(_ width: CGFloat) {
        guard let tag = currentSelectedTagView?.tagSticker,
              let jsonString = dictToJSONString(["strokeWidth": width / imageEditor.imageScale]) else { return }

        tag.width = width
        updateTagParams(with: tag.id, and: jsonString)
    }

    private func updateTagColor(_ color: ColorPanelType) {
        let colorRGBA = color.color().rgba
        guard let tag = currentSelectedTagView?.tagSticker,
              let jsonString = dictToJSONString(
                ["strokeColor": [colorRGBA.red, colorRGBA.green, colorRGBA.blue, colorRGBA.alpha]])
        else { return }

        tag.color = color
        updateTagParams(with: tag.id, and: jsonString)
    }

    private func moveTag(_ tagView: TagStickerBoarderView, diff point: CGPoint,
                         touchType: StickerBoarderView.TouchType) {
        let tag = tagView.tagSticker
        let params: [String: Any]
        switch tag.type {
        case .rect, .circle:
            let newCenter = CGPoint(x: tag.center.x + point.x, y: tag.center.y + point.y)
            let pointInImage = newCenter / imageEditor.imageScale
            tag.center = newCenter
            params = ["centerPosition": [pointInImage.x, pointInImage.y]]
        case .arrow:
            guard let arrowInfo = getVectorGraphicsParams(with: tag.id),
                  let startPosition = arrowInfo["startPosition"] as? [CGFloat],
                  let startX = startPosition.first,
                  let startY = startPosition.last,
                  let endPosition = arrowInfo["endPosition"] as? [CGFloat],
                  let endX = endPosition.first,
                  let endY = endPosition.last else { return }

            let diffInImage = point / imageEditor.imageScale
            switch touchType {
            case .inLineHead:
                let targetEndPosition = CGPoint(x: endX + diffInImage.x, y: endY + diffInImage.y)
                params = ["endPosition": [targetEndPosition.x, targetEndPosition.y]]
                tag.center = (CGPoint(x: startX, y: startY) + targetEndPosition) / 2 * imageEditor.imageScale
            case .inLineTail:
                let targetStartPosition = CGPoint(x: startX + diffInImage.x, y: startY + diffInImage.y)
                params = ["startPosition": [targetStartPosition.x, targetStartPosition.y]]
                tag.center = (targetStartPosition + CGPoint(x: endX, y: endY)) / 2 * imageEditor.imageScale
            case .inRect:
                params = ["startPosition": [startX + diffInImage.x, startY + diffInImage.y],
                          "endPosition": [endX + diffInImage.x, endY + diffInImage.y]]
                tag.center = CGPoint(x: tag.center.x + point.x, y: tag.center.y + point.y)
            }
        }

        guard let jsonString = dictToJSONString(params) else { return }
        updateTagParams(with: tag.id, and: jsonString)
    }

    private func rotateTag(_ tagID: String, with degree: CGFloat) {
        guard let jsonString = dictToJSONString(["rotation": degree]) else { return }

        updateTagParams(with: tagID, and: jsonString)
    }

    private func scaleTag(_ tagID: String, with scale: CGFloat, type: TagType) {
        guard let tagParams = getVectorGraphicsParams(with: tagID) else { return }

        let params: [String: Any]
        switch type {
        case .rect, .circle:
            let dimensionString = (type == .rect ? "rectDimension" : "ellipseRadius")
            guard let dimension = tagParams[dimensionString] as? [CGFloat],
                  let width = dimension.first,
                  let height = dimension.last else { return }

            params = [dimensionString: [width * scale, height * scale]]
        case .arrow: params = [:]
        }

        guard let jsonString = dictToJSONString(params) else { return }
        updateTagParams(with: tagID, and: jsonString)
    }

    private func adjustStickerPositonIfNeeded(stickerView: TagStickerBoarderView) {
        let sticker = stickerView.tagSticker
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
                self?.moveTag(stickerView, diff: .init(x: deltaX, y: deltaY), touchType: .inRect)
                self?.updateBoarderView(stickerView)
            }
        }
    }
}

// internal apis
extension ImageEditorTagOperator {

    var lastTag: TagStickerBoarderView? { allTagStickerBoarderViews.first(where: { $0.tagSticker.id == lastTagID }) }

    var inSelected: Bool { currentSelectedTagView != nil }

    func setup() {
        vectorStickerID = imageEditor.addVectorSticker(ImageEditorResourceManager.vectorGraphicsStickerResourcePath)
    }

    func handleAddPan(_ pan: UIPanGestureRecognizer, boarderViewDelegate: TagStickerBoarderViewDelegate,
                      afterEnded: (() -> Void)? = nil) {
        guard !inSelected else { return }
        let tapPoint = pan.location(in: pan.view)
        var point = pan.translation(in: pan.view)

        switch pan.state {
        case .began:
            panBeforePoint = .zero
            addVector()
            imageEditor.processGesture(withPath: resourcePackPath,
                                       commandID: VECTOR_BRUSH,
                                        type: TEIMAGE_GT_TOUCH_DOWN,
                                       point: tapPoint,
                                       offset: .zero,
                                       factor: 1,
                                       etc: 2)
        case .ended, .cancelled, .failed:
            imageEditor.processGesture(withPath: resourcePackPath,
                                       commandID: VECTOR_BRUSH,
                                       type: TEIMAGE_GT_TOUCH_UP,
                                       point: tapPoint,
                                       offset: .zero,
                                       factor: 0,
                                       etc: 2)
            panBeforePoint = .zero
            setupBoarderViewForLastTag(delegate: boarderViewDelegate)
            afterEnded?()
        case .changed:
            point.y *= -1
            let translate = CGPoint(x: point.x - panBeforePoint.x, y: panBeforePoint.y - point.y)
            panBeforePoint = point
            imageEditor.processGesture(withPath: resourcePackPath,
                                       commandID: VECTOR_BRUSH,
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

    func changeWidth(with width: CGFloat) { inSelected ? updateTagWidth(width) : (currentWidth = width) }

    func changeColor(with color: ColorPanelType) { inSelected ? updateTagColor(color) : (currentColor = color) }

    func selectTagIfNeeded(with tapPoint: CGPoint) {
        if let selectedTag = allTagStickerBoarderViews.first(where: { $0.frame.contains(tapPoint) }) {
            currentSelectedTagView = selectedTag
        }
    }

    func pointInCurrentTag(with tapPoint: CGPoint) -> Bool { currentSelectedTagView?.frame.contains(tapPoint) ?? false }

    func handleTagTap(afterTap: (TagType, CGFloat, ColorPanelType) -> Void) {
        guard let tagView = currentSelectedTagView else { return }
        allTagStickerBoarderViews.forEach { $0.hidden() }
        tagView.show()

        afterTap(tagView.tagSticker.type, tagView.tagSticker.width, tagView.tagSticker.color)
    }

    func removeAllBoarder() { allTagStickerBoarderViews.forEach { $0.removeFromSuperview() } }

    func updateAllTags(with scale: CGFloat) {
        allTagStickers.forEach {
            $0.center *= scale
            $0.size *= scale
        }
        updateAllBoarderViews()
    }

    func cancelSelected() {
        allTagStickerBoarderViews.forEach { $0.hidden() }
        currentSelectedTagView = nil
    }

    func handleSelectedPan(_ pan: UIPanGestureRecognizer, inDeleteFrame: Bool) {
        guard let boarderView = currentSelectedTagView else { return }
        boarderView.show()

        switch pan.state {
        case .began: panTouchType = boarderView.checkPointInView(pan.location(in: boarderView))
        case .changed:
            let translationPoint = pan.translation(in: pan.view)
            pan.setTranslation(.zero, in: pan.view)
            moveTag(boarderView, diff: translationPoint, touchType: panTouchType)
            updateBoarderView(boarderView)
            delegate?.setRenderFlag()
        case .ended, .cancelled, .failed:
            if inDeleteFrame {
                imageEditor.removeVectorGraphics(withId: vectorStickerID,
                                                 geometryID: boarderView.tagSticker.id)
                boarderView.removeFromSuperview()
                currentSelectedTagView = nil
                imageEditor.renderEffect()
            } else { adjustStickerPositonIfNeeded(stickerView: boarderView) }
            delegate?.setRenderFlag()
        case .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleSelectedRotation(_ rotation: UIRotationGestureRecognizer) {
        guard let currentStickerView = currentSelectedTagView,
              currentStickerView.tagSticker.type == .rect || currentStickerView.tagSticker.type == .circle
        else { return }

        let currentSticker = currentStickerView.tagSticker
        switch rotation.state {
        case .changed:
            let degree = rotation.rotation * 180 / .pi
            rotation.rotation = 0
            currentSticker.angle += degree
            rotateTag(currentSticker.id, with: currentSticker.angle)
            updateBoarderView(currentStickerView)
        case .ended, .cancelled, .failed, .began, .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleSelectedPinch(_ pinch: UIPinchGestureRecognizer) {
        guard let boarderView = currentSelectedTagView,
              boarderView.tagSticker.type == .rect || boarderView.tagSticker.type == .circle else { return }

        let currentSticker = boarderView.tagSticker
        switch pinch.state {
        case .began: pinchBeginScale = pinch.scale
        case .changed:
            let scale = pinch.scale - pinchBeginScale + 1
            let newScale = currentSticker.scale * scale
            guard newScale < 3 && newScale > 1 / 3 else { return }
            scaleTag(currentSticker.id, with: scale, type: currentSticker.type)
            currentSticker.scale *= scale
            currentSticker.size *= scale
            pinchBeginScale = pinch.scale
            updateBoarderView(boarderView)
            delegate?.setRenderFlag()
        case .ended, .cancelled, .failed, .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func resetTagCenter() {
        allTagStickerBoarderViews.forEach {
            guard let info = getVectorGraphicsParams(with: $0.tagSticker.id) else { return }

            switch $0.tagSticker.type {
            case .rect:
                guard let (tagCenter, _, _) = getRectParams(with: info) else { return }
                $0.tagSticker.center = tagCenter
            case .circle:
                guard let (tagCenter, _, _) = getCircleParams(with: info) else { return }
                $0.tagSticker.center = tagCenter
            case .arrow:
                guard let (startPosition, endPosition, _) = getArrowParams(with: info) else { return }
                $0.tagSticker.center = (startPosition + endPosition) / 2
            }
            updateBoarderView($0)
        }
    }

    func setVectorEnable(_ enable: Bool) {
        imageEditor.setVectorGraphicsBrushEnable(vectorStickerID, enable: enable)
        if !enable { cancelSelected() }
    }

    func updateCurrentType(with type: TagType) { currentType = type }
}

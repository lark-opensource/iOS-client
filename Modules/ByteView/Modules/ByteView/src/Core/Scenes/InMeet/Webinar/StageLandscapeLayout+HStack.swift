// nolint: magic_number

import ByteViewNetwork

extension CGRect {
    func horizontalFliped(centerX: CGFloat) -> CGRect {
        CGRect(
            origin: CGPoint(
                x: centerX + centerX - self.origin.x - self.size.width,
                y: self.origin.y
            ),
            size: self.size
        )
    }
}

private struct SolveResult {
    var shareWidth: CGFloat
    var shareHeight: CGFloat
    // guestContentHeight: guestHeight * guestCount + spacing * (guestCount - 1)
    // 默认情况下 shareHeight == guestContentHeight, 当 shareWidth/shareHeight >= 2.0 && guestWidth < safeAreaWidth / 6,
    // guestWidth 使用固定宽度
    var guestContentHeight: CGFloat
    var guestWidth: CGFloat
    var guestHeight: CGFloat
}

func computeLinearLayout(
    layoutArea: CGRect,
    ratio: CGFloat,
    spacing: CGFloat,
    count: Int
) -> [CGRect] {
    guard count > 0 else {
        return []
    }
    guard ratio > 0 else {
        return (0..<count).map { _ in CGRect.zero }
    }
    // fitWidth
    var elementWidth = layoutArea.width
    var elementHeight = elementWidth / ratio
    if elementHeight * CGFloat(count) + spacing * CGFloat(count - 1) > layoutArea.height {
        elementHeight = max((layoutArea.height - spacing * CGFloat(count - 1)) / CGFloat(count), 0)
        elementWidth = elementHeight * ratio
    }
    let offsetX = layoutArea.origin.x + (layoutArea.width - elementWidth) * 0.5
    let offsetY =
        layoutArea.origin.y
        + (layoutArea.height - elementHeight * CGFloat(count) - spacing * CGFloat(count - 1)) * 0.5
    return (0..<count).map { idx in
        CGRect(
            x: offsetX,
            y: offsetY + CGFloat(idx) * (spacing + elementHeight),
            width: elementWidth,
            height: elementHeight
        )
    }
}

private func solveFitWidth(
    safeAreaRect: CGRect,
    spacing: CGFloat,
    guestCount: CGFloat,
    shareRatio: CGFloat
) -> SolveResult {
    // fitWidth
    //
    // - shareWidth + spacing + guestWidth = safeAreaWidth
    // - shareHeight = guestHeight * n + spacing * (n - 1)
    // - shareWidth = shareHeight * shareRatio
    // - guestWidth * 9 / 16 = guestHeight
    // - shareHeight <= safeAreaHeight

    // guestHeight = 1/n * shareHeight - (n - 1)/n * spacing
    // guestWidth = guestHeight * 16/9 = 16/9n * shareHeight - (16n - 16)/9n * spacing

    // shareWidth + spacing + 16/9n * shareHeight - 16(n - 1)/9n * spacing = safeAreaWidth
    // shareWidth + spacing + 16/9n * 1/shareRatio * shareWidth - (16n - 16)/9n * spacing = safeAreaWidth
    // (1 + 16/(9n * shareRatio)) * shareWidth = safeAreaWidth + (7n - 16)/9n * spacing

    let shareWidth = ceil(max((safeAreaRect.width + (7 * guestCount - 16) / (9 * guestCount) * spacing) / (1 + 16 / (9 * guestCount * shareRatio)), 0))
    let shareHeight = ceil(shareWidth / shareRatio)
    let guestWidth = max(safeAreaRect.width - spacing - shareWidth, 0)
    let guestHeight = ceil(guestWidth * 9 / 16)
    return SolveResult(
        shareWidth: shareWidth,
        shareHeight: shareHeight,
        guestContentHeight: shareHeight,
        guestWidth: guestWidth,
        guestHeight: guestHeight
    )
}

private func solveFitHeight(
    safeAreaRect: CGRect,
    spacing: CGFloat,
    guestCount: CGFloat,
    shareRatio: CGFloat
) -> SolveResult {
    let shareHeight = safeAreaRect.height
    let shareWidth = ceil(shareHeight * shareRatio)
    let guestHeight = ceil(max((safeAreaRect.height - (guestCount - 1) * spacing) / guestCount, 0))
    let guestWidth = ceil(guestHeight * 16 / 9)
    return SolveResult(
        shareWidth: shareWidth,
        shareHeight: shareHeight,
        guestContentHeight: shareHeight,
        guestWidth: guestWidth,
        guestHeight: guestHeight
    )
}

private func solveFixedGuestWidthShare(
    safeAreaRect: CGRect,
    spacing: CGFloat,
    guestCount: CGFloat,
    shareRatio: CGFloat
) -> SolveResult {
    let guestWidth = ceil(safeAreaRect.width / 6)
    let guestHeight = ceil(guestWidth * 9 / 16)
    let shareWidth = max(safeAreaRect.width - spacing - guestWidth, 0)
    let shareHeight = ceil(shareWidth / shareRatio)
    return SolveResult(
        shareWidth: shareWidth,
        shareHeight: shareHeight,
        guestContentHeight: guestHeight * guestCount + spacing * (guestCount - 1),
        guestWidth: guestWidth,
        guestHeight: guestHeight
    )
}

extension WebinarStageMobileLandscapeLayout {
    func computeSpacing(hasShareContent: Bool, guestCount: Int) -> CGFloat {
        guard guestCount > 0 else {
            return 0
        }
        let spacing: CGFloat

        if isPhone {
            spacing = hasShareContent ? 6.0 : 8.0
        } else {
            spacing = 8.0
        }
        return spacing
    }

    private func computeHStackDraggedShareRects(
        guestCount: Int,
        draggedLayoutInfo: WebinarStageInfo.DraggedLayoutInfo
    ) -> (CGRect, [CGRect]) {
        assert(guestCount > 0)
        assert(draggedLayoutInfo.guestLayoutColumn.count >= guestCount)
        let columnCount = Int(draggedLayoutInfo.guestLayoutColumn[guestCount - 1])
        let spacing = computeSpacing(hasShareContent: true, guestCount: guestCount)
        let guestAreaWidth = stageArea.width * draggedLayoutInfo.guestAreaRatio

        var guestRects = layoutStageGrid(
            layoutArea: CGRect(
                origin: .zero,
                size: CGSize(width: guestAreaWidth, height: stageSafeArea.height)
            ),
            ratio: CGFloat(draggedLayoutInfo.guestItemRatio),
            pinRatio: true,
            spacing: spacing,
            columnCount: Int(columnCount),
            guestCount: guestCount
        )
        let shareSize: CGSize
        if stageSafeArea.height * shareRatio <= stageSafeArea.width - spacing - guestAreaWidth {
            shareSize = CGSize(width: stageSafeArea.height * shareRatio, height: stageSafeArea.height)
        } else {
            shareSize = CGSize(
                width: max(stageSafeArea.width - spacing - guestAreaWidth, 0),
                height: max((stageSafeArea.width - spacing - guestAreaWidth) / shareRatio, 0)
            )
        }

        let shareRect = CGRect(
            x: (stageSafeArea.width - shareSize.width - guestAreaWidth - spacing) * 0.5 + stageSafeArea.origin.x,
            y: (stageSafeArea.height - shareSize.height) * 0.5 + stageSafeArea.origin.y,
            width: shareSize.width,
            height: shareSize.height
        ).integral
        let offsetX = shareRect.maxX + spacing
        let offsetY = stageSafeArea.origin.y
        guestRects = guestRects.map { rect in
            return CGRect(
                x: rect.origin.x + offsetX,
                y: rect.origin.y + offsetY,
                width: rect.width,
                height: rect.height
            )
        }

        return (shareRect, guestRects)
    }

    private func computeHStackShareRects(guestCount: Int) -> (CGRect, [CGRect]) {
        var shareRect: CGRect
        var guestRects = [CGRect]()
        guestRects.reserveCapacity(guestCount)

        let spacing = computeSpacing(hasShareContent: true, guestCount: guestCount)
        var solveResult: SolveResult

        var shareWidth: CGFloat
        var shareHeight: CGFloat

        var guestWidth: CGFloat
        var guestHeight: CGFloat

        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        if guestCount <= 2 {
            solveResult = solveFitWidth(
                safeAreaRect: stageSafeArea,
                spacing: spacing,
                guestCount: 2,
                shareRatio: shareRatio
            )
            if solveResult.shareHeight > stageSafeArea.height {
                solveResult = solveFitHeight(
                    safeAreaRect: stageSafeArea,
                    spacing: spacing,
                    guestCount: 2,
                    shareRatio: shareRatio
                )
            }
        } else {
            solveResult = solveFitHeight(
                safeAreaRect: stageSafeArea,
                spacing: spacing,
                guestCount: 4,
                shareRatio: shareRatio
            )
            if solveResult.shareWidth + spacing + solveResult.guestWidth > stageSafeArea.width {
                solveResult = solveFitWidth(
                    safeAreaRect: stageSafeArea,
                    spacing: spacing,
                    guestCount: 4,
                    shareRatio: shareRatio
                )
            }
        }
        if solveResult.guestWidth < stageSafeArea.width / 6.0 {
            solveResult = solveFixedGuestWidthShare(
                safeAreaRect: stageSafeArea,
                spacing: spacing,
                guestCount: guestCount <= 2 ? 2 : 4,
                shareRatio: shareRatio
            )
        }
        shareWidth = solveResult.shareWidth
        shareHeight = solveResult.shareHeight
        guestWidth = solveResult.guestWidth
        guestHeight = solveResult.guestHeight
        if showFullVideoFrame {
            guestHeight = guestWidth * 9.0 / 16.0
        } else {
            guestHeight =
                (solveResult.guestContentHeight - spacing * CGFloat(guestCount - 1))
                / CGFloat(guestCount)
        }
        shareRect = CGRect(
            origin: CGPoint(
                x: stageSafeArea.midX - (shareWidth + spacing + guestWidth) * 0.5,
                y: stageSafeArea.midY - shareHeight * 0.5
            ),
            size: CGSize(width: shareWidth, height: shareHeight)
        ).integral
        offsetX = shareRect.maxX + spacing
        offsetY = shareRect.midY - (CGFloat(guestCount) * guestHeight + CGFloat(guestCount - 1) * spacing) * 0.5

        for _ in 0..<guestCount {
            guestRects.append(
                CGRect(
                    origin: CGPoint(x: offsetX, y: offsetY),
                    size: CGSize(width: guestWidth, height: guestHeight)
                )
            )
            offsetY += guestHeight + spacing
        }
        return (shareRect, guestRects)
    }

    func computeHStackShareLayouts(
        guestCount: Int,
        draggedLayoutInfo: WebinarStageInfo.DraggedLayoutInfo?,
        sharePositionIsLeft: Bool
    ) -> (StageAreaInfo, [StageAreaInfo]) {
        assert(guestCount > 0)
        var shareArea: CGRect
        var guestAreas = [CGRect]()
        if let draggedLayoutInfo,
            draggedLayoutInfo.guestAreaRatio > 0,
            draggedLayoutInfo.guestLayoutColumn.count >= guestCount {
            (shareArea, guestAreas) = computeHStackDraggedShareRects(guestCount: guestCount,
                                                                     draggedLayoutInfo: draggedLayoutInfo)
        } else {
            (shareArea, guestAreas) = computeHStackShareRects(
                guestCount: guestCount
            )
        }

        let centerX = self.stageSafeArea.center.x
        if !sharePositionIsLeft {
            shareArea = shareArea.horizontalFliped(centerX: centerX)
            guestAreas = guestAreas.map({ $0.horizontalFliped(centerX: centerX) })
        }
        let guestRenderMode: ByteViewRenderMode
        if self.showFullVideoFrame {
            guestRenderMode = .renderModeFit
        } else {
            guestRenderMode = .renderModeFill16x9
        }
        let guestAreaInfos = guestAreas.map { rect in
            StageAreaInfo(rect: rect, renderMode: guestRenderMode)
        }

        return (StageAreaInfo(rect: shareArea, renderMode: .renderModeFit), guestAreaInfos)
    }
}

// nolint: magic_number

extension WebinarStageMobileLandscapeLayout {
    func computeFloatingShareLayout(
        shareRatio: CGFloat,
        stageArea: CGRect,
        guestCount: Int,
        isTopLayout: Bool
    ) -> (StageAreaInfo, [StageAreaInfo]) {
        let shareArea: CGRect
        if stageArea.width > stageArea.height * shareRatio {
            let height = stageArea.height
            let width = height * shareRatio
            shareArea = CGRect(x: stageArea.origin.x + (stageArea.width - width) * 0.5,
                               y: stageArea.origin.y,
                               width: width,
                               height: height).integral
        } else {
            let width = stageArea.width
            let height = width / shareRatio
            shareArea = CGRect(x: stageArea.origin.x,
                               y: stageArea.origin.y + (stageArea.height - height) * 0.5,
                               width: width,
                               height: height).integral
        }

        var guestWidth: CGFloat
        var guestHeight: CGFloat
        if shareRatio >= 16.0/9.0 {
            guestWidth = shareArea.width * 0.18
            guestHeight = guestWidth * 9.0 / 16.0
        } else {
            guestHeight = shareArea.height * 0.18
            guestWidth = guestHeight * 16.0 / 9.0
        }
        if guestCount > 0 {
            if !isTopLayout && guestWidth * CGFloat(guestCount) + 8.0 * 2 > stageArea.width {
                guestWidth = (stageArea.width - 8.0 * 2) / CGFloat(guestCount)
                guestHeight = guestWidth * 9.0 / 16.0
            } else if isTopLayout && guestHeight * CGFloat(guestCount) + 8.0 * 2 > stageArea.height {
                guestHeight = (stageArea.height - 8.0 * 2) / CGFloat(guestCount)
                guestWidth = guestHeight * 16.0 / 9.0
            }
        }
        guestWidth = floor(guestWidth)
        guestHeight = floor(guestHeight)
        let guestSize = CGSize(width: guestWidth, height: guestHeight)

        let vMargin: CGFloat = 8.0
        let hMargin: CGFloat = 8.0

        let originX: CGFloat
        let originY: CGFloat
        let deltaX: CGFloat
        let deltaY: CGFloat

        if isTopLayout {
            deltaX = 0.0
            deltaY = guestHeight
            let totalHeight = guestHeight * CGFloat(guestCount)
            originX = shareArea.maxX - hMargin - guestWidth
            if totalHeight + vMargin <= shareArea.height {
                originY = shareArea.minY + vMargin
            } else {
                originY = floor(shareArea.midY - totalHeight * 0.5)
            }
        } else {
            let totalWidth = guestWidth * CGFloat(guestCount)
            deltaX = guestWidth
            deltaY = 0.0
            if totalWidth + hMargin <= shareArea.width {
                originX = shareArea.maxX - totalWidth - hMargin
            } else {
                originX = floor(shareArea.midX - totalWidth * 0.5)
            }
            originY = shareArea.maxY - guestHeight - vMargin
        }
        let guestAreaInfos = (0..<guestCount).map { idx in
            StageAreaInfo(
                rect: CGRect(
                    origin: CGPoint(
                        x: originX + CGFloat(idx) * deltaX, y: originY + CGFloat(idx) * deltaY),
                    size: guestSize),
                renderMode: .renderModeFit)
        }
        return (StageAreaInfo(rect: shareArea, renderMode: .renderModeFit), guestAreaInfos)
    }
}

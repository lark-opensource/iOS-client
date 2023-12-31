// nolint: magic_number

import UIKit
import ByteViewNetwork

struct WebinarStageMobilePortraitLayout: StageLayout {
    let stageSafeArea: CGRect
    let showFullVideoFrame: Bool

    init(stageSafeArea: CGRect, showFullVideoFrame: Bool) {
        self.stageSafeArea = stageSafeArea
        self.showFullVideoFrame = showFullVideoFrame
    }

    func computeShareLayouts(guestCount: Int,
                             draggedLayoutInfo: WebinarStageInfo.DraggedLayoutInfo?,
                             sharePosition: StageSharePosition) -> (StageAreaInfo, [StageAreaInfo]) {
        let spacing: CGFloat = 7.0
        let horizontalPadding = spacing
        let topPadding: CGFloat = 4.0
        let bottomPadding: CGFloat = 7.0

        let shareArea: CGRect

        let shareWidth = self.stageSafeArea.width - 2.0 * horizontalPadding
        let shareHeight = ceil(shareWidth * 9.0 / 16.0)
        var guestAreas = [CGRect]()
        guestAreas.reserveCapacity(guestCount)
        let guestRatio: CGFloat
        if showFullVideoFrame {
            guestRatio = 16.0 / 9.0
        } else {
            if guestCount == 1 {
                guestRatio = 1.25 / 1.0
            } else if guestCount == 2 || guestCount == 4 {
                guestRatio = 16.0 / 9.0
            } else {
                guestRatio = 1.0
            }
        }

        let guestRowCount = guestCount >= 2 ? 2 : 1
        let guestColCount = guestCount >= 3 ? 2 : 1

        var guestWidth: CGFloat = ceil((self.stageSafeArea.width - horizontalPadding * 2.0 - CGFloat(guestColCount - 1) * spacing) / CGFloat(guestColCount))
        var guestHeight: CGFloat = ceil(guestWidth / guestRatio)

        let fillHeight = shareHeight + topPadding + bottomPadding + CGFloat(guestRowCount) * (spacing + guestHeight) > self.stageSafeArea.height
        if fillHeight {
            guestHeight = ceil((self.stageSafeArea.height - topPadding - bottomPadding - shareHeight) / CGFloat(guestRowCount) - spacing)
            if guestRatio == 1.0 && guestWidth <= guestHeight * 1.2 {
                // 1:1 下，视频允许变形到 1.2 : 1
            } else {
                guestWidth = ceil(guestHeight * guestRatio)
            }
        }

        var offsetX = floor((self.stageSafeArea.width - shareWidth) * 0.5 + stageSafeArea.origin.x)
        var offsetY: CGFloat
        if guestCount <= 2 {
            offsetY = floor(self.stageSafeArea.origin.y + (self.stageSafeArea.height - (spacing + guestHeight) * CGFloat(guestCount) - shareHeight) * 0.5)
            shareArea = CGRect(origin: CGPoint(x: offsetX, y: offsetY), size: CGSize(width: shareWidth, height: shareHeight))
            offsetY += shareHeight + spacing
            offsetX = (self.stageSafeArea.width - guestWidth) * 0.5 + self.stageSafeArea.origin.x
            if guestCount == 1 {
                guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                         size: CGSize(width: guestWidth, height: guestHeight)))
            } else if guestCount == 2 {
                guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                         size: CGSize(width: guestWidth, height: guestHeight)))
                offsetY += spacing + guestHeight
                guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                         size: CGSize(width: guestWidth, height: guestHeight)))
            }
        } else {
            offsetY = floor(fillHeight ? self.stageSafeArea.minY + topPadding : self.stageSafeArea.origin.y + (self.stageSafeArea.height - 2.0 * spacing - shareHeight - 2.0 * guestHeight) * 0.5)
            shareArea = CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                               size: CGSize(width: shareWidth, height: shareHeight))

            offsetY += shareHeight + spacing
            offsetX = self.stageSafeArea.origin.x + (self.stageSafeArea.width - spacing - guestWidth * 2.0) * 0.5
            guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                     size: CGSize(width: guestWidth, height: guestHeight)))
            offsetX += spacing + guestWidth
            guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                     size: CGSize(width: guestWidth, height: guestHeight)))

            offsetY += guestHeight + spacing
            if guestCount == 3 {
                offsetX = (self.stageSafeArea.width - guestWidth) * 0.5 + self.stageSafeArea.origin.x
                guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                         size: CGSize(width: guestWidth, height: guestHeight)))
            } else {
                offsetX = self.stageSafeArea.origin.x + (self.stageSafeArea.width - spacing - guestWidth * 2.0) * 0.5
                guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                         size: CGSize(width: guestWidth, height: guestHeight)))
                offsetX += spacing + guestWidth
                guestAreas.append(CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                         size: CGSize(width: guestWidth, height: guestHeight)))
            }
        }
        let renderMode: ByteViewRenderMode
        if showFullVideoFrame || guestCount == 2 || guestCount == 4 {
            renderMode = .renderModeFit
        } else {
            renderMode = .renderModeFit1x1
        }

        return (StageAreaInfo(rect: shareArea, renderMode: .renderModeFit),
                guestAreas.map({ rect in
            StageAreaInfo(rect: rect, renderMode: renderMode)
        }))
    }

    func computeLayouts(guestCount: Int) -> [StageAreaInfo] {
        guard guestCount > 0 else {
            return []
        }
        let spacing: CGFloat = 7.0
        let topPadding = 7.0
        let bottomPadding = 7.0
        let horizontalPadding = spacing

        let videoRatio: CGFloat
        let columnCount: Int
        if showFullVideoFrame || guestCount == 1 {
            videoRatio = 16.0/9.0
        } else {
            videoRatio = 1.0
        }
        if showFullVideoFrame || guestCount <= 2 {
            columnCount = 1
        } else {
            columnCount = 2
        }
        let guestAreas = layoutStageGrid(layoutArea: self.stageSafeArea.inset(by: UIEdgeInsets(top: topPadding,
                                                                                               left: horizontalPadding,
                                                                                               bottom: bottomPadding,
                                                                                               right: horizontalPadding)),
                                         ratio: videoRatio,
                                         pinRatio: false,
                                         spacing: spacing,
                                         columnCount: columnCount,
                                         guestCount: guestCount)

        let renderMode: ByteViewRenderMode
        if showFullVideoFrame || guestCount == 1 {
            renderMode = .renderModeFit
        } else {
            renderMode = .renderModeFit1x1
        }

        return guestAreas.map { rect in
            StageAreaInfo(rect: rect, renderMode: renderMode)
        }
    }
}

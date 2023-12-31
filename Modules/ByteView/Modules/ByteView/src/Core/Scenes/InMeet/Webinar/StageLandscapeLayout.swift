// nolint: magic_number
import UIKit
import ByteViewNetwork


struct WebinarStageMobileLandscapeLayout: StageLayout {
    let stageArea: CGRect
    let stageSafeArea: CGRect
    let isPhone: Bool
    let shareRatio: CGFloat

    // 是否完整显示视频
    let showFullVideoFrame: Bool

    init(stageArea: CGRect,
         isPhone: Bool,
         shareRatio: CGFloat,
         showFullVideoFrame: Bool) {
        self.shareRatio = shareRatio
        self.stageArea = stageArea
        self.isPhone = isPhone

        // 安全区域调整 96% 的舞台宽度， 82% 的舞台高度
        let safeAreaSize = CGSize(
            width: stageArea.width * 0.96,
            height: stageArea.height * 0.82)
        self.stageSafeArea = CGRect(
            origin: CGPoint(
                x: stageArea.midX - safeAreaSize.width * 0.5,
                y: stageArea.midY - safeAreaSize.height * 0.5),
            size: safeAreaSize).integral
        self.showFullVideoFrame = showFullVideoFrame
    }

    func computeShareLayouts(guestCount: Int,
                             draggedLayoutInfo: WebinarStageInfo.DraggedLayoutInfo?,
                             sharePosition: StageSharePosition) -> (StageAreaInfo, [StageAreaInfo]) {
        switch sharePosition {
        case .topFloating, .bottomFloating:
            return computeFloatingShareLayout(shareRatio: shareRatio,
                                              stageArea: stageArea,
                                              guestCount: guestCount,
                                              isTopLayout: sharePosition == .topFloating)
        default:
            if guestCount <= 0 {
                let shareWidth: CGFloat
                let shareHeight: CGFloat
                if stageSafeArea.width > shareRatio * stageSafeArea.height {
                    // fit height
                    shareHeight = stageSafeArea.height
                    shareWidth = shareHeight * shareRatio
                } else {
                    // fit width
                    shareWidth = stageSafeArea.width
                    shareHeight = shareWidth / shareRatio
                }
                let shareAreaInfo = StageAreaInfo(rect: CGRect(x: stageSafeArea.origin.x + (stageSafeArea.width - shareWidth) * 0.5,
                                                               y: stageSafeArea.origin.y + (stageSafeArea.height - shareHeight) * 0.5,
                                                               width: shareWidth,
                                                               height: shareHeight),
                                                  renderMode: .renderModeFit)
                return (shareAreaInfo, [])
            } else {
                return computeHStackShareLayouts(guestCount: guestCount,
                                                 draggedLayoutInfo: draggedLayoutInfo,
                                                 sharePositionIsLeft: sharePosition == .left)
            }
        }
    }

    func computeLayouts(guestCount: Int) -> [StageAreaInfo] {
        guard guestCount > 0 else {
            return []
        }
        let spacing: CGFloat = computeSpacing(hasShareContent: false, guestCount: guestCount)

        let columnCount: Int
        let videoRatio: CGFloat

        if showFullVideoFrame {
            columnCount = guestCount >= 2 ? 2 : 1
        } else {
            columnCount = guestCount
        }

        if showFullVideoFrame || guestCount == 1 {
            videoRatio = 16.0 / 9.0
        } else {
            videoRatio = 1.0
        }
        let guestAreas = layoutStageGrid(layoutArea: stageSafeArea,
                                         ratio: videoRatio,
                                         pinRatio: true,
                                         spacing: spacing,
                                         columnCount: columnCount,
                                         guestCount: guestCount)

        let guestRenderMode: ByteViewRenderMode
        if showFullVideoFrame || guestCount == 1 {
            guestRenderMode = .renderModeFit
        } else {
            guestRenderMode = .renderModeFit1x1
        }
        return guestAreas.map { StageAreaInfo(rect: $0, renderMode: guestRenderMode) }
    }
}

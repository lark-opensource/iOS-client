// nolint: magic_number

import UIKit
import ByteViewNetwork


enum StageSharePosition {
    case none
    case left
    case right
    case topFloating
    case bottomFloating
}


struct StageAreaInfo {
    var rect: CGRect
    var renderMode: ByteViewRenderMode
}
protocol StageLayout {
    func computeLayouts(guestCount: Int) -> [StageAreaInfo]
    func computeShareLayouts(guestCount: Int,
                             draggedLayoutInfo: WebinarStageInfo.DraggedLayoutInfo?,
                             sharePosition: StageSharePosition) -> (StageAreaInfo, [StageAreaInfo])
    var stageSafeArea: CGRect { get }
}

func layoutStageGrid(layoutArea: CGRect,
                     ratio: CGFloat, // 嘉宾视图宽高比
                     pinRatio: Bool, // false: 允许嘉宾视图宽高比轻微调整, true: 不允许嘉宾视图宽高调整
                     spacing: CGFloat,
                     columnCount: Int,
                     guestCount: Int) -> [CGRect] {
    let rowCount = (guestCount + columnCount - 1) / columnCount

    var width = max((layoutArea.width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount), 0)
    var height = width / ratio
    if layoutArea.height < height * CGFloat(rowCount) + spacing * CGFloat(rowCount - 1) {
        height = max((layoutArea.height - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount), 0)
        if ratio == 1.0 && width <= height * 1.2 && !pinRatio {
            // 1:1 下，视频允许变形到 1.2 : 1
        } else {
            width = height * ratio
        }
    }
    width = ceil(width)
    height = ceil(height)

    let offsetY = floor(layoutArea.midY - (height * CGFloat(rowCount) + spacing * CGFloat(rowCount - 1)) * 0.5)
    let offsetX = floor(layoutArea.midX - (width * CGFloat(columnCount) + spacing * CGFloat(columnCount - 1)) * 0.5)
    let lastRowItemCount = guestCount - (rowCount - 1) * columnCount
    let lastRowOffsetX = floor(layoutArea.midX - (width * CGFloat(lastRowItemCount) + spacing * CGFloat(lastRowItemCount - 1)) * 0.5)
    var result: [CGRect] = []
    for idx in 0..<guestCount {
        let row = idx / columnCount
        let col = idx % columnCount
        let offsetX = idx >= guestCount - lastRowItemCount ? lastRowOffsetX : offsetX
        result.append(CGRect(x: offsetX + CGFloat(col) * (width + spacing),
                             y: offsetY + CGFloat(row) * (height + spacing),
                             width: width,
                             height: height))
    }
    return result
}

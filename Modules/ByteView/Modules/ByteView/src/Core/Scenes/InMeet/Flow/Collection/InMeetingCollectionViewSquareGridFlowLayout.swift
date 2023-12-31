//
//  InMeetingCollectionViewSquareGridFlowLayout.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/3/31.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxRelay
import RxSwift
import ByteViewSetting

class InMeetingCollectionViewSquareGridFlowLayout: UICollectionViewLayout {

    class SquareInfo {
        let gridType: GridTileType

        init(gridType: GridTileType) {
            self.gridType = gridType
        }

        var weight: Int {
            gridType == .room ? 2 : 1
        }
    }

    private static let logger = Logger.ui

    private weak var context: InMeetViewContext?

    var layouts: [IndexPath: InMeetingCollectionViewLayoutAttributes] = [:]

    var gridInfos: [SquareInfo] = []

    private var pages: [GridFlowPage] = []

    var pageRelay = BehaviorRelay<Int>(value: 0)

    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard meetingLayoutStyle != oldValue else {
                return
            }
            self.invalidateLayout()
        }
    }

    var isOverlayFullScreen: Bool {
        meetingLayoutStyle.isOverlayFullScreen
    }

    var topBarFrame: CGRect = .null {
        didSet {
            guard topBarFrame != oldValue,
                  isOverlayFullScreen else {
                return
            }
            self.invalidateLayout()
        }
    }

    var bottomBarFrame: CGRect = .null {
        didSet {
            guard bottomBarFrame != oldValue,
                  isOverlayFullScreen else {
                return
            }
            self.invalidateLayout()
        }
    }

    private static let maxWeightPerPage = 6
    private struct Layout {
        static let topBarHeight: CGFloat = InMeetNavigationBar.contentHeight
        static let bottomBarHeight: CGFloat = TiledLayoutGuideHelper.bottomBarHeight

        static let top: CGFloat = 4
        static let bottom: CGFloat = 7.0
        static let leftAndRight: CGFloat = 7.0
        static let spacing: CGFloat = 7.0

        static let maxHeightCompressRatio: CGFloat = 1.2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let cfgs: MultiResolutionConfig
    init(cfgs: MultiResolutionConfig, context: InMeetViewContext?) {
        self.cfgs = cfgs
        self.context = context
        super.init()
    }

    override func prepare() {
        super.prepare()
        setUpDefaultLayout()
        self.pageRelay.accept(pages.count)
    }

    // disable-lint: long function
    private func setUpDefaultLayout() {
        layouts.removeAll()

        guard let collectionView = collectionView,
              collectionView.frame.size.width > 1.0,
              collectionView.frame.size.height > 1.0,
              gridInfos.count == collectionView.numberOfItems(inSection: 0) else {
            Self.logger.error("[SquareLayout] collectionView state is invalid or gridVMs.count(\(gridInfos.count)) != collectionView.count(\(collectionView?.numberOfItems(inSection: 0))), skip")
            return
        }

        let collectionWidth = collectionView.frame.size.width
        let collectionHeight = collectionView.frame.size.height

        var pages: [GridFlowPage] = []
        for gridInfo in gridInfos {
            if let last = pages.last, last.add(item: gridInfo.weight) {
                continue
            } else {
                let page = GridFlowPage()
                _ = page.add(item: gridInfo.weight)
                pages.append(page)
            }
        }
        self.pages = pages

        let personHeight = (collectionWidth - 2 * Layout.leftAndRight - Layout.spacing) / 2
        let roomHeight = (collectionWidth - 2 * Layout.leftAndRight) * 9 / 16
        let fullscreenTopOffset = (collectionHeight - 2 * personHeight - roomHeight - 2 * Layout.spacing) / 2

        var totalCellIndex = 0
        for pageIndex in 0..<pages.count {
            let page = pages[pageIndex]

            // 1. 宫格真实size计算，包含挤压计算
            let personCount = CGFloat(page.personCount)
            let roomCount = CGFloat(page.roomCount)
            let (pagePersonWidth, pagePersonHeight,
                 pageRoomWidth, pageRoomHeight) = calRealHeight(collectionViewSize: collectionView.frame.size,
                                                                totalPageCount: pages.count,
                                                                personCount: personCount,
                                                                roomCount: roomCount)

            // 2. 计算整体距顶部的offset
            var preBottomY: CGFloat = 0
            if page.count == 1 {
                if page.rows[0].isRoomRow {
                    preBottomY = (collectionHeight - pageRoomHeight) / 2
                } else {
                    preBottomY = (collectionHeight - pagePersonHeight) / 2
                }
            } else if page.count == 2 {
                if page.rows.count == 1 {
                    if meetingLayoutStyle != .tiled, pages.count == 1 {
                        // 沉浸态1v1时宫格对齐topBar底部，不能被topBar、bottomBar遮挡
                        preBottomY = Layout.topBarHeight + Layout.top
                    } else {
                        preBottomY = (collectionHeight - 2 * pagePersonHeight - Layout.spacing) / 2
                    }
                } else {
                    var height: CGFloat = 0
                    for row in page.rows {
                        if row.isRoomRow {
                            height += pageRoomHeight
                        } else {
                            height += pagePersonHeight
                        }
                    }
                    preBottomY = (collectionHeight - height - Layout.spacing) / 2
                }
            } else if page.count <= 6 {
                if page.rows.count == 2 {
                    // 只有两行，整体居中
                    var height: CGFloat = 0
                    page.rows.forEach { row in
                        if row.isRoomRow {
                            height += pageRoomHeight
                        } else {
                            height += pagePersonHeight
                        }
                    }
                    preBottomY = (collectionHeight - height - Layout.spacing) / 2
                } else if page.count == 3 && page.rows.count == 3 {
                    // 三行rooms，仍然整体居中
                    preBottomY = max(Layout.top, (collectionHeight - 3 * pageRoomHeight - 2 * Layout.spacing) / 2)
                } else {
                    // 其余情况，固定顶部offset
                    preBottomY = max(Layout.top, fullscreenTopOffset)
                }
            } else {
//                assert(false, "layout error, page.count: \(page.count)")
            }

            var pageMatrix: [[Int]] = [[0, 0], [0, 0], [0, 0]]
            for i in 0..<page.rows.count {
                let row = page.rows[i]
                pageMatrix[i][0] = 1
                if row.isRoomRow || row.items.count == 2 {
                    pageMatrix[i][1] = 1
                }
            }

            // 3.根据上述计算得到的size、offset，计算每一个cell的绝对坐标
            for (row, column, weight) in page.enumerated {
                let indexPath = IndexPath(row: totalCellIndex, section: 0)
                let layout = InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
                layout.styleConfig = .squareGrid

                if page.count <= 2 {
                    layout.styleConfig.systemCallingStatusInfoSyle = Display.phone ? .systemCallingBigPhone : .systemCallingBigPad
                } else {
                    layout.styleConfig.systemCallingStatusInfoSyle = Display.phone ? .systemCallingMidPhone : .systemCallingMidPad
                }

                let x: CGFloat
                let y: CGFloat
                var width: CGFloat
                var height: CGFloat
                let isPerson = weight == 1

                if isPerson {
                    width = pagePersonWidth
                    height = pagePersonHeight
                } else {
                    width = pageRoomWidth
                    height = pageRoomHeight
                }

                if page.count == 1 {
                    if isPerson {
                        x = CGFloat(pageIndex) * collectionWidth + Layout.leftAndRight
                        y = preBottomY
                        layout.style = .fillSquare
                    } else {
                        x = CGFloat(pageIndex) * collectionWidth + Layout.leftAndRight
                        y = preBottomY
                        layout.style = .third
                    }
                    layout.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: 1)
                } else if page.count == 2 {
                    if page.rows.count == 1 {
                        let offset = (collectionWidth - width) / 2
                        x = CGFloat(pageIndex) * collectionWidth + offset
                        y = column == 0 ? preBottomY : preBottomY + Layout.spacing
                        layout.style = .newHalf
                    } else {
                        if isPerson {
                            x = CGFloat(pageIndex) * collectionWidth + (collectionWidth - width) / 2
                            y = row == 0 ? preBottomY : preBottomY + Layout.spacing
                            layout.style = .sixth
                        } else {
                            x = CGFloat(pageIndex) * collectionWidth + Layout.leftAndRight
                            y = row == 0 ? preBottomY : preBottomY + Layout.spacing
                            layout.style = .third
                        }
                    }
                    layout.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: 2)
                } else if page.count <= 6 {
                    if isPerson {
                        if pageMatrix[row][(column + 1) % 2] == 0 {
                            x = CGFloat(pageIndex) * collectionWidth + (collectionWidth - width) / 2
                        } else {
                            let offset = (collectionWidth - 2 * width - Layout.spacing) / 2
                            x = CGFloat(pageIndex) * collectionWidth + offset
                                    + CGFloat(column) * (Layout.spacing + width)
                        }
                        if column == 0 {
                            y = row == 0 ? preBottomY : preBottomY + Layout.spacing
                        } else {
                            y = preBottomY - height
                        }
                        layout.style = .sixth
                    } else {
                        let offset = (collectionWidth - pageRoomWidth) / 2
                        x = CGFloat(pageIndex) * collectionWidth + offset
                        y = row == 0 ? preBottomY : preBottomY + Layout.spacing
                        layout.style = .third
                    }
                    layout.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: 6)
                } else {
                    // 将异常状态下的 Cell 移出可见范围，避免千人会议卡死
                    x = -10000
                    y = -10000
                    width = 0
                    height = 0
                    layout.style = .fill
                    layout.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: 6)
//                    assert(false, "layout error")
                }

                layout.frame = CGRect(x: x, y: y, width: width, height: height)

                layout.styleConfig.meetingLayoutStyle = meetingLayoutStyle
                if self.isOverlayFullScreen {
                    if !self.topBarFrame.isNull,
                       self.topBarFrame.maxY > layout.frame.minY {
                        layout.styleConfig.topBarInset = self.topBarFrame.maxY - layout.frame.minY
                    } else {
                        layout.styleConfig.topBarInset = 0
                    }
                    if !self.bottomBarFrame.isNull,
                       self.bottomBarFrame.minY < layout.frame.maxY {
                        layout.styleConfig.bottomBarInset = layout.frame.maxY - self.bottomBarFrame.minY
                    } else {
                        layout.styleConfig.bottomBarInset = 0
                    }
                } else {
                    layout.styleConfig.topBarInset = 0
                    layout.styleConfig.bottomBarInset = 0
                }

                layouts[indexPath] = layout
                totalCellIndex += 1
                preBottomY = y + height
            }
        }
    }
    // enable-lint: long function

    private var errorTracked = false
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let ret = layouts.values.filter({ layout in
            layout.frame.size.width >= 1.0 && layout.frame.size.height >= 1.0 && rect.intersects(layout.frame)
        })

        if ret.count > 30 {
            let msg = "SquareGridFlowLayout elements in rect \(rect), count: \(ret.count), cv \(self.collectionView?.bounds), last: \(ret.last?.frame)"
            Logger.grid.error(msg)
            if !errorTracked {
                errorTracked = true
                BizErrorTracker.trackBizError(key: .gridCellCount, msg)
            }
        }
        return ret
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, collectionView.numberOfSections > 0 else {
            return .zero
        }
        var size = collectionView.frame.size
        size.width *= CGFloat(pages.count)
        return size
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attr = layouts[indexPath] {
            return attr
        }
        let attr = InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
        attr.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: 6)
        return attr
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return !newBounds.size.equalTo(collectionView.bounds.size)
    }

    override class var layoutAttributesClass: AnyClass {
        return InMeetingCollectionViewLayoutAttributes.self
    }

    // swiftlint:disable large_tuple
    private func calRealHeight(collectionViewSize: CGSize,
                               totalPageCount: Int,
                               personCount: CGFloat,
                               roomCount: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let collectionWidth = collectionViewSize.width
        let collectionHeight = collectionViewSize.height
        let personWidth = (collectionWidth - 2 * Layout.leftAndRight - Layout.spacing) / 2
        let personHeight = personWidth
        let roomWidth = collectionWidth - 2 * Layout.leftAndRight
        let roomHeight = roomWidth * (9.0 / 16.0)

        var pagePersonWidth = personWidth
        var pagePersonHeight = personHeight
        var pageRoomWidth = roomWidth
        var pageRoomHeight = roomHeight

        let personRowCount = ceil(personCount / 2)
        let roomRowCount = roomCount

        var maxDisplayHeight = collectionHeight - Layout.top - Layout.bottom

        // 三种情况宫格的size可能有异化:
        // 1.只有一个个人宫格；2.只有两个个人宫格；3.三行排满，需要挤压
        if personCount == 1 && roomCount == 0 {
            // 只有一个个人宫格
            pagePersonWidth = collectionWidth - 2 * Layout.leftAndRight
            pagePersonHeight = pagePersonWidth
        } else if personCount == 2 && roomCount == 0 {
            // 有两个个人宫格
            // 沉浸态1v1时宫格不能被topBar、bottomBar遮挡，因此最大显示高度要减掉
            if meetingLayoutStyle != .tiled, totalPageCount == 1 {
                maxDisplayHeight -= Layout.topBarHeight
                maxDisplayHeight -= Layout.bottomBarHeight
            }

            let regularHeight = collectionWidth - 2 * Layout.leftAndRight
            if 2 * regularHeight + Layout.spacing > maxDisplayHeight {
                pagePersonHeight = (maxDisplayHeight - Layout.spacing) / 2
                let minCompressHeight = regularHeight / Layout.maxHeightCompressRatio
                // 高度挤压
                if minCompressHeight > pagePersonHeight {
                    pagePersonWidth = pagePersonHeight
                } else {
                    pagePersonWidth = regularHeight
                }
            } else {
                pagePersonWidth = regularHeight
                pagePersonHeight = regularHeight
            }
        } else if personRowCount + roomRowCount == 3 {
            // 三行排满，可能需要挤压
            var totalHeight = personRowCount * personHeight + roomRowCount * roomHeight + 2 * Layout.spacing
            if totalHeight > maxDisplayHeight {
                let minPersonCompressHeight = personHeight / Layout.maxHeightCompressRatio
                totalHeight = personRowCount * minPersonCompressHeight + roomRowCount * roomHeight + 2 * Layout.spacing
                if totalHeight > maxDisplayHeight {
                    // 个人、Room宫格等比例缩放
                    // 计算公式推导说明: https://bytedance.feishu.cn/docx/doxcnTmYqoMJ7sBa9994O8uy1ac
                    let numerator = maxDisplayHeight - (9.0 / 16.0 * roomRowCount + 2) * Layout.spacing
                    let fraction = personRowCount + 9.0 / 8.0 * roomRowCount
                    pagePersonWidth = numerator / fraction
                    pagePersonHeight = pagePersonWidth
                    pageRoomWidth = 2 * pagePersonWidth + Layout.spacing
                    pageRoomHeight = pageRoomWidth * 9.0 / 16.0
                } else {
                    // 个人宫格高度挤压
                    pagePersonHeight = (maxDisplayHeight - roomRowCount * roomHeight - 2 * Layout.spacing) / personRowCount
                }
            }
        }
        return (pagePersonWidth, pagePersonHeight, pageRoomWidth, pageRoomHeight)
    }
    // swiftlint:enable large_tuple
}

extension InMeetingCollectionViewSquareGridFlowLayout: PagedCollectionLayout {
    var pageObservable: Observable<Int> {
        pageRelay.asObservable()
    }
    var pageCount: Int {
        pageRelay.value
    }
    var visibleRange: GridVisibleRange {
        let pageWidth = collectionView?.bounds.width ?? 0
        let offsetX = collectionView?.contentOffset.x ?? 0
        let pageIndex = pageWidth == 0 ? 0 : Int(round(offsetX / pageWidth))
        return .page(index: pageIndex)
    }
}

private class GridFlowRow {
    var items: [Int] = []
    var weight = 0
    static let maxWeight = 2

    var isRoomRow = false

    func add(item: Int) -> Bool {
        if weight + item > Self.maxWeight {
            return false
        }
        isRoomRow = item == 2
        items.append(item)
        weight += item
        return true
    }
}

private class GridFlowPage {
    var rows: [GridFlowRow] = []
    static let maxNumberOfRows = 3

    func add(item: Int) -> Bool {
        if let last = rows.last, last.add(item: item) {
            return true
        } else if rows.count + 1 <= Self.maxNumberOfRows {
            let row = GridFlowRow()
            _ = row.add(item: item)
            rows.append(row)
            return true
        } else {
            return false
        }
    }

    var count: Int {
        rows.reduce(0, { $0 + $1.items.count })
    }

    var roomCount: Int {
        rows.filter { $0.isRoomRow }.count
    }

    var personCount: Int {
        rows.filter { !$0.isRoomRow }.map { $0.items.count }.reduce(0, +)
    }

    var enumerated: [(row: Int, column: Int, weight: Int)] {
        rows.enumerated().flatMap { (i, row) in
            row.items.enumerated().map { (j, item) in
                (row: i, column: j, weight: item)
            }
        }
    }
}

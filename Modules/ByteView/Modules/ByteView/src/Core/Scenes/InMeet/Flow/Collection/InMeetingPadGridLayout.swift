//
//  InMeetingPadGridLayout.swift
//  ByteView
//
//  Created by liujianlong on 2022/7/26.
//

import UIKit
import RxRelay
import RxSwift
import ByteViewSetting

// PRD: https://bytedance.feishu.cn/docx/doxcnkL5Kt6OP0UNL26fyi5nvoc
final class InMeetingPadGridLayout: UICollectionViewLayout, PagedCollectionLayout {

    // 从多分辨率 iPad 订阅配置中初始化
    private let maxCellCount: Int

    var itemCount: Int = 0
    var pageCount: Int = 0

    var pageSize: CGSize = .zero

    var itemsPerPage: Int = 5 * 5

    var insets: UIEdgeInsets = .zero
    var hSpacing: CGFloat = 8.0
    var vSpacing: CGFloat = 8.0

    var gridCalculator: PadGridCalculator?
    var lastPageSolution: PadGridCalculator.Solution?

    var pageObservable: Observable<Int> {
        pageRelay.asObservable()
    }

    var visibleRange: GridVisibleRange {
        let range = collectionVisibleRange
        return .range(start: range.startIndex, end: range.endIndex, pageSize: itemsPerPage)
    }

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

    private let pageRelay = BehaviorRelay(value: 0)

    let cfgs: MultiResolutionConfig
    private let showFullVideoFrame: Bool
    init(cfgs: MultiResolutionConfig, showFullVideoFrame: Bool) {
        self.cfgs = cfgs
        self.showFullVideoFrame = showFullVideoFrame
        self.maxCellCount = cfgs.pad.subscribe.gallery.last?.max ?? 9
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        self.itemCount = self.collectionView?.numberOfItems(inSection: 0) ?? 0
        self.pageSize = self.collectionView?.bounds.size ?? .zero
        let safeAreaInsets = self.collectionView?.safeAreaInsets ?? .zero
        let minWHRatio = showFullVideoFrame ? 16.0 / 9.0 : 1.0
        let maxWHRatio = 16.0 / 9.0
        var padGridConfig = Self.computePadGridConfig(safeAreaInsets: safeAreaInsets,
                                                      pageSize: self.pageSize,
                                                      minWHRatio: minWHRatio,
                                                      maxWHRatio: maxWHRatio,
                                                      itemCount: self.itemCount,
                                                      maxCellCount: self.maxCellCount)

        if self.gridCalculator == nil || self.gridCalculator!.padGridConfig != padGridConfig {
            self.gridCalculator = PadGridCalculator(padGridConfig: padGridConfig)
            self.itemsPerPage = gridCalculator!.maxCol * gridCalculator!.maxRow
        }
        self.lastPageSolution = self.gridCalculator!.computeSolution(cellCount: itemCount)
        self.pageCount = (itemCount + itemsPerPage - 1) / itemsPerPage
        self.pageRelay.accept(self.pageCount)
    }

    override class var layoutAttributesClass: AnyClass {
        InMeetingCollectionViewLayoutAttributes.self
    }

    private func indexPathFromItemIndex(_ itemIndex: Int) -> IndexPath {
        return IndexPath(row: itemIndex, section: 0)
    }

    private func makeAttribute(indexPath: IndexPath) -> InMeetingCollectionViewLayoutAttributes {
        let itemIndex = indexPath.row
        let attribute = InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
        attribute.styleConfig = .padGrid
        let pageIndex = itemIndex / itemsPerPage
        let solution = pageIndex < pageCount - 1 ? gridCalculator!.fullPageSolution : lastPageSolution!
        let indexInsidePage = itemIndex % itemsPerPage
        let columnIndex = indexInsidePage % solution.columnCount

        var x = CGFloat(columnIndex) * (solution.cellWidth + solution.hSpacing) + solution.hMargin + CGFloat(pageIndex) * pageSize.width
        let y = CGFloat(indexInsidePage / solution.columnCount) * (solution.cellHeight + solution.vSpacing) + solution.topMargin
        let rowIndex = indexInsidePage / solution.columnCount
        if pageIndex == pageCount - 1,
           rowIndex == solution.rowCount - 1,
           itemCount % itemsPerPage > 0 {
            x += CGFloat(solution.columnCount * solution.rowCount - itemCount % itemsPerPage) * (solution.cellWidth + solution.hSpacing) * 0.5
        }
        attribute.frame = CGRect(x: x, y: y, width: solution.cellWidth, height: solution.cellHeight)

        // UX 异化 视频框架高度小于等于160，则头像和异常 icon 的纵向居中范围向上抬高4
        attribute.styleConfig.avatarOffset = solution.cellHeight <= 160.0 ? -2.0 : 0.0
        attribute.styleConfig.cameraHaveNoAccessOffset = attribute.styleConfig.avatarOffset
        attribute.styleConfig.meetingLayoutStyle = meetingLayoutStyle
        if showFullVideoFrame {
            attribute.styleConfig.renderMode = .renderModeFit
        }
        if self.isOverlayFullScreen {
            if !self.topBarFrame.isNull,
               self.topBarFrame.maxY > attribute.frame.minY {
                attribute.styleConfig.topBarInset = self.topBarFrame.maxY - attribute.frame.minY
            } else {
                attribute.styleConfig.topBarInset = 0
            }
            if !self.bottomBarFrame.isNull,
               self.bottomBarFrame.minY < attribute.frame.maxY {
                attribute.styleConfig.bottomBarInset = attribute.frame.maxY - self.bottomBarFrame.minY
            } else {
                attribute.styleConfig.bottomBarInset = 0
            }
        } else {
            attribute.styleConfig.topBarInset = 0
            attribute.styleConfig.bottomBarInset = 0
        }

        attribute.style = .quarter
        let lastPageCellCount = itemCount % itemsPerPage == 0 ? itemsPerPage : itemCount % itemsPerPage
        attribute.viewCount = pageIndex == pageCount - 1 ? lastPageCellCount : itemsPerPage
        attribute.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: attribute.viewCount)

        return attribute
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard isValidState else {
            return InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
        }
        return makeAttribute(indexPath: indexPath)
    }

    var errorTracked = false
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard isValidState && !rect.isEmpty && !rect.isNull else {
            return []
        }
        let pageIndexStart = Int(floor(rect.minX / self.pageSize.width))
        let pageIndexEnd = Int(floor(rect.maxX / self.pageSize.width))
        let itemIndexStart = min(max(pageIndexStart * itemsPerPage, 0), max(self.itemCount - 1, 0))
        let itemIndexEnd = min(max(itemsPerPage * (pageIndexEnd + 1), 0), self.itemCount)

        let attributes = (itemIndexStart..<itemIndexEnd)
            .map(indexPathFromItemIndex(_:))
            .map(makeAttribute(indexPath:))
            .filter { attr in
                !attr.frame.isNull && !attr.frame.isEmpty && !attr.frame.isInfinite && attr.frame.intersects(rect)
            }
        if attributes.count > 100 {
            let msg = "PadGallery elements in rect \(rect), count: \(attributes.count), cv \(self.collectionView?.bounds), last: \(attributes.last?.frame)"
            Logger.grid.error(msg)
            if !errorTracked {
                errorTracked = true
                BizErrorTracker.trackBizError(key: .gridCellCount, msg)
            }
        }
        return attributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else {
            return false
        }
        return !collectionView.bounds.size.equalTo(newBounds.size)
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: self.pageSize.width * CGFloat(pageCount),
               height: self.pageSize.height)
    }

    private var isValidState: Bool {
        pageSize.width >= 1.0 && pageSize.height >= 1.0 && itemCount > 0
    }
}

extension InMeetingPadGridLayout {

    // disable-lint: magic number
    private static func bottomPadding(isPageControlVisible: Bool, safeAreaInsets: UIEdgeInsets) -> CGFloat {
        var bottomPadding = 4.0
        if safeAreaInsets.bottom > 0 {
            bottomPadding += isPageControlVisible ? 26.0 : 13.0
        } else {
            bottomPadding += isPageControlVisible ? 13.0 : 0.0
        }
        return bottomPadding
    }
    // enable-lint: magic number

    private static func computePadGridConfig(safeAreaInsets: UIEdgeInsets,
                                             pageSize: CGSize,
                                             minWHRatio: Double,
                                             maxWHRatio: Double,
                                             spacing: CGFloat,
                                             itemCount: Int,
                                             maxCellCount: Int) -> PadGridConfig {
        let maxCol = pageSize.width > pageSize.height ? 5 : 4
        let maxRow = pageSize.width > pageSize.height ? 5 : 6
        func pageControlVisibleConfig() -> PadGridConfig {
            PadGridConfig(screenSize: pageSize,
                          topPadding: safeAreaInsets.top + 4.0,
                          bottomPadding: bottomPadding(isPageControlVisible: true, safeAreaInsets: safeAreaInsets),
                          leftPadding: 8.0,
                          rightPadding: 8.0,
                          vSpacing: spacing,
                          hSpacing: spacing,
                          maxCellCount: maxCellCount,
                          maxCol: maxCol,
                          maxRow: maxRow,
                          minWHRatio: minWHRatio,
                          maxWHRatio: maxWHRatio)
        }

        if itemCount > maxRow * maxCol || itemCount > maxCellCount {
            return pageControlVisibleConfig()
        }

        let padGridConfig = PadGridConfig(screenSize: pageSize,
                                          topPadding: safeAreaInsets.top + 4.0,
                                          bottomPadding: bottomPadding(isPageControlVisible: false, safeAreaInsets: safeAreaInsets),
                                          leftPadding: 8.0,
                                          rightPadding: 8.0,
                                          vSpacing: spacing,
                                          hSpacing: spacing,
                                          maxCellCount: maxCellCount,
                                          maxCol: maxCol,
                                          maxRow: maxRow,
                                          minWHRatio: minWHRatio,
                                          maxWHRatio: maxWHRatio)
        if itemCount > padGridConfig.maxCol * padGridConfig.maxRow {
            return pageControlVisibleConfig()
        }
        return padGridConfig
    }

    private static func computePadGridConfig(safeAreaInsets: UIEdgeInsets,
                                             pageSize: CGSize,
                                             minWHRatio: Double,
                                             maxWHRatio: Double,
                                             itemCount: Int,
                                             maxCellCount: Int) -> PadGridConfig {
        return computePadGridConfig(safeAreaInsets: safeAreaInsets,
                                    pageSize: pageSize,
                                    minWHRatio: minWHRatio,
                                    maxWHRatio: maxWHRatio,
                                    spacing: 8.0,
                                    itemCount: itemCount,
                                    maxCellCount: maxCellCount)
    }

}

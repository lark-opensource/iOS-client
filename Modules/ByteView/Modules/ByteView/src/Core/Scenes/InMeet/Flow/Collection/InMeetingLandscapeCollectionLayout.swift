//
//  InMeetingLandscapeCollectionLayout.swift
//  ByteView
//
//  Created by liujianlong on 2022/4/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxRelay
import RxSwift
import ByteViewSetting
import ByteViewUI

class InMeetingLandscapeCollectionLayout: UICollectionViewLayout, PagedCollectionLayout {
    enum Layout {
        static let topBarHeight = 44.0
        static let elementsPerPage = 4
        static let isXSeries = Display.iPhoneXSeries
        static let widthHeightRatio: CGFloat = 16.0 / 9.0
        static let pageControlHeight = 10.0
        enum XserisesBottomInset {
            static let pageControlHiddenInset: CGFloat = 21.0
            static let normalInset: CGFloat = 26.0
        }
        static let normalBottomInset: CGFloat = 13.0
    }

    var pageObservable: Observable<Int> {
        pageRelay.asObservable()
    }
    var pageCount: Int {
        pageRelay.value
    }
    var visibleRange: GridVisibleRange {
        let range = collectionVisibleRange
        return .range(start: range.startIndex, end: range.endIndex, pageSize: Layout.elementsPerPage)
    }

    private let pageRelay = BehaviorRelay(value: 0)

    var pageSize = VCScene.bounds.size
    var itemCount: Int = 0

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

    var viewModels: [InMeetGridCellViewModel] = []

    var isPageControlHidden: Bool {
        self.pageCount <= 1
    }

    // 宫格数据源中是否包含共享类型 （共享屏幕、白板）
    private var isSharing: Bool = false

    let cfgs: MultiResolutionConfig
    init(cfgs: MultiResolutionConfig) {
        self.cfgs = cfgs
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        guard let cv = self.collectionView else {
            return
        }
        self.isSharing = viewModels.first?.type == .share
        self.pageSize = cv.bounds.size
        // fix https://t.wtturl.cn/UuCw599/
        self.itemCount = max(0, cv.numberOfItems(inSection: 0) - (isSharing ? 1 : 0))
        let pageCount = (itemCount + Layout.elementsPerPage - 1) / Layout.elementsPerPage + (isSharing ? 1 : 0)
        self.pageRelay.accept(pageCount)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: pageSize.width * CGFloat(self.pageCount), height: pageSize.height)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard isValidState else {
            return InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
        }
        return makeLayoutAttribute(indexPath: indexPath)
    }

    private var errorTracked = false
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard isValidState else {
            return []
        }
        var itemRect: CGRect = rect
        if isSharing {
            itemRect = itemRect.offsetBy(dx: -self.pageSize.width, dy: 0)
        }
        let itemsPerPage = Self.Layout.elementsPerPage
        let pageIndexStart = Int(floor(itemRect.minX / self.pageSize.width))
        let pageIndexEnd = Int(floor(itemRect.maxX / self.pageSize.width))
        let itemIndexStart = max(0, min(pageIndexStart * itemsPerPage, itemCount - 1))
        let itemIndexEnd = max(0, min(itemsPerPage * (pageIndexEnd + 1), itemCount))

        var attributes = (itemIndexStart..<itemIndexEnd).map { i -> UICollectionViewLayoutAttributes in
            return makeLayoutAttribute(indexPath: IndexPath(row: isSharing ? i + 1 : i, section: 0))
        }
        .filter { attr in
            !attr.frame.isNull && !attr.frame.isEmpty && !attr.frame.isInfinite && attr.frame.intersects(rect)
        }

        if isSharing, rect.intersects(self.shareScreenFrame) {
            attributes.append(self.shareScreenAttr)
        }

        if attributes.count > 30 {
            let msg = "LandscapeLayout elements in rect \(rect), count: \(attributes.count), cv \(self.collectionView?.bounds), last: \(attributes.last?.frame)"
            Logger.grid.error(msg)
            if !errorTracked {
                errorTracked = true
                BizErrorTracker.trackBizError(key: .gridCellCount, msg)
            }
        }
        return attributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return !newBounds.size.equalTo(collectionView.bounds.size)
    }

    var safeAreaLeft: CGFloat {
        self.collectionView?.safeAreaInsets.left ?? 44.0
    }

    override class var layoutAttributesClass: AnyClass {
        InMeetingCollectionViewLayoutAttributes.self
    }

    private var isValidState: Bool {
        pageSize.width >= 1.0 && pageSize.height >= 1.0
    }
}

extension InMeetingLandscapeCollectionLayout {

    private func makeLayoutAttribute(indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        if isSharing && indexPath.row == 0 {
            return shareScreenAttr
        }
        let itemIndex = isSharing ? indexPath.row - 1 : indexPath.row
        let attr = InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
        let (rect, viewCount) = computeLayoutRect(index: itemIndex,
                                                  total: self.itemCount,
                                                  pageSize: self.pageSize)
        attr.frame = rect
        attr.viewCount = viewCount
        attr.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: viewCount)
        configAttrStyle(attribute: attr)
        switch viewCount {
        case 1:
            attr.style = .fill
        case 2:
            attr.style = .half
        default:
            attr.style = .quarter
        }
        if isSharing {
            transformGridAttribute(attr)
        }
        return attr
    }

    private func configAttrStyle(attribute: InMeetingCollectionViewLayoutAttributes) {
        attribute.styleConfig = .phoneLandscapeGrid
        attribute.styleConfig.userInfoViewStyle.isMobileLandscapeSingle = self.itemCount == 1
        attribute.styleConfig.cornerRadius = self.itemCount == 1 ? 0.0 : 8.0
        attribute.styleConfig.meetingLayoutStyle = meetingLayoutStyle
        if attribute.viewCount <= 2 {
            attribute.styleConfig.systemCallingStatusInfoSyle = Display.phone ? .systemCallingBigPhone : .systemCallingBigPad
        } else {
            attribute.styleConfig.systemCallingStatusInfoSyle = Display.phone ? .systemCallingMidPhone : .systemCallingMidPad
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
    }


    private func computeLayoutRect(index: Int, total: Int, pageSize: CGSize) -> (CGRect, Int) {
        let totalPageCount = (total + 3) / Self.Layout.elementsPerPage
        let pageIndex = index / Self.Layout.elementsPerPage
        let lastPageItemCount = total % Self.Layout.elementsPerPage
        let indexInsidePage = index % Self.Layout.elementsPerPage
        let pageOffset = CGFloat(pageIndex) * pageSize.width
        var vTopInset: CGFloat = isOverlayFullScreen ? 7.0 : 7.0 + Self.Layout.topBarHeight
        var vBottomInset: CGFloat = 0.0
        if Self.Layout.isXSeries {
            vBottomInset = isPageControlHidden ? Self.Layout.XserisesBottomInset.pageControlHiddenInset : Self.Layout.XserisesBottomInset.normalInset
        } else {
            vBottomInset = isPageControlHidden ? 7.0 : Self.Layout.normalBottomInset
        }
        let hSpace: CGFloat = 7.0
        let vSpace: CGFloat = 7.0

        var rect: CGRect
        var viewCount: Int

        if itemCount == 1 {
            if isOverlayFullScreen {
                vTopInset = 0.0
                vBottomInset = 0.0
            } else {
                vTopInset = Self.Layout.topBarHeight
                vBottomInset = 0.0
            }
            let itemHeight = pageSize.height - vTopInset - vBottomInset
            let itemWidth = itemHeight * Self.Layout.widthHeightRatio
            rect = CGRect(x: (pageSize.width - itemWidth) / 2,
                          y: vTopInset,
                          width: itemWidth,
                          height: itemHeight)
            viewCount = 1
        } else if pageIndex == totalPageCount - 1 && lastPageItemCount != 0 {
            viewCount = lastPageItemCount
            if lastPageItemCount == 1 {
                let itemHeight = pageSize.height - vTopInset - vBottomInset
                let itemWidth = itemHeight * Self.Layout.widthHeightRatio
                rect = CGRect(x: (pageSize.width - itemWidth) / 2,
                              y: vTopInset,
                              width: itemWidth,
                              height: itemHeight)
                viewCount = 1
            } else if lastPageItemCount == 2 {
                let hInset: CGFloat = Self.Layout.isXSeries ? safeAreaLeft : 7.0
                let itemWidth: CGFloat = (pageSize.width - hInset * 2 - hSpace) / 2
                let itemHeight: CGFloat = itemWidth / Self.Layout.widthHeightRatio
                rect = CGRect(x: hInset + (itemWidth + hSpace) * CGFloat(index % Self.Layout.elementsPerPage),
                              y: (pageSize.height - itemHeight) / 2,
                              width: itemWidth,
                              height: itemHeight)
            } else {
                assert(lastPageItemCount == 3)
                let itemHeight: CGFloat = (pageSize.height - vTopInset - vBottomInset - vSpace) / 2
                let itemWidth: CGFloat = itemHeight * Self.Layout.widthHeightRatio
                let hInset = (pageSize.width - itemWidth * 2.0 - hSpace) / 2
                switch indexInsidePage {
                case 0, 1:
                    rect = CGRect(x: hInset + (itemWidth + hSpace) * CGFloat(indexInsidePage),
                                  y: vTopInset,
                                  width: itemWidth,
                                  height: itemHeight)
                default:
                    assert(indexInsidePage == 2)
                    rect = CGRect(x: (pageSize.width - itemWidth) / 2,
                                  y: vTopInset + itemHeight + vSpace,
                                  width: itemWidth,
                                  height: itemHeight)
                }
            }
        } else {
            let itemHeight: CGFloat = (pageSize.height - vTopInset - vBottomInset - vSpace) / 2
            let itemWidth: CGFloat = itemHeight * Self.Layout.widthHeightRatio
            let hInset = (pageSize.width - itemWidth * 2 - hSpace) / 2
            let pageRow = indexInsidePage / 2
            let pageCol = indexInsidePage % 2
            rect = CGRect(x: hInset + CGFloat(pageCol) * (itemWidth + hSpace),
                          y: vTopInset + CGFloat(pageRow) * (itemHeight + vSpace),
                          width: itemWidth,
                          height: itemHeight)
            viewCount = Self.Layout.elementsPerPage
        }
        rect.origin.x += pageOffset
        return (rect, viewCount)
    }
}

extension InMeetingLandscapeCollectionLayout {
    private func transformGridAttribute(_ attr: UICollectionViewLayoutAttributes) {
        assert(self.isSharing)
        if let gridAttr = attr as? InMeetingCollectionViewLayoutAttributes {
            gridAttr.frame = gridAttr.frame.offsetBy(dx: self.pageSize.width, dy: 0)
        }
    }

    var shareScreenFrame: CGRect {
        CGRect(origin: .zero, size: self.pageSize)
    }

    var shareScreenAttr: UICollectionViewLayoutAttributes {
        let attr = InMeetingCollectionViewLayoutAttributes(forCellWith: IndexPath(row: 0, section: 0))
        attr.frame = shareScreenFrame
        configAttrStyle(attribute: attr)
        attr.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs, viewCount: 1)
        attr.viewCount = 1
        return attr
    }
}

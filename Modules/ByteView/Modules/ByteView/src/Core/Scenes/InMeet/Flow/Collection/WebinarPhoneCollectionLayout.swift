//
//  WebinarPhoneCollectionLayout.swift
//  ByteView
//
//  Created by liujianlong on 2023/9/20.
//

import Foundation
import UIKit
import RxRelay
import RxSwift
import ByteViewSetting

/// https://bytedance.feishu.cn/docx/UonIdBnbConJT7xvhDscov13n9Y
/// Webinar 手机采用单列布局
private let itemsPerPage = 3
private let hPadding: CGFloat = 7.0
private let topPadding: CGFloat = 4.0
private let vSpacing: CGFloat = 7.0
private let topBarHeight: CGFloat = InMeetNavigationBar.contentHeight
private let bottomBarHeight: CGFloat = TiledLayoutGuideHelper.bottomBarHeight

private enum Layout {
    static let bottomPadding: CGFloat = 7.0
    static let bottomPaddingMoreThanOnePage: CGFloat = 13.0
}


// flowVC: top = overlayFullScreen ? superView : topBar.bottom, bottom = overlayFullScreen ? superView : bottomBar.top
// collectionView: top, bottom = safeAreaLayoutGuide
class WebinarPhoneCollectionLayout: UICollectionViewLayout, PagedCollectionLayout {

    private let cfgs: MultiResolutionConfig
    private var pageSize: CGSize = .zero
    private var itemCount: Int = 0
    private var itemSize: CGSize = CGSize(width: 1.0, height: 1.0)
    private var layoutArea: CGRect = .zero
    private var bottomPadding: CGFloat = Layout.bottomPadding

    // 在 performBatchUpdate 或者 reloadData 前修改，无需调用 `invalidateLayout`
    var indexPathFor1x1: IndexPath?

    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard self.meetingLayoutStyle != oldValue else {
                return
            }
            invalidateLayout()
        }
    }

    var pageObservable: Observable<Int> {
        pageRelay.asObservable()
    }
    var pageCount: Int {
        pageRelay.value
    }
    var visibleRange: GridVisibleRange {
        let range = collectionVisibleRange
        return .range(start: range.startIndex, end: range.endIndex, pageSize: itemsPerPage)
    }

    private let pageRelay = BehaviorRelay(value: 0)

    init(cfgs: MultiResolutionConfig) {
        self.cfgs = cfgs
        super.init()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private var isValidLayout: Bool {
        self.pageSize.width >= 1.0 && self.pageSize.height >= 1.0 && self.pageCount > 0 && self.itemCount > 0
    }

    override func prepare() {
        guard let collectionView = self.collectionView else {
            return
        }
        super.prepare()
        assert(collectionView.numberOfSections == 1)
        itemCount = collectionView.numberOfItems(inSection: 0)
        pageSize = collectionView.bounds.size
        pageRelay.accept((itemCount + (itemsPerPage - 1)) / itemsPerPage)
        layoutArea = CGRect(origin: .zero, size: pageSize)
        if meetingLayoutStyle.isOverlayFullScreen {
            layoutArea = layoutArea.inset(by: UIEdgeInsets(top: topBarHeight, left: 0.0, bottom: bottomBarHeight, right: 0.0))
        }
        self.bottomPadding = meetingLayoutStyle == .tiled && pageCount > 1 ? Layout.bottomPaddingMoreThanOnePage : Layout.bottomPadding
        var itemWidth = pageSize.width - hPadding * 2
        var itemHeight = itemWidth / 16.0 * 9.0
        if itemHeight * 3 + vSpacing * 2 + topPadding + bottomPadding > layoutArea.height {
            itemHeight = (layoutArea.height - vSpacing * 2 - topPadding - bottomPadding) / 3
            itemWidth = itemHeight * 16.0 / 9.0
        }
        self.itemSize = CGSize(width: itemWidth, height: itemHeight)

    }

    private func makeLayoutAttributeForItemAt(indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let attrs = InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
        guard isValidLayout else {
            return attrs
        }
        let pageIndex = indexPath.row / itemsPerPage
        let indexInsidePage = indexPath.row % itemsPerPage
        let itemCountInsideThisPage = pageIndex == pageCount - 1 && itemCount % itemsPerPage != 0 ? itemCount % itemsPerPage : itemsPerPage

        var itemSize = self.itemSize
        if indexPath == self.indexPathFor1x1 {
            if itemCountInsideThisPage == 1 {
                itemSize.height = itemSize.width
            } else {
                itemSize.width = itemSize.height
            }
        }


        let vOffset = (layoutArea.height - CGFloat(itemCountInsideThisPage) * itemSize.height - CGFloat(itemCountInsideThisPage - 1) * vSpacing - topPadding - bottomPadding) * 0.5 + topPadding + layoutArea.origin.y
        let hOffset = (pageSize.width - itemSize.width) * 0.5 + pageSize.width * CGFloat(pageIndex)
        let frame = CGRect(origin: CGPoint(x: hOffset,
                                           y: vOffset + CGFloat(indexInsidePage) * (itemSize.height + vSpacing)),
                           size: itemSize)
        attrs.frame = frame
        attrs.style = .quarter
        attrs.multiResSubscribeConfig = InMeetingLandscapeCollectionLayout.makeMultiResSubConfig(cfgs: self.cfgs, viewCount: itemCountInsideThisPage)
        attrs.styleConfig = .squareGrid
        attrs.styleConfig.renderMode = .renderModeFit
        return attrs
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return makeLayoutAttributeForItemAt(indexPath: indexPath)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard isValidLayout else {
            return []
        }
        let startPage = max(Int(rect.minX / pageSize.width), 0)
        let endPage = max(Int(rect.maxX / pageSize.width), 0)
        assert(endPage >= startPage)

        let itemStart = startPage * itemsPerPage
        var itemsEnd = (endPage + 1) * itemsPerPage

        if itemStart >= itemCount {
            return []
        }
        if itemsEnd > itemCount {
            itemsEnd = itemCount
        }
        return (itemStart..<itemsEnd).map { idx in
            makeLayoutAttributeForItemAt(indexPath: IndexPath(row: idx, section: 0))
        }
    }

    override class var layoutAttributesClass: AnyClass {
        InMeetingCollectionViewLayoutAttributes.self
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

}

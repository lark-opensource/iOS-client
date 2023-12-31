//
//  InMeetingCollectionViewSingleRowLayout.swift
//  ByteView
//
//  Created by Prontera on 2020/11/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import RxSwift
import ByteViewSetting

class InMeetingCollectionViewSingleRowLayout: UICollectionViewLayout {
    var layouts: [IndexPath: InMeetingCollectionViewLayoutAttributes] = [:]

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

    // disable-lint: magic number
    struct Layout {
        private static let isPad = Display.pad
        private static var isNewLayout: Bool {
            InMeetFlowComponent.isNewLayoutEnabled
        }
        static let top: CGFloat = 4
        static let margin: CGFloat = isPad ? 8 : 0
        static let rightInset: CGFloat = isPad ? 24.0 : 0.0
        static let spacing: CGFloat = isPad ? 8 : (isNewLayout ? 6 : 7)
        static let additionalSpacing: CGFloat = isPad ? 0 : spacing
        static var singleRowWidth: CGFloat {
            return isPad ? 160 : 90
        }
        static let singleRowHeight: CGFloat = 90
    }
    // enable-lint: magic number

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
        setUpSingleRowLayout()
    }

    private func setUpSingleRowLayout() {
        guard let collectionView = collectionView else {
            return
        }
        layouts.removeAll()

        let count = collectionView.numberOfItems(inSection: 0)
        if CGFloat(count) * (Layout.singleRowWidth + Layout.spacing) + Layout.additionalSpacing + Layout.margin + Layout.rightInset < collectionView.frame.size.width {
            // 居中
            let y = Layout.top
            let centerX = collectionView.frame.size.width / 2
            let halfIndex = count / 2
            if count % 2 == 0 {
                for i in 0 ..< count {
                    let indexPath = IndexPath(row: i, section: 0)
                    let layout = makeLayoutAttribute(indexPath: indexPath)
                    let x: CGFloat
                    if i < halfIndex {
                        x = centerX - Layout.spacing / 2 - Layout.singleRowWidth - CGFloat(halfIndex - i - 1) * (Layout.singleRowWidth + Layout.spacing)
                    } else {
                        x = centerX + Layout.spacing / 2 + CGFloat(i - halfIndex) * (Layout.singleRowWidth + Layout.spacing)
                    }
                    layout.frame = CGRect(x: x, y: y, width: Layout.singleRowWidth, height: Layout.singleRowHeight)
                    layouts[indexPath] = layout
                }
            } else {
                for i in 0 ..< count {
                    let indexPath = IndexPath(row: i, section: 0)
                    let layout = makeLayoutAttribute(indexPath: indexPath)
                    let x = centerX - CGFloat(halfIndex - i) * (Layout.singleRowWidth + Layout.spacing) - Layout.singleRowWidth / 2
                    layout.frame = CGRect(x: x, y: y, width: Layout.singleRowWidth, height: Layout.singleRowHeight)
                    layouts[indexPath] = layout
                }
            }
        } else {
            // 居左
            for i in 0 ..< count {
                let indexPath = IndexPath(row: i, section: 0)
                let layout = makeLayoutAttribute(indexPath: indexPath)
                let x = CGFloat(i) * (Layout.singleRowWidth + Layout.spacing) + Layout.additionalSpacing + Layout.margin
                let y = Layout.top
                layout.frame = CGRect(x: x, y: y, width: Layout.singleRowWidth, height: Layout.singleRowHeight)
                layouts[indexPath] = layout
            }
        }
        layouts.forEach({ configTopBarInset(attribute: $0.value ) })
    }

    private func configTopBarInset(attribute: InMeetingCollectionViewLayoutAttributes) {
        attribute.styleConfig.meetingLayoutStyle = meetingLayoutStyle
        if self.isOverlayFullScreen {
            if !self.topBarFrame.isNull,
               self.topBarFrame.maxY > attribute.frame.minY {
                attribute.styleConfig.topBarInset = self.topBarFrame.maxY - attribute.frame.minY
            } else {
                attribute.styleConfig.topBarInset = 0
            }
        } else {
            attribute.styleConfig.topBarInset = 0
            attribute.styleConfig.bottomBarInset = 0
        }
    }

    private var errorTracked = false
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let ret = layouts.values.filter({ layout in
            layout.frame.size.width >= 1.0 && layout.frame.size.height >= 1.0 && rect.intersects(layout.frame)
        })
        if ret.count > 30 {
            let msg = "SingleRowLayout elements in rect \(rect), count: \(ret.count), cv \(self.collectionView?.bounds), last: \(ret.last?.frame)"
            Logger.grid.error(msg)
            if !errorTracked {
                errorTracked = true
                BizErrorTracker.trackBizError(key: .gridCellCount, msg)
            }
        }
        return ret
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }
        let count = collectionView.numberOfItems(inSection: 0)
        let width = max(CGFloat(count) * CGFloat(Layout.singleRowWidth + Layout.spacing) + Layout.additionalSpacing + Layout.margin + Layout.rightInset, collectionView.bounds.width)
        let contentSize = CGSize(width: width,
                                 height: collectionView.frame.size.height)
        return contentSize
    }

    private func makeLayoutAttribute(indexPath: IndexPath) -> InMeetingCollectionViewLayoutAttributes {
        let layout = InMeetingCollectionViewLayoutAttributes(forCellWith: indexPath)
        /// 默认不可见
        layout.frame = CGRect(x: -10000, y: -10000, width: 0, height: 0)

        layout.style = InMeetFlowComponent.isNewLayoutEnabled ? .singleRowSquare : .singleRow
        layout.styleConfig = .singleRow
        layout.multiResSubscribeConfig = Self.makeMultiResSubConfig(cfgs: cfgs)

        return layout
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.layouts[indexPath] ?? makeLayoutAttribute(indexPath: indexPath)
    }

    override class var layoutAttributesClass: AnyClass {
        InMeetingCollectionViewLayoutAttributes.self
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return !newBounds.size.equalTo(collectionView.bounds.size)
    }
}

extension InMeetingCollectionViewSingleRowLayout: PagedCollectionLayout {
    var pageObservable: Observable<Int> {
        .just(1)
    }
    var pageCount: Int {
        1
    }
    var visibleRange: GridVisibleRange {
        let range = collectionVisibleRange
        return .range(start: range.startIndex, end: range.endIndex, pageSize: pageSize)
    }

    private var pageSize: Int {
        guard let collectionView = self.collectionView else {
            return 3
        }
        let pageWidth = collectionView.bounds.width
        if pageWidth <= 0 {
            return 3
        }
        let space = Layout.spacing
        let width = Layout.singleRowWidth
        let margin = Layout.margin
        if InMeetFlowComponent.isNewLayoutEnabled {
            // 完整可见才认为"可见"（向下取整）
            return Int((pageWidth - margin) / (width + space))
        } else {
            // 可见宽度大于一半才认为"可见"（四舍五入）
            return lroundf(Float((pageWidth - margin) / (width + space)))
        }
    }

    var collectionVisibleRange: (startIndex: Int, endIndex: Int) {
        guard let collectionView = self.collectionView,
              collectionView.bounds.size.width > 1.0,
              collectionView.bounds.size.height > 1.0 else {
            return (0, 0)
        }
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visibleIndexPaths = collectionView.visibleCells
            .compactMap({ cell -> IndexPath? in
                    guard let indexPath = collectionView.indexPath(for: cell) else {
                        return nil
                    }
                    if InMeetFlowComponent.isNewLayoutEnabled {
                        // 完整可见才认为"可见"
                        return visibleRect.contains(cell.frame) ? indexPath : nil
                    } else {
                        // 可见宽度大于一半才认为"可见"
                        return visibleRect.contains(cell.frame.center) ? indexPath : nil
                    }
                })
                .sorted { path1, path2 in path1.row < path2.row }
        if visibleIndexPaths.isEmpty {
            return (0, 0)
        }
        let startIndex = visibleIndexPaths.first!.row
        let endIndex = visibleIndexPaths.last!.row
        return (startIndex, endIndex + 1)
    }
}

//
//  MultiPageShareOptionArea.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/17.
//

import Foundation
import UIKit

final class ShareOptionMultiLineView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    // 回调函数
    /// item点击事件
    var onItemViewClicked: ((LarkShareItemType) -> Void)?
    /// 行高改变事件
    var lineChanged: ((Int, Int) -> Void)?
    var productLevel: String = ""
    var scene: String = ""

    private var shareTypes: [LarkShareItemType]

    private(set) lazy var lines = layout.line {
        didSet {
            self.lineChanged?(lines, layout.numsOfPage)
        }
    }
    private(set) lazy var numsOfPage = layout.numsOfPage {
        didSet {
            pageControl.numberOfPages = numsOfPage
            pageControl.isHidden = !(layout.numsOfPage > 1)
            self.lineChanged?(lines, layout.numsOfPage)
        }
    }

    private lazy var multiPageContainter: UIStackView = {
        let container = UIStackView()
        container.spacing = ShareCons.defaultSpacing
        container.alignment = .center
        container.axis = .vertical
        return container
    }()

    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = layout.numsOfPage
        pageControl.pageIndicatorTintColor = ShareColor.shareUnselectedPageColor
        pageControl.currentPageIndicatorTintColor = ShareColor.shareCurrentPageColor
        pageControl.backgroundColor = .clear
        pageControl.currentPage = 0
        pageControl.size(forNumberOfPages: 4)
        pageControl.addTarget(self, action: #selector(pageChanged(_:)),
                              for: .valueChanged)
        pageControl.isHidden = !(layout.numsOfPage > 1)
        pageControl.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        return pageControl
    }()

    private lazy var layout = MultiPageShareOptionLayout(shareTypes.count, rootview: self)

    private lazy var shareOptionArea: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.insetsLayoutMarginsFromSafeArea = true
        collectionView.register(ShareOptionCell.self,
                                forCellWithReuseIdentifier: ShareOptionCell.idenContentString)
        return collectionView
    }()

    init(shareTypes: [LarkShareItemType]) {
        self.shareTypes = shareTypes
        super.init(frame: .zero)
        self.addSubview(multiPageContainter)
        multiPageContainter.addArrangedSubview(shareOptionArea)
        multiPageContainter.addArrangedSubview(pageControl)

        multiPageContainter.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        shareOptionArea.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }

        pageControl.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(ShareCons.sharePageIndicatorHeight)
        }

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }

    func update() {
        layout.update()
        self.lines = layout.line
        self.numsOfPage = layout.numsOfPage
        self.shareOptionArea.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shareTypes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShareOptionCell.idenContentString,
                                                         for: indexPath) as? ShareOptionCell {
            let type = shareTypes[indexPath.row]
            cell.configure(type: type)
            return cell
        } else {
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let type = shareTypes[indexPath.item]
        self.onItemViewClicked?(type)
    }

    // UIScrollViewDelegate方法，每次滚动结束后调用
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 通过scrollView内容的偏移计算当前显示的是第几页
        let page = Int(shareOptionArea.contentOffset.x / shareOptionArea.frame.size.width)
        // 设置pageController的当前页
        if pageControl.currentPage != page {
            if pageControl.currentPage > page {
                SharePanelTracker.trackerPublicSharePanelClick(productLevel: self.productLevel,
                                                               scene: self.scene,
                                                               clickItem: nil,
                                                               clickOther: "turn_page",
                                                               panelType: .actionPanel,
                                                               extra: ["turn_page_type": "left_turn"])
            } else {
                SharePanelTracker.trackerPublicSharePanelClick(productLevel: self.productLevel,
                                                               scene: self.scene,
                                                               clickItem: nil,
                                                               clickOther: "turn_page",
                                                               panelType: .actionPanel,
                                                               extra: ["turn_page_type": "right_turn"])
            }
        }

        pageControl.currentPage = page
    }

    // 点击页控件时事件处理
    @objc
    func pageChanged(_ sender: UIPageControl) {
        let index = IndexPath(item: sender.currentPage * layout.cols * layout.line, section: shareOptionArea.numberOfSections - 1)
        shareOptionArea.scrollToItem(at: index,
                                     at: .left,
                                     animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MultiPageShareOptionLayout: UICollectionViewFlowLayout {

    weak var rootview: UIView?
    private var dataSourceCount: Int
    /// 列数，默认为5
    private(set) var cols: Int = 5
    /// 行数，默认为2
    private(set) var line: Int = 2
    /// 页数
    private(set) var numsOfPage: Int = 2
    /// contentSize的最大宽度
    private(set) var maxWidth: CGFloat = 0
    private lazy var itemWidth: CGFloat = ShareCons.shareCellItemSize.width
    private lazy var itemHeight: CGFloat = ShareCons.shareCellItemSize.height
    private lazy var itemMinSpacing: CGFloat = ShareCons.shareIconMinSpacing
    private lazy var itemCurrentSpacing: CGFloat = ShareCons.defaultSpacing
    /// 布局frame数组
    private lazy var layoutAttributeArray: [UICollectionViewLayoutAttributes] = []

    init(_ dataSourceCount: Int, rootview: UIView) {
        self.rootview = rootview
        self.dataSourceCount = dataSourceCount
        super.init()
    }

    public func update() {
        calculateCurrentCols()
        calculateCurrentLine()
        calculateCurrentNumsOfPage()
        calculateCurrentSpacing()
    }

    private func calculateCurrentCols() {
        guard let rootview = rootview else { return }
        let width: CGFloat = rootview.bounds.width == 0 ? 375 : rootview.bounds.width
        let remainWidth = width - ShareCons.defaultSpacing * 2
        self.cols = Int((remainWidth + ShareCons.shareIconMinSpacing) / (itemWidth + ShareCons.shareIconMinSpacing))
    }

    private func calculateCurrentLine() {
        if dataSourceCount <= cols {
            self.line = 1
        } else {
            self.line = 2
        }
    }

    private func calculateCurrentNumsOfPage() {
        if dataSourceCount % (cols * line) == 0 {
            self.numsOfPage = dataSourceCount / (cols * line)
        } else {
            self.numsOfPage = dataSourceCount / (cols * line) + 1
        }
    }

    private func calculateCurrentSpacing() {
        guard let rootview = rootview else {
            return
        }
        let currentWidth = rootview.bounds.width - ShareCons.defaultSpacing * 2 - itemWidth * CGFloat(cols)
        self.itemCurrentSpacing = currentWidth / CGFloat(cols - 1)
    }

    private func preSetting() {
        minimumInteritemSpacing = self.itemCurrentSpacing
        minimumLineSpacing = ShareCons.defaultSpacing
        itemSize = ShareCons.shareCellItemSize
        scrollDirection = .horizontal
        sectionInset = UIEdgeInsets(top: 0,
                                    left: ShareCons.defaultSpacing,
                                    bottom: 0,
                                    right: ShareCons.defaultSpacing)
    }

    /// 重写Prepare方法，准备要缓存的布局对象
    public override func prepare() {
        super.prepare()
        preSetting()
        guard let collectionView = collectionView else { return }
        // 求出对应的组数
        let sections = collectionView.numberOfSections
        // 每个item所在组的 前面总的页数
        var prePageCount: Int = 0
        for i in 0..<sections {
            // 每组的item的总的个数
            let itemCount = collectionView.numberOfItems(inSection: i)
            for j in 0..<itemCount {
                let indexPath = IndexPath(item: j, section: i)
                let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                // item 在 这一组内处于第几页
                let page = j / (cols * line)
                // item 在每一页内是处于第几个
                let index = j % (cols * line)

                // item的y值
                let itemY = sectionInset.top + (itemHeight + minimumLineSpacing) * CGFloat(index / cols)
                // item的x值 为 左切距 + 前面页数宽度 + 在本页中的X值
                let itemX = sectionInset.left + CGFloat(prePageCount + page) * collectionView.bounds.width + (itemWidth + minimumInteritemSpacing) * CGFloat(index % cols)
                attr.frame = CGRect(x: itemX, y: itemY, width: itemWidth, height: itemHeight)
                layoutAttributeArray.append(attr)
            }
            // 重置 PrePageCount
            prePageCount += (itemCount - 1) / (cols * line) + 1
        }
        // 最大宽度
        maxWidth = CGFloat(prePageCount) * collectionView.bounds.width
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: maxWidth, height: 0)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // 找出相交的那些，别全部返回
        return layoutAttributeArray.filter { $0.frame.intersects(rect) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

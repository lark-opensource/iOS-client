//
//  BrowserSideMenu.swift
//  SpaceKit
//
//  Created by Webster on 2019/4/22.
//

import SKFoundation
import UIKit
import CoreGraphics
import SKCommon
import SKUIKit
import UniverseDesignColor
import SpaceInterface

protocol BrowserCatalogSideViewDelegate: AnyObject {
    /// 目录项点击的回调
    func didClicked(_ item: CatalogItemDetail, atIndex: Int, sideView: BrowserCatalogSideView)
    func didReceivePan(gesture: UIPanGestureRecognizer)
}

class BrowserCatalogSideView: UIView {
    /// Delegate
    weak var delegate: BrowserCatalogSideViewDelegate?
    private var enableZoomFontSize: Bool = false
    /// layout etc
    private let cellLinePadding: CGFloat = 4
    private let collectionLeftPadding: CGFloat = 18
    private let collectionRightPadding: CGFloat = 44
    private let collectionItemWidth: CGFloat = 144
    /// 目录的详细信息
    private var catalogItems: [CatalogItemDetail] = [CatalogItemDetail]()
    /// 从小到大排好序的目录上边距距离
    private var sortedYOffset: [CGFloat] = [CGFloat]()
    /// 上次计算的collectionView偏移
    private var collectionOldYOffset: CGFloat = -100
    private var lastSelectId: Int = -1
    /// 底部白色渐变背景
    private lazy var backLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        return layer
    }()
    /// cell resuse id
    private let cellReuseIdentifier = "com.bytedance.ee.doc.BrowserCatalogSideView"
    /// 触控反馈
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    /// collectionView layout
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: collectionItemWidth, height: CatalogSideCell.cellHeight)
        layout.minimumLineSpacing = cellLinePadding
        return layout
    }()

    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [] // 目录这里的防护不需要toast
        return preventer
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(CatalogSideCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        view.dataSource = self
        view.delegate = self
        view.clipsToBounds = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        return view
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        backLayer.frame = self.bounds
    }

    init(frame: CGRect, docsType: DocsType, items: [CatalogItemDetail]) {
        super.init(frame: frame)
        self.enableZoomFontSize = docsType == .doc
        self.backgroundColor = .clear
        catalogItems = items
        makeSortedYOffset()
        self.layer.addSublayer(backLayer)
        setupBackLayer()
        let containerView: UIView
        if ViewCapturePreventer.isFeatureEnable {
            containerView = viewCapturePreventer.contentView
            addSubview(containerView)
            containerView.snp.makeConstraints {
               $0.edges.equalToSuperview()
            }
        } else {
            containerView = self
        }
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(collectionLeftPadding)
            make.top.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(collectionItemWidth)
        }
        collectionView.reloadData()
        feedbackGenerator.prepare()
    
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture(gesture:)))
        self.addGestureRecognizer(panGesture)
        
    }

    private func setupBackLayer() {
        let white = UDColor.bgBody
        // bugfix: darkmode 切换颜色不自动跟随问题 https://bytedance.feishu.cn/wiki/wikcn4gyLzavJWslDM71lnydJye#25JEG6
        backLayer.ud.setColors([white.withAlphaComponent(0), white.withAlphaComponent(0.9), white, white])
        backLayer.locations = [NSNumber(0.0), NSNumber(0.165), NSNumber(0.32), NSNumber(1.0)]
        backLayer.startPoint = CGPoint(x: 0, y: 0)
        backLayer.endPoint = CGPoint(x: 1, y: 0)
    }

    @objc
    func didReceivePanGesture(gesture: UIPanGestureRecognizer) {
        delegate?.didReceivePan(gesture: gesture)
    }

    func update(_ items: [CatalogItemDetail], reload: Bool) {
        lastSelectId = -1
        catalogItems = items
        makeSortedYOffset()
        if reload {
            collectionView.reloadData()
        }
    }

    class func findIndex(datas: [CatalogItemDetail], scrollOffset: CGFloat, indicatorOffset: CGFloat) -> Int {
        let yDatas = datas.map { (item) -> CGFloat in return item.yOffset }
        guard yDatas.count > 0 else { return 0 }
        let titleTopPadding = (CatalogSideCell.cellHeight - CatalogSideCell.titleHeight) / 2.0
        let yOffset = scrollOffset + indicatorOffset + titleTopPadding
        var index = BrowserCatalogSideView.findLastLargerOfEqual(target: yOffset, data: yDatas)
        let maxIndex = datas.count - 1
        index = min(max(0, index), maxIndex)
        return index
    }

    private func currentIndex(contentOffsetY: CGFloat, indicatorOffsetY: CGFloat) -> Int {
        let currentItems = catalogItems
        guard currentItems.count > 0 else {
            return -1
        }
        let titleTopPadding = (CatalogSideCell.cellHeight - CatalogSideCell.titleHeight) / 2.0
        let yOffset = contentOffsetY + indicatorOffsetY + titleTopPadding
        var index = BrowserCatalogSideView.findLastLargerOfEqual(target: yOffset, data: sortedYOffset)
        let maxIndex = currentItems.count - 1
        index = min(max(0, index), maxIndex)
        //如果yoffset < 0 说明前端还没准备好位置信息，返回0
        if currentItems[index].yOffset < 0 {
            index = 0
        }
        return index
    }

    /// contentOffsetY：当前webview滚动的OffsetY
    /// indicatorOffsetY：当前indicator滚动的OffsetY
    func resetIndex(contentOffsetY: CGFloat, indicatorOffsetY: CGFloat) {
        let index = currentIndex(contentOffsetY: contentOffsetY, indicatorOffsetY: indicatorOffsetY)
        let offsetCount: CGFloat = index >= 1 ? CGFloat(index) : 0.0
        //当前命中的cell,距离collectionView最顶部的距离
        let indexViewTopDistance = offsetCount * (cellLinePadding + CatalogSideCell.cellHeight)
        // 要跟随到手，当前collection可能需要的偏移量
        let tryOffset = (indexViewTopDistance - indicatorOffsetY)
        let maxOffset = collectionView.contentSize.height - collectionView.frame.height
        var topPadding: CGFloat = 0
        if tryOffset >= 0, tryOffset <= maxOffset {
            collectionView.setContentOffset(CGPoint(x: 0, y: tryOffset), animated: false)
        } else if tryOffset < 0 {
            collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            topPadding = -tryOffset
        } else if tryOffset >= 0, tryOffset > maxOffset {
            collectionView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
            topPadding = maxOffset - tryOffset
        }
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.collectionView.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(topPadding)
            }
        })
        if lastSelectId >= 0 {
            let dimView = collectionView.cellForItem(at: IndexPath(row: lastSelectId, section: 0)) as? CatalogSideCell
            dimView?.lightUp(false)
        }
        let lightView = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? CatalogSideCell
        lightView?.lightUp(true)
        if lastSelectId != index {
            lastSelectId = index
            feedbackGenerator.impactOccurred()
        }
    }

    private func makeSortedYOffset() {
        let unZeroCatalogItems = catalogItems.filter { (item) -> Bool in
            return item.yOffset >= 0
        }
        var yOffsetInfos = unZeroCatalogItems.map { (item) -> CGFloat in return item.yOffset }
        yOffsetInfos.sort { $0 <= $1 }
        sortedYOffset = yOffsetInfos
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func findLastLargerOfEqual(target: CGFloat, data: [CGFloat]) -> Int {
        let tempArray = data
        let count = tempArray.count
        guard count > 0 else { return -1 }
        var start: Int = 0
        var end: Int = count - 1
        while start <= end {
            let mid = (start + end) / 2
            if tempArray[mid] <= target {
                start = mid + 1
            } else {
                end = mid - 1
            }
        }
        if start == 0 {
            return -1
        }
        return start - 1
    }
}

extension BrowserCatalogSideView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return catalogItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let cell = cell1 as? CatalogSideCell else {
            return cell1
        }
        cell.configure(by: catalogItems[indexPath.row], enableZoomFontSize: self.enableZoomFontSize)
        cell.lightUp(indexPath.row == lastSelectId)
        return cell
    }
}

extension BrowserCatalogSideView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row >= 0, indexPath.row < catalogItems.count else {
            return
        }
        delegate?.didClicked(catalogItems[indexPath.row], atIndex: indexPath.row, sideView: self)
    }
}

// MARK: - 防截图
extension BrowserCatalogSideView {
    
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}

/// 侧边目录栏的item cell
private class CatalogSideCell: UICollectionViewCell {

    static let titleHeight: CGFloat = 20
    static let topPadding: CGFloat = 12
    static var cellHeight: CGFloat = 44

    private var defaultAllWidth: CGFloat = 144
    private var titlePadding: CGFloat = 16
    private lazy var container: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        view.backgroundColor = .clear
        return view
    }()

    private var titleLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        addSubview(container)
        container.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    func configure(by item: CatalogItemDetail, enableZoomFontSize: Bool) {
        guard shouldReMakeTitleLabel(txt: item.title) else { return }
        titleLabel?.removeFromSuperview()
        titleLabel = nil
        if enableZoomFontSize {
            CatalogSideCell.cellHeight = CatalogSideCell.topPadding * 2 + CatalogSideCell.titleHeight.auto(.s4)
        }
        let titleMaxWidth = defaultAllWidth - titlePadding * 2
        let tempTitleLabel = makeTitleLabel(enableZoomFontSize: enableZoomFontSize)
        tempTitleLabel.text = item.title
        tempTitleLabel.sizeToFit()
        let dstWidth = min(titleMaxWidth, tempTitleLabel.frame.size.width)
        var containerWidth = dstWidth + titlePadding * 2
        if containerWidth <= 50 {
            containerWidth = 50
        }
        titleLabel = makeTitleLabel(enableZoomFontSize: enableZoomFontSize)
        titleLabel?.text = item.title
        container.snp.remakeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.height.equalToSuperview()
             make.width.equalTo(containerWidth)
        }
        if let newLabel = titleLabel {
            container.addSubview(newLabel)
            let titleHeight = enableZoomFontSize ? CatalogSideCell.titleHeight.auto(.s4) : CatalogSideCell.titleHeight
            newLabel.snp.remakeConstraints { (make) in
                make.width.equalTo(dstWidth)
                make.height.equalTo(titleHeight)
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        }
        self.layoutIfNeeded()
    }

    private func shouldReMakeTitleLabel(txt: String) -> Bool {
        if let label = titleLabel, label.text != txt {
            return true
        }
        return titleLabel == nil
    }

    func lightUp(_ light: Bool) {
        let highlightColor = UDColor.N700
        let dstColor: UIColor = light ? highlightColor : .clear
        container.backgroundColor = dstColor

        let txtColor = UDColor.textTitle
        let dstTxtColor = light ? UDColor.N100 : txtColor
        titleLabel?.textColor = dstTxtColor
    }

    private func makeTitleLabel(enableZoomFontSize: Bool) -> UILabel {
        let label = UILabel()
        label.textColor = UDColor.N900
        label.textAlignment = .right
        label.font = enableZoomFontSize ? UIFont.ud.body1(.s4) : UIFont(name: "PingFangSC-Medium", size: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

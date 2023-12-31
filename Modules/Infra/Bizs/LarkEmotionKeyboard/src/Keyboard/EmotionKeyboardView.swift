//
//  EmotionKeyboardView.swift
//  LarkUIKit
//
//  Created by 李晨 on 2019/8/13.
//

import Foundation
import UIKit
import SnapKit

public final class EmotionKeyboardView: UIView {
    /// 下方展示emotion来源的collectionView
    public fileprivate(set) var dataSourceCollection: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    /// 上方展示表情的collectionView
    public fileprivate(set) var emotionPanelCollection: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())

    public fileprivate(set) var emotionLayout: UICollectionViewFlowLayout
    public fileprivate(set) var sourceLayout: UICollectionViewFlowLayout

    public fileprivate(set) var dataSourceItems: [EmotionItemDataSourceItem] = [] {
        didSet {
            dataSourceItems.forEach { (item) in
                if let set = item as? EmotionItemDataSourceSet {
                    set.setupEmotion(keyboard: self)
                }
            }
        }
    }

    public var dataSources: [EmotionItemDataSource] {
        var allDataSource: [EmotionItemDataSource] = []
        for item in self.dataSourceItems {
            if let dataSource = item as? EmotionItemDataSource {
                allDataSource.append(dataSource)
            } else if let dataSourceSet = item as? EmotionItemDataSourceSet {
                allDataSource.append(contentsOf: dataSourceSet.sourceItems())
            }
        }
        return allDataSource
    }

    fileprivate weak var actionView: UIView?

    fileprivate var leftView: UIView?
    fileprivate var leftViewWidth: CGFloat = 0

    fileprivate var excludeSendBtn = false {
        didSet {
            if oldValue != excludeSendBtn {
                self.updateActionBarView()
            }
        }
    }

    fileprivate var bottomContainer: UIView = UIView()
    fileprivate var bottomPlaceholderView: UIView = UIView()

    private let cellDidSelectedColor: UIColor

    fileprivate(set) var emotionCache: [String: EmotionKeyboardItemView] = [:]

    public var bottomBarHeight: CGFloat = 40 {
        didSet {
            bottomContainer.snp.remakeConstraints({ make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.bottomPlaceholderView.snp.top)
                make.height.equalTo(self.bottomBarHeight)
            })
            if self.bottomBarHeight <= 0 {
                assert(self.bottomBarHeight == 0, "self.bottomBarHeight < 0")
                self.sourceLayout.itemSize = CGSize(width: 50, height: 1)
            } else {
                self.sourceLayout.itemSize = CGSize(width: 50, height: self.bottomBarHeight)
            }
            self.dataSourceCollection.reloadData()
        }
    }

    public var actionBtnHidden: Bool {
        didSet {
            self.updateActionBarView()
        }
    }

    public var bottomContainerHidden: Bool = false {
        didSet {
            self.bottomContainer.isHidden = bottomContainerHidden
        }
    }

    public var bottomPlaceholderViewHidden: Bool = false {
        didSet {
            self.bottomPlaceholderView.isHidden = bottomPlaceholderViewHidden
        }
    }

    public fileprivate(set) var selectedIndex: Int = 0 {
        didSet {
            selectedIndex = min(max(0, selectedIndex), self.dataSources.count)
            self.updateActionBarView(syncLayout: true)
            self.updateActionBarEnable()
            self.updateSelectSourceOffset()
            self.selectedID = self.dataSources[selectedIndex].identifier
            if selectedIndex != oldValue { self.dataSources[selectedIndex].didSwitch() }
        }
    }

    public fileprivate(set) var selectedID: String?

    private var originSize: CGSize = .zero

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        // 视图被重新添加，显示在屏幕上
        if newSuperview != nil { self.dataSources[self.selectedIndex].didSelect() }
    }

    public func setSelectIndex(index: Int, animation: Bool) {
        self.selectedIndex = index
        self.dataSources[self.selectedIndex].didSelect()
        let offset = CGPoint(
            x: self.emotionPanelCollection.bounds.width * CGFloat(index),
            y: 0
        )
        self.emotionPanelCollection.setContentOffset(offset, animated: animation)
    }

    public func setupEmotions(dataSources: [EmotionItemDataSourceItem]) {
        self.dataSourceItems = dataSources
        self.emotionPanelCollection.reloadData()
        self.dataSourceCollection.reloadData()

        self.selectedIndex = 0
        self.emotionPanelCollection.contentOffset = CGPoint(x: 0, y: 0)
        self.dataSourceCollection.contentOffset = CGPoint(x: 0, y: 0)
        self.updateActionBarView()
        self.updateActionBarEnable()
    }

    public func append(dataSources: [EmotionItemDataSourceItem]) {
        self.dataSourceItems.append(contentsOf: dataSources)
        self.emotionPanelCollection.reloadData()
        self.dataSourceCollection.reloadData()
    }

    public func delete(index: Int) {
        self.dataSourceItems.remove(at: index)
        self.emotionPanelCollection.reloadData()
        self.dataSourceCollection.reloadData()
        if self.selectedIndex > index {
            self.setSelectIndex(index: self.selectedIndex - 1, animation: false)
        }
    }

    public func keyboardStatusChange(isFold: Bool) {
        self.dataSources.forEach { item in
            item.onKeyboardStatusChange(isFold: isFold)
        }
    }

    public func reloadEmotionKeyboard() {
        let selectedID = self.selectedID ?? ""

        self.dataSourceCollection.reloadData()
        self.emotionPanelCollection.reloadData()

        var selectIndex: Int = 0
        if !selectedID.isEmpty, let index = self.dataSources.firstIndex(where: { (item) -> Bool in
            return item.identifier == selectedID
        }) {
            selectIndex = index
        }
        self.setSelectIndex(index: selectIndex, animation: false)
    }

    /// update action view and left view
    /// - Parameter syncLayout: Default is false, if Yes, self.view layoutIfNeeded immediately
    public func updateActionBarView(syncLayout: Bool = false) {
        guard self.selectedIndex < self.dataSources.count else { return }
        self.actionView?.removeFromSuperview()
        self.actionView = nil

        var rightOffset: CGFloat = 0
        var leftOffset: CGFloat = 0

        if let leftView = self.leftView {
            self.bottomContainer.addSubview(leftView)
            leftView.snp.remakeConstraints({ make in
                make.top.left.bottom.equalToSuperview()
                make.width.equalTo(self.leftViewWidth)
            })
            leftOffset = self.leftViewWidth
        }

        if !self.actionBtnHidden {
            let actionWidth = self.dataSources[self.selectedIndex].emotionActionViewWidth()
            if let actionView = self.dataSources[self.selectedIndex].emotionActionView(excludeSendBtn: excludeSendBtn) {
                self.actionView = actionView
                self.bottomContainer.addSubview(actionView)
                actionView.snp.remakeConstraints({ make in
                    make.top.right.bottom.equalToSuperview()
                    make.width.equalTo(actionWidth)
                })
            }
            rightOffset = actionWidth
        }

        self.dataSourceCollection.snp.remakeConstraints({ make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-rightOffset)
            make.left.equalToSuperview().offset(leftOffset)
        })
        if syncLayout {
            self.layoutIfNeeded()
        }
    }

    public func updateActionBarEnable() {
        self.dataSources[self.selectedIndex].updateActionBtnIfNeeded()
    }

    public func updateSendBtnIfNeed(hidden: Bool) {
        self.excludeSendBtn = hidden
    }

    private func initEmotionPanel() {
        let emotionPanelCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: emotionLayout)
        emotionPanelCollection.backgroundColor = UIColor.ud.bgBase
        emotionPanelCollection.showsVerticalScrollIndicator = false
        emotionPanelCollection.showsHorizontalScrollIndicator = false
        emotionPanelCollection.isPagingEnabled = true
        emotionPanelCollection.dataSource = self
        emotionPanelCollection.delegate = self
        self.addSubview(emotionPanelCollection)
        emotionPanelCollection.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        let emotionCellName = String(describing: EmotionItemCell.self)
        emotionPanelCollection.register(EmotionItemCell.self, forCellWithReuseIdentifier: emotionCellName)
        self.emotionPanelCollection = emotionPanelCollection

        let bottomPlaceholderView = UIView()
        self.bottomPlaceholderView = bottomPlaceholderView
        self.addSubview(bottomPlaceholderView)
        bottomPlaceholderView.backgroundColor = UIColor.ud.bgBody
        bottomPlaceholderView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    private func initDataSourcePanel() {
        let dataSourceCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.sourceLayout)
        dataSourceCollection.backgroundColor = UIColor.clear
        dataSourceCollection.showsVerticalScrollIndicator = false
        dataSourceCollection.showsHorizontalScrollIndicator = false
        dataSourceCollection.dataSource = self
        dataSourceCollection.delegate = self
        bottomContainer.addSubview(dataSourceCollection)
        dataSourceCollection.snp.makeConstraints({ make in
            make.top.right.left.bottom.equalToSuperview()
        })
        let cellName = String(describing: EmotionSourceItemCell.self)
        dataSourceCollection.register(EmotionSourceItemCell.self, forCellWithReuseIdentifier: cellName)
        self.dataSourceCollection = dataSourceCollection
    }

    /// init
    public init(config: EmotionKeyboardViewConfig, dataSources: [EmotionItemDataSourceItem]) {
        self.cellDidSelectedColor = config.cellDidSelectedColor
        self.emotionLayout = config.emotionLayout
        self.sourceLayout = config.sourceLayout
        self.actionBtnHidden = config.actionBtnHidden

        super.init(frame: .zero)

        self.backgroundColor = config.backgroundColor

        // 初始化EmotionPanel
        self.initEmotionPanel()

        // 底部区域容器
        let bottomContainer = UIView()
        bottomContainer.layer.masksToBounds = true
        bottomContainer.backgroundColor = UIColor.ud.bgBody
        self.addSubview(bottomContainer)
        self.bottomContainer = bottomContainer
        bottomContainer.snp.remakeConstraints({ make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.bottomPlaceholderView.snp.top)
            make.height.equalTo(self.bottomBarHeight)
        })

        // 表情集合
        self.initDataSourcePanel()

        self.setupEmotions(dataSources: dataSources)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.frame.size != self.originSize {
            self.emotionLayout.itemSize = self.bounds.size
            self.emotionLayout.invalidateLayout()
            self.emotionPanelCollection.reloadData()
            DispatchQueue.main.async {
                // update emotion collection offset when view size change
                self.setSelectIndex(index: self.selectedIndex, animation: false)
            }
            self.originSize = self.frame.size
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToSuperview()
        if let controller = EmotionKeyboardView.getViewController(view: self),
            let navgation = controller.navigationController {
            if let edgePanGesture = navgation.view
                .gestureRecognizers?.first(where: { $0 is UIScreenEdgePanGestureRecognizer }) {
                edgePanGesture.require(toFail: dataSourceCollection.panGestureRecognizer)
                edgePanGesture.require(toFail: emotionPanelCollection.panGestureRecognizer)
            }
        }
    }

    @available(iOS 11.0, *)
    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        bottomPlaceholderView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(self.safeAreaInsets.bottom)
        }
    }

    public func setLeftView(view: UIView?, width: CGFloat) {
        if self.leftView != view {
            self.leftView?.removeFromSuperview()
        }
        self.leftView = view
        self.leftViewWidth = width
        self.updateActionBarView()
    }

    private static func getViewController(view: UIView) -> UIViewController? {
        if let next = view.next as? UIViewController {
            return next
        } else if let next = view.next as? UIView {
            return getViewController(view: next)
        }
        return nil
    }

    private func updateSelectSourceOffset() {
        self.dataSourceCollection.reloadData()
        let minX = self.dataSourceCollection.contentOffset.x
        let maxX = minX + self.dataSourceCollection.frame.width
        guard let attributes = self.dataSourceCollection
            .layoutAttributesForItem(
                at: IndexPath(row: self.selectedIndex, section: 0)
            ) else {
                return
            }
        let itemFrame = attributes.frame
        if itemFrame.minX < minX {
            self.dataSourceCollection.setContentOffset(CGPoint(x: itemFrame.minX, y: 0), animated: true)
        } else if itemFrame.maxX > maxX {
            self.dataSourceCollection.setContentOffset(CGPoint(
                x: itemFrame.maxX - self.dataSourceCollection.frame.width,
                y: 0
            ), animated: true)
        }
    }

    private func getEmotionView(_ source: EmotionItemDataSource) -> UIView {
        if let emotionView = self.emotionCache[source.identifier] {
            emotionView.source = source
            emotionView.bottomBarHeight = self.bottomBarHeight
            return emotionView
        }
        let emotionView = EmotionKeyboardItemView(source: source)
        emotionView.bottomBarHeight = self.bottomBarHeight
        self.emotionCache[source.identifier] = emotionView
        return emotionView
    }
}

extension EmotionKeyboardView: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSources.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let source = self.dataSources[indexPath.row]

        if collectionView == self.emotionPanelCollection {
            let name = String(describing: EmotionItemCell.self)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
            if let collectionCell = cell as? EmotionItemCell {
                collectionCell.set(emotionView: self.getEmotionView(source))
            }
            return cell
        } else if collectionView == self.dataSourceCollection {
            let name = String(describing: EmotionSourceItemCell.self)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
            if let collectionCell = cell as? EmotionSourceItemCell {
                collectionCell.cellDidSelectedColor = self.cellDidSelectedColor
                collectionCell.index = indexPath.row
                source.setupSourceIconImage { (image) in
                    if collectionCell.index == indexPath.row {
                        collectionCell.sourceIcon.image = image
                    }
                }
                collectionCell.shouldSelected = indexPath.row == self.selectedIndex
            }
            return cell
        }
        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.emotionPanelCollection {
            collectionView.deselectItem(at: indexPath, animated: false)
        } else if collectionView == self.dataSourceCollection {
            if self.selectedIndex != indexPath.row {
                self.setSelectIndex(index: indexPath.row, animation: false)
            }
        }
    }
}

extension EmotionKeyboardView: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == self.emotionPanelCollection {
            self.updateSelectedIndexWhenScroll()
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.emotionPanelCollection {
            self.updateSelectedIndexWhenScroll()
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView == self.emotionPanelCollection {
            self.scrollViewDidEndDecelerating(scrollView)
        }
    }

    private func updateSelectedIndexWhenScroll() {
        let pageWidth: CGFloat = self.emotionPanelCollection.frame.size.width
        guard pageWidth > 0 else { return }
        let page = Int(self.emotionPanelCollection.contentOffset.x / pageWidth)
        if self.selectedIndex != page {
            self.selectedIndex = page
        }
    }
}

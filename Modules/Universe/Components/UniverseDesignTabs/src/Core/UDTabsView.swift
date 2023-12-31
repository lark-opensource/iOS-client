//
//  UDTabsView.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit
import UniverseDesignColor

/// 选中item时的类型
public enum UDTabsViewItemSelectedType {
    /// unknown: 不是选中
    case unknown
    /// code: 通过代码调用方法`func selectItemAt(index: Int)`选中
    case code
    /// click: 通过点击item选中
    case click
    /// scroll: 通过滚动到item选中
    case scroll
}

/// 为什么会把选中代理分为三个，因为有时候只关心点击选中的，有时候只关心滚动选中的，有时候只关心选中。所以具体情况，使用对应方法。
public protocol UDTabsViewDelegate: AnyObject {
    /// 点击选中或者滚动选中都会调用该方法。适用于只关心选中事件，而不关心具体是点击还是滚动选中的情况。
    ///
    /// - Parameters:
    ///   - tabsView: UDTabsView
    ///   - index: 选中的index
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int)

    /// 点击选中的情况才会调用该方法
    ///
    /// - Parameters:
    ///   - tabsView: UDTabsView
    ///   - index: 选中的index
    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int)

    /// 滚动选中的情况才会调用该方法
    ///
    /// - Parameters:
    ///   - tabsView: UDTabsView
    ///   - index: 选中的index
    func tabsView(_ tabsView: UDTabsView, didScrollSelectedItemAt index: Int)

    /// 正在滚动中的回调
    ///
    /// - Parameters:
    ///   - tabsView: UDTabsView
    ///   - leftIndex: 正在滚动中，相对位置处于左边的index
    ///   - rightIndex: 正在滚动中，相对位置处于右边的index
    ///   - percent: 从左往右计算的百分比
    func tabsView(_ tabsView: UDTabsView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat)

    /// 是否允许点击选中目标index的item
    ///
    /// - Parameters:
    ///   - tabsView: UDTabsView
    ///   - index: 目标index
    func tabsView(_ tabsView: UDTabsView, canClickItemAt index: Int) -> Bool

    /// 通知代理 UDTabsView 将开始手势滑动
    func tabsViewWillBeginDragging(_ tabsView: UDTabsView)

    /// 通知代理 UDTabsView 已停止手势滑动
    func tabsViewDidEndDragging(_ tabsView: UDTabsView)
}

/// 提供UDTabsViewDelegate的默认实现，这样对于遵从UDTabsViewDelegate的类来说，所有代理方法都是可选实现的。
public extension UDTabsViewDelegate {
    /// 选中Item
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) { }
    /// 点击选中的情况才会调用该方法
    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) { }
    /// 滚动选中的情况才会调用该方法
    func tabsView(_ tabsView: UDTabsView, didScrollSelectedItemAt index: Int) { }
    /// 正在滚动中的回调
    func tabsView(_ tabsView: UDTabsView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat) { }
    /// 是否允许点击选中目标index的item
    func tabsView(_ tabsView: UDTabsView, canClickItemAt index: Int) -> Bool { return true }
    /// 通知代理 UDTabsView 将开始手势滑动
    func tabsViewWillBeginDragging(_ tabsView: UDTabsView) { }
    /// 通知代理 UDTabsView 已停止手势滑动
    func tabsViewDidEndDragging(_ tabsView: UDTabsView) { }
}

/// 内部会自己找到父UIViewController，然后将其automaticallyAdjustsScrollViewInsets设置为false，这一点请知晓。
open class UDTabsView: UIView {

    open weak var delegate: UDTabsViewDelegate?
    open private(set) var collectionView: UDTabsCollectionView!
    open var isContentScrollEnabled: Bool = true {
        didSet {
            guard let contentScrollView = self.contentScrollView else { return }
            contentScrollView.isScrollEnabled = isContentScrollEnabled
        }
    }
    open var contentScrollView: UIScrollView? {
        willSet {
            contentScrollView?.removeObserver(self, forKeyPath: "contentOffset")
        }
        didSet {
            contentScrollView?.scrollsToTop = false
            contentScrollView?.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
            contentScrollView?.isScrollEnabled = self.isContentScrollEnabled
        }
    }

    var config: UDTabsViewConfig {
        return baseConfig
    }

    private var baseConfig: UDTabsViewConfig = UDTabsViewConfig()

    public var listContainer: UDTabsViewListContainer? = nil {
        didSet {
            listContainer?.defaultSelectedIndex = defaultSelectedIndex
            contentScrollView = listContainer?.contentScrollView()
        }
    }

    open var indicators = [UDTabsIndicatorProtocol]() {
        didSet {
            collectionView.indicators = indicators
        }
    }
    /// 初始化或者reloadData之前设置，用于指定默认的index
    open var defaultSelectedIndex: Int = 0 {
        didSet {
            selectedIndex = defaultSelectedIndex
            if listContainer != nil {
                listContainer?.defaultSelectedIndex = defaultSelectedIndex
            }
        }
    }
    open private(set) var selectedIndex: Int = 0

    public var animator: UDTabsAnimator?
    /// 最终传递给UDTabsView的数据源数组
    var itemDataSource = [UDTabsBaseItemModel]()

    private var innerItemSpacing: CGFloat = 0
    private var lastContentOffset: CGPoint = CGPoint.zero
    private var lastProgress: CGFloat = 0
    /// 正在滚动中的目标index。用于处理正在滚动列表的时候，立即点击item，会导致界面显示异常。
    private var scrollingTargetIndex: Int = -1
    private var isFirstLayoutSubviews = true
    private var isTabViewFrameChanged: Bool = false

    private var gradientMaskLayer: CAGradientLayer = {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.locations = [0.0, 0.875]
        gradientMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return gradientMaskLayer
    }()

    private var gradientMaskView: UIView = {
        let gradientMaskView = UIView()
        gradientMaskView.isUserInteractionEnabled = false
        return gradientMaskView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    deinit {
        animator?.stop()
        contentScrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }

    private func commonInit() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = UDTabsCollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.scrollsToTop = false
        collectionView.dataSource = self
        collectionView.delegate = self
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = false
        }
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(collectionView)
        addSubview(gradientMaskView)
        gradientMaskView.layer.insertSublayer(gradientMaskLayer, at: 0)
        setupAppearance()
    }

    func setupAppearance() {
        let startColor = config.maskColor.withAlphaComponent(0)
        let endColor = config.maskColor
        gradientMaskLayer.ud.setColors([startColor, endColor])
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        var nextResponder: UIResponder? = newSuperview
        while nextResponder != nil {
            if let parentVC = nextResponder as? UIViewController {
                parentVC.automaticallyAdjustsScrollViewInsets = false
                break
            }
            nextResponder = nextResponder?.next
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        //部分使用者为了适配不同的手机屏幕尺寸，UDTabsView的宽高比要求保持一样。
        //所以它的高度就会因为不同宽度的屏幕而不一样。
        //计算出来的高度，有时候会是位数很长的浮点数，如果把这个高度设置给UICollectionView就会触发内部的一个错误。
        //所以，为了规避这个问题，在这里对高度统一向下取整。
        //如果向下取整导致了你的页面异常，请自己重新设置UDTabsView的高度，保证为整数即可。
        let targetFrame = CGRect(x: 0, y: 0, width: bounds.size.width, height: floor(bounds.size.height))
        if isFirstLayoutSubviews {
            isFirstLayoutSubviews = false
            collectionView.frame = targetFrame
            reloadDataWithoutListContainer()
        } else {
            if collectionView.frame != targetFrame {
                collectionView.frame = targetFrame
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.reloadData()
                reloadDataWithoutListContainer()
            }
        }

        showMask()
        setupAppearance()

        gradientMaskView.frame = CGRect(x: bounds.width - config.maskWidth,
                                        y: bounds.origin.y + config.maskVerticalPadding,
                                        width: config.maskWidth,
                                        height: bounds.height - config.maskVerticalPadding * 2)
        gradientMaskLayer.frame = gradientMaskView.bounds
        
        if isTabViewFrameChanged, !itemDataSource.isEmpty {
            isTabViewFrameChanged = false
            collectionView.scrollToItem(at: IndexPath(item: self.selectedIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *),
              let previousTraitCollection = previousTraitCollection,
              previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) else {
            return
        }
        /// 切换tab时候会执行动画：preferredTitleZoomAnimateClosure
        /// 这里面计算颜色渐变过程后丢失了颜色的动态性，导致darkMode切换有问题
        /// 所以这里进行一次刷新，重新获取下配置set到UI上
        /// 比较好做法是渐变动画结束后再设置下最终颜色保持其动态性
        /// 但是考虑到使用 UDTabsViewTool.interpolateColor 地方较多，要改多处，这里直接刷新
        reloadDataWithoutListContainer()
        self.isTabViewFrameChanged = true
    }

    // MARK: - Public
    public final func dequeueReusableCell(withReuseIdentifier identifier: String, at index: Int) -> UDTabsBaseCell {
        let indexPath = IndexPath(item: index, section: 0)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        guard cell.isKind(of: UDTabsBaseCell.self) else {
            fatalError("Cell class must be subclass of UDTabsBaseCell")
        }

        if let baseCell = cell as? UDTabsBaseCell {
            baseCell.config = self.config
        }

        return cell as? UDTabsBaseCell ?? UDTabsBaseCell()
    }

    open func setConfig(config: UDTabsViewConfig = UDTabsViewConfig()) {
        self.baseConfig = config
        self.layoutSubviews()
    }

    open func getConfig() -> UDTabsViewConfig {
        return self.baseConfig
    }

    open func reloadData() {
        reloadDataWithoutListContainer()
        listContainer?.reloadData()
    }

    private func reloadDataWithoutListContainer() {
        reloadData(selectedIndex: selectedIndex)
        registerCellClass(in: self)
        if selectedIndex < 0 || selectedIndex >= itemDataSource.count {
            defaultSelectedIndex = 0
            selectedIndex = 0
        }

        innerItemSpacing = config.itemSpacing
        var totalItemWidth: CGFloat = 0
        var totalContentWidth: CGFloat = getContentEdgeInsetLeft()
        for (index, itemModel) in itemDataSource.enumerated() {
            itemModel.index = index
            itemModel.itemWidth = tabsView(widthForItemAt: index, isItemWidthZoomValid: true)
            itemModel.isSelected = (index == selectedIndex)
            totalItemWidth += itemModel.itemWidth
            if index == itemDataSource.count - 1 {
                totalContentWidth += itemModel.itemWidth + getContentEdgeInsetRight()
            } else {
                totalContentWidth += itemModel.itemWidth + innerItemSpacing
            }
        }

        if config.isItemSpacingAverageEnabled == true && totalContentWidth < bounds.size.width {
            var itemSpacingCount = itemDataSource.count - 1
            var totalItemSpacingWidth = bounds.size.width - totalItemWidth
            if config.contentEdgeInsetLeft == UDTabsViewAutomaticDimension {
                itemSpacingCount += 1
            } else {
                totalItemSpacingWidth -= config.contentEdgeInsetLeft
            }
            if config.contentEdgeInsetRight == UDTabsViewAutomaticDimension {
                itemSpacingCount += 1
            } else {
                totalItemSpacingWidth -= config.contentEdgeInsetRight
            }
            if itemSpacingCount > 0 {
                innerItemSpacing = totalItemSpacingWidth / CGFloat(itemSpacingCount)
            }
        }

        var selectedItemFrameX = innerItemSpacing
        var selectedItemWidth: CGFloat = 0
        totalContentWidth = getContentEdgeInsetLeft()
        for (index, itemModel) in itemDataSource.enumerated() {
            if index < selectedIndex {
                selectedItemFrameX += itemModel.itemWidth + innerItemSpacing
            } else if index == selectedIndex {
                selectedItemWidth = itemModel.itemWidth
            }
            if index == itemDataSource.count - 1 {
                totalContentWidth += itemModel.itemWidth + getContentEdgeInsetRight()
            } else {
                totalContentWidth += itemModel.itemWidth + innerItemSpacing
            }
        }

        let minX: CGFloat = 0
        let maxX = totalContentWidth - bounds.size.width
        let targetX = selectedItemFrameX - bounds.size.width / 2 + selectedItemWidth / 2
        collectionView.setContentOffset(CGPoint(x: max(min(maxX, targetX), minX), y: 0), animated: false)

        if contentScrollView != nil {
            if contentScrollView!.frame.equalTo(CGRect.zero) &&
                contentScrollView!.superview != nil {
                //某些情况系统会出现UDTabsView先布局，contentScrollView后布局。
                //就会导致下面指定defaultSelectedIndex失效，
                //所以发现contentScrollView的frame为zero时，强行触发其父视图链里面已经有frame的一个父视图的layoutSubviews方法。
                //比如UDTabsListContainerView会将contentScrollView包裹起来使用，该情况需要UDTabsListContainerView.superView触发布局更新
                var parentView = contentScrollView?.superview
                while parentView != nil && parentView?.frame.equalTo(CGRect.zero) == true {
                    parentView = parentView?.superview
                }
                parentView?.setNeedsLayout()
                parentView?.layoutIfNeeded()
            }

            contentScrollView!.setContentOffset(
                CGPoint(x: CGFloat(selectedIndex) * contentScrollView!.bounds.size.width
                ,
                        y: 0),
                animated: false)
        }

        for indicator in indicators {
            if itemDataSource.isEmpty {
                indicator.isHidden = true
            } else {
                indicator.isHidden = false
                let indicatorParamsModel = UDTabsIndicatorParamsModel()
                indicatorParamsModel.contentSize = CGSize(width: totalContentWidth, height: bounds.size.height)
                indicatorParamsModel.currentSelectedIndex = selectedIndex
                let selectedItemFrame = getItemFrameAt(index: selectedIndex)
                indicatorParamsModel.currentSelectedItemFrame = selectedItemFrame
                indicator.refreshIndicatorState(model: indicatorParamsModel)

                if indicator.isIndicatorConvertToItemFrameEnabled {
                    var indicatorConvertToItemFrame = indicator.frame
                    indicatorConvertToItemFrame.origin.x -= selectedItemFrame.origin.x
                    itemDataSource[selectedIndex].indicatorConvertToItemFrame = indicatorConvertToItemFrame
                }
            }
        }
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    open func reloadItem(at index: Int) {
        guard index >= 0 && index < itemDataSource.count else {
            return
        }

        refreshItemModel(itemDataSource[index], at: index, selectedIndex: selectedIndex)
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? UDTabsBaseCell
        cell?.reloadData(itemModel: itemDataSource[index], selectedType: .unknown)
    }

    /// 代码选中指定index
    /// 如果要同时触发列表容器对应index的列表加载，请再调用`listContainerView.didClickSelectedItem(at: index)`方法
    ///
    /// - Parameter index: 目标index
    open func selectItemAt(index: Int) {
        selectItemAt(index: index, selectedType: .code)
    }

    /// 配置完各种属性之后，需要手动调用该方法，更新数据源
    ///
    /// - Parameter selectedIndex: 当前选中的index
    open func reloadData(selectedIndex: Int) {
        itemDataSource.removeAll()
    }

    /// 子类需要重载该方法，用于返回自己定义的UDTabsBaseItemModel子类实例
    ///
    /// - Returns: UDTabsBaseItemModel子类实例
    open func preferredItemModelInstance() -> UDTabsBaseItemModel {
        return UDTabsBaseItemModel()
    }

    open func preferredTabsView(widthForItemAt index: Int) -> CGFloat {
        guard index >= 0 else {
            return 0
        }
        return min(config.itemWidthIncrement, config.itemMaxWidth)
    }

    open func preferredRefreshItemModel(_ itemModel: UDTabsBaseItemModel, at index: Int, selectedIndex: Int) {
        itemModel.index = index
        if index == selectedIndex {
            itemModel.isSelected = true
            itemModel.itemWidthCurrentZoomScale = config.itemWidthSelectedZoomScale
        } else {
            itemModel.isSelected = false
            itemModel.itemWidthCurrentZoomScale = config.itemWidthNormalZoomScale
        }
    }

    /// 自定义子类请继承方法`func preferredWidthForItem(at index: Int) -> CGFloat`
    public final func tabsView(widthForItemAt index: Int,
                               isItemWidthZoomValid: Bool) -> CGFloat {
        let itemWidth = preferredTabsView(widthForItemAt: index)
        if config.isItemWidthZoomEnabled && isItemWidthZoomValid {
            return itemWidth * itemDataSource[index].itemWidthCurrentZoomScale
        } else {
            return itemWidth
        }
    }

    open func registerCellClass(in tabsView: UDTabsView) {

    }

    open func tabsView(cellForItemAt index: Int) -> UDTabsBaseCell {
        let cell = UDTabsBaseCell()
        cell.config = self.config
        return cell
    }

    open func refreshItemModel(currentSelectedItemModel: UDTabsBaseItemModel,
                               willSelectedItemModel: UDTabsBaseItemModel,
                               selectedType: UDTabsViewItemSelectedType) {
        currentSelectedItemModel.isSelected = false
        willSelectedItemModel.isSelected = true

        if config.isItemWidthZoomEnabled {
            if (selectedType == .scroll && !config.isItemTransitionEnabled) ||
                selectedType == .click ||
                selectedType == .code {
                animator = UDTabsAnimator()
                animator?.duration = config.selectedAnimationDuration
                animator?.progressClosure = {[weak self] (percent) in
                    guard let self = `self` else { return }
                    currentSelectedItemModel.itemWidthCurrentZoomScale = UDTabsViewTool
                        .interpolate(from: self.config.itemWidthSelectedZoomScale,
                                     to: self.config.itemWidthNormalZoomScale,
                                     percent: percent)
                    currentSelectedItemModel.itemWidth = self.tabsView(widthForItemAt: currentSelectedItemModel.index,
                                                                       isItemWidthZoomValid: true)
                    willSelectedItemModel.itemWidthCurrentZoomScale = UDTabsViewTool
                        .interpolate(from: self.config.itemWidthNormalZoomScale,
                                     to: self.config.itemWidthSelectedZoomScale,
                                     percent: percent)
                    willSelectedItemModel.itemWidth = self.tabsView(widthForItemAt: willSelectedItemModel.index,
                                                                    isItemWidthZoomValid: true)
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                animator?.start()
            }
        } else {
            currentSelectedItemModel.itemWidthCurrentZoomScale = config.itemWidthNormalZoomScale
            willSelectedItemModel.itemWidthCurrentZoomScale = config.itemWidthSelectedZoomScale
        }
    }

    open func refreshItemModel(leftItemModel: UDTabsBaseItemModel,
                               rightItemModel: UDTabsBaseItemModel,
                               percent: CGFloat) {
        //如果正在进行itemWidth缩放动画，用户又立马滚动了contentScrollView，需要停止动画。
        animator?.stop()
        if config.isItemWidthZoomEnabled && config.isItemTransitionEnabled {
            //允许itemWidth缩放动画且允许item渐变过渡
            leftItemModel.itemWidthCurrentZoomScale = UDTabsViewTool
                .interpolate(from: config.itemWidthSelectedZoomScale,
                             to: config.itemWidthNormalZoomScale,
                             percent: percent)
            leftItemModel.itemWidth = self.tabsView(widthForItemAt: leftItemModel.index,
                                                    isItemWidthZoomValid: true)
            rightItemModel.itemWidthCurrentZoomScale = UDTabsViewTool
                .interpolate(from: config.itemWidthNormalZoomScale,
                             to: config.itemWidthSelectedZoomScale,
                             percent: percent)
            rightItemModel.itemWidth = self.tabsView(widthForItemAt: rightItemModel.index,
                                                     isItemWidthZoomValid: true)
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    /// 自定义子类请继承方法`func preferredRefreshItemModel(_ itemModel: UDTabsBaseItemModel, at index: Int, selectedIndex: Int)`
    public final func refreshItemModel(_ itemModel: UDTabsBaseItemModel,
                                       at index: Int,
                                       selectedIndex: Int) {
        preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
    }

    public func selectItemAt(index: Int, selectedType: UDTabsViewItemSelectedType) {
        guard index >= 0 && index < itemDataSource.count else {
            return
        }

        if index == selectedIndex {
            if selectedType == .code {
                listContainer?.didClickSelectedItem(at: index)
            } else if selectedType == .click {
                delegate?.tabsView(self, didClickSelectedItemAt: index)
                listContainer?.didClickSelectedItem(at: index)
            } else if selectedType == .scroll {
                delegate?.tabsView(self, didScrollSelectedItemAt: index)
            }
            delegate?.tabsView(self, didSelectedItemAt: index)
            scrollingTargetIndex = -1
            return
        }

        let currentSelectedItemModel = itemDataSource[selectedIndex]
        let willSelectedItemModel = itemDataSource[index]
        refreshItemModel(currentSelectedItemModel: currentSelectedItemModel,
                         willSelectedItemModel: willSelectedItemModel,
                         selectedType: selectedType)

        let currentSelectedCell = collectionView
            .cellForItem(at: IndexPath(item: selectedIndex, section: 0)) as? UDTabsBaseCell
        currentSelectedCell?.reloadData(itemModel: currentSelectedItemModel, selectedType: selectedType)

        let willSelectedCell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? UDTabsBaseCell
        willSelectedCell?.reloadData(itemModel: willSelectedItemModel, selectedType: selectedType)

        if scrollingTargetIndex != -1 && scrollingTargetIndex != index {
            let scrollingTargetItemModel = itemDataSource[scrollingTargetIndex]
            scrollingTargetItemModel.isSelected = false
            refreshItemModel(currentSelectedItemModel: scrollingTargetItemModel,
                             willSelectedItemModel: willSelectedItemModel,
                             selectedType: selectedType)
            let scrollingTargetCell = collectionView
                .cellForItem(at: IndexPath(item: scrollingTargetIndex, section: 0)) as? UDTabsBaseCell
            scrollingTargetCell?.reloadData(itemModel: scrollingTargetItemModel, selectedType: selectedType)
        }

        if config.isItemWidthZoomEnabled == true {
            if selectedType == .click || selectedType == .code {
                //延时为了解决cellwidth变化，点击最后几个cell，scrollToItem会出现位置偏移bu。需要等cellWidth动画渐变结束后再滚动到index的cell位置。
                let selectedAnimationDurationInMilliseconds = Int((config
                                                                    .selectedAnimationDuration) * 1000)
                DispatchQueue.main.asyncAfter(deadline:
                                                DispatchTime.now() + DispatchTimeInterval
                                                .milliseconds(selectedAnimationDurationInMilliseconds)) {
                    self.collectionView
                        .scrollToItem(at: IndexPath(item: index, section: 0),
                                      at: .centeredHorizontally,
                                      animated: true)
                }
            } else if selectedType == .scroll {
                //滚动选中的直接处理
                collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                            at: .centeredHorizontally,
                                            animated: true)
            }
        } else {
            collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                        at: .centeredHorizontally,
                                        animated: true)
        }

        if contentScrollView != nil && (selectedType == .click || selectedType == .code) {
            contentScrollView!.setContentOffset(
                CGPoint(x: contentScrollView!.bounds.size.width * CGFloat(index), y: 0),
                animated: config.isContentScrollViewClickTransitionAnimationEnabled)
        }

        let lastSelectedIndex = selectedIndex
        selectedIndex = index

        let currentSelectedItemFrame = getItemFrameAt(index: selectedIndex)
        for indicator in indicators {
            let indicatorParamsModel = UDTabsIndicatorParamsModel()
            indicatorParamsModel.lastSelectedIndex = lastSelectedIndex
            indicatorParamsModel.currentSelectedIndex = selectedIndex
            indicatorParamsModel.currentSelectedItemFrame = currentSelectedItemFrame
            indicatorParamsModel.selectedType = selectedType
            indicator.selectItem(model: indicatorParamsModel)

            if indicator.isIndicatorConvertToItemFrameEnabled {
                var indicatorConvertToItemFrame = indicator.frame
                indicatorConvertToItemFrame.origin.x -= currentSelectedItemFrame.origin.x
                itemDataSource[selectedIndex].indicatorConvertToItemFrame = indicatorConvertToItemFrame
                willSelectedCell?.reloadData(itemModel: willSelectedItemModel, selectedType: selectedType)
            }
        }

        scrollingTargetIndex = -1
        if selectedType == .code {
            listContainer?.didClickSelectedItem(at: index)
        } else if selectedType == .click {
            delegate?.tabsView(self, didClickSelectedItemAt: index)
            listContainer?.didClickSelectedItem(at: index)
        } else if selectedType == .scroll {
            delegate?.tabsView(self, didScrollSelectedItemAt: index)
        }
        delegate?.tabsView(self, didSelectedItemAt: index)
    }

    // MARK: - KVO
    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset",
           let contentOffset = change?[NSKeyValueChangeKey.newKey] as? CGPoint {
            if contentScrollView?.isTracking == true || contentScrollView?.isDecelerating == true {
                //用户滚动引起的contentOffset变化，才处理。
                let progress = contentOffset.x / contentScrollView!.bounds.size.width
                if Int(progress) > itemDataSource.count - 1 || progress < 0 {
                    //超过了边界，不需要处理
                    return
                }
                if contentOffset.x == 0 && selectedIndex == 0 && lastContentOffset.x == 0 {
                    //滚动到了最左边，且已经选中了第一个，且之前的contentOffset.x为0
                    return
                }
                let maxContentOffsetX = contentScrollView!.contentSize.width - contentScrollView!.bounds.size.width
                if contentOffset.x == maxContentOffsetX,
                   selectedIndex == itemDataSource.count - 1,
                   lastContentOffset.x == maxContentOffsetX {
                    //滚动到了最右边，且已经选中了最后一个，且之前的contentOffset.x为maxContentOffsetX
                    return
                }

                setProgress(progress)
            }
            lastContentOffset = contentOffset
        }
    }

    // MARK: - Private
    private func setProgress(_ oldProgress: CGFloat) {
        let progress = max(0, min(CGFloat(itemDataSource.count - 1), oldProgress))
        let baseIndex = Int(floor(progress))
        let remainderProgress = progress - CGFloat(baseIndex)

        let leftItemFrame = getItemFrameAt(index: baseIndex)
        let rightItemFrame = getItemFrameAt(index: baseIndex + 1)

        let indicatorParamsModel = UDTabsIndicatorParamsModel()
        indicatorParamsModel.currentSelectedIndex = selectedIndex
        indicatorParamsModel.leftIndex = baseIndex
        indicatorParamsModel.leftItemFrame = leftItemFrame
        indicatorParamsModel.rightIndex = baseIndex + 1
        indicatorParamsModel.rightItemFrame = rightItemFrame
        indicatorParamsModel.percent = remainderProgress

        if remainderProgress == 0 {
            //滑动翻页，需要更新选中状态
            //滑动一小段距离，然后放开回到原位，contentOffset同样的值会回调多次。例如在index为1的情况，滑动放开回到原位，contentOffset会多次回调CGPoint(width, 0)
            if !(lastProgress == progress && selectedIndex == baseIndex) {
                scrollSelectItemAt(index: baseIndex)
            }
        } else {
            //快速滑动翻页，当remainderRatio没有变成0，但是已经翻页了，需要通过下面的判断，触发选中
            if abs(progress - CGFloat(selectedIndex)) > 1 {
                var targetIndex = baseIndex
                if progress < CGFloat(selectedIndex) {
                    targetIndex = baseIndex + 1
                }
                scrollSelectItemAt(index: targetIndex)
            }
            if selectedIndex == baseIndex {
                scrollingTargetIndex = baseIndex + 1
            } else {
                scrollingTargetIndex = baseIndex
            }

            refreshItemModel(leftItemModel: itemDataSource[baseIndex],
                             rightItemModel: itemDataSource[baseIndex + 1],
                             percent: remainderProgress)

            for indicator in indicators {
                indicator.contentScrollViewDidScroll(model: indicatorParamsModel)
                if indicator.isIndicatorConvertToItemFrameEnabled {
                    var leftIndicatorConvertToItemFrame = indicator.frame
                    leftIndicatorConvertToItemFrame.origin.x -= leftItemFrame.origin.x
                    itemDataSource[baseIndex].indicatorConvertToItemFrame = leftIndicatorConvertToItemFrame

                    var rightIndicatorConvertToItemFrame = indicator.frame
                    rightIndicatorConvertToItemFrame.origin.x -= rightItemFrame.origin.x
                    itemDataSource[baseIndex + 1].indicatorConvertToItemFrame = rightIndicatorConvertToItemFrame
                }
            }

            let leftCell = collectionView
                .cellForItem(at: IndexPath(item: baseIndex, section: 0)) as? UDTabsBaseCell
            leftCell?.reloadData(itemModel: itemDataSource[baseIndex], selectedType: .unknown)

            let rightCell = collectionView.cellForItem(at: IndexPath(item: baseIndex + 1,
                                                                     section: 0)) as? UDTabsBaseCell
            rightCell?.reloadData(itemModel: itemDataSource[baseIndex + 1], selectedType: .unknown)

            listContainer?.scrolling(from: baseIndex,
                                     to: baseIndex + 1,
                                     percent: remainderProgress,
                                     selectedIndex: selectedIndex)
            delegate?.tabsView(self, scrollingFrom: baseIndex, to: baseIndex + 1, percent: remainderProgress)
        }

        lastProgress = oldProgress
    }

    private func clickSelectItemAt(index: Int) {
        guard delegate?.tabsView(self, canClickItemAt: index) != false else {
            return
        }
        selectItemAt(index: index, selectedType: .click)
    }

    private func scrollSelectItemAt(index: Int) {
        selectItemAt(index: index, selectedType: .scroll)
    }

    private func getItemFrameAt(index: Int) -> CGRect {
        guard index < itemDataSource.count else {
            return CGRect.zero
        }
        var left = getContentEdgeInsetLeft()
        for i in 0..<index {
            let itemModel = itemDataSource[i]
            var itemWidth: CGFloat = 0
            if itemModel.isTransitionAnimating && config.isItemWidthZoomEnabled {
                //正在进行动画的时候，itemWidthCurrentZoomScale是随着动画渐变的，而没有立即更新到目标值
                if itemModel.isSelected {
                    itemWidth = (tabsView(widthForItemAt: itemModel.index,
                                          isItemWidthZoomValid: false) ) *
                        config.itemWidthSelectedZoomScale
                } else {
                    itemWidth = (tabsView(widthForItemAt: itemModel.index,
                                          isItemWidthZoomValid: false) ) *
                        config.itemWidthNormalZoomScale
                }
            } else {
                itemWidth = itemModel.itemWidth
            }
            left += itemWidth + innerItemSpacing
        }
        var width: CGFloat = 0
        let selectedItemModel = itemDataSource[index]
        if selectedItemModel.isTransitionAnimating && config.isItemWidthZoomEnabled {
            width = (tabsView(widthForItemAt: selectedItemModel.index,
                              isItemWidthZoomValid: false) ) *
                config.itemWidthSelectedZoomScale
        } else {
            width = selectedItemModel.itemWidth
        }
        return CGRect(x: left, y: 0, width: width, height: bounds.size.height)
    }

    private func getContentEdgeInsetLeft() -> CGFloat {
        if config.contentEdgeInsetLeft == UDTabsViewAutomaticDimension {
            return innerItemSpacing
        } else {
            return config.contentEdgeInsetLeft
        }
    }

    private func getContentEdgeInsetRight() -> CGFloat {
        if config.contentEdgeInsetRight == UDTabsViewAutomaticDimension {
            return innerItemSpacing
        } else {
            return config.contentEdgeInsetRight
        }
    }
}

extension UDTabsView: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemDataSource.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = tabsView(cellForItemAt: indexPath.item)
        cell.reloadData(itemModel: itemDataSource[indexPath.item], selectedType: .unknown)
        return cell
    }
}

extension UDTabsView: UICollectionViewDelegate {
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var isTransitionAnimating = false
        for itemModel in itemDataSource where itemModel.isTransitionAnimating {
            isTransitionAnimating = true
            break
        }
        if !isTransitionAnimating {
            //当前没有正在过渡的item，才允许点击选中
            clickSelectItemAt(index: indexPath.item)
        }
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        showMask()
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.tabsViewWillBeginDragging(self)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.tabsViewDidEndDragging(self)
    }

    private func showMask() {
        guard config.layoutStyle != .average,
              config.isShowGradientMaskLayer else {
            self.gradientMaskLayer.isHidden = true
            return
        }
        
        let collectionFrameWidth = collectionView.frame.size.width
        let collectionContentOffsetX = collectionView.contentOffset.x
        let distanceFromRight = collectionView.contentSize.width - collectionContentOffsetX - config.contentEdgeInsetRight

        self.gradientMaskLayer.isHidden = distanceFromRight <= collectionFrameWidth
    }
}

extension UDTabsView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: getContentEdgeInsetLeft(), bottom: 0, right: getContentEdgeInsetRight())
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemDataSource[indexPath.item].itemWidth, height: collectionView.bounds.size.height)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return innerItemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return innerItemSpacing
    }
}

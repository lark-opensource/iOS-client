//
//  PagingListContainerView.swift
//  Minutes
//
//  Created by jiaxin on 2018/12/26.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

/// 列表容器视图的类型
///- ScrollView: UIScrollView。优势：没有其他副作用。劣势：实时的视图内存占用相对大一点，因为所有加载之后的列表视图都在视图层级里面。
/// - CollectionView: 使用UICollectionView。优势：因为列表被添加到cell上，实时的视图内存占用更少，适合内存要求特别高的场景。劣势：因为cell重用机制的问题，导致列表被移除屏幕外之后，会被放入缓存区，而不存在于视图层级中。如果刚好你的列表使用了下拉刷新视图，在快速切换过程中，就会导致下拉刷新回调不成功的问题。一句话概括：使用CollectionView的时候，就不要让列表使用下拉刷新加载。
public enum PagingListContainerType {
    case scrollView
    case collectionView
}

@objc
public protocol PagingViewListViewDelegate {
    /// 如果列表是VC，就返回VC.view
    /// 如果列表是View，就返回View自己
    ///
    /// - Returns: 返回列表视图
    func listView() -> UIView
    /// 返回listView内部持有的UIScrollView或UITableView或UICollectionView
    /// 主要用于mainTableView已经显示了header，listView的contentOffset需要重置时，内部需要访问到外部传入进来的listView内的scrollView
    ///
    /// - Returns: listView内部持有的UIScrollView或UITableView或UICollectionView
    func listScrollView() -> UIScrollView
    /// 当listView内部持有的UIScrollView或UITableView或UICollectionView的代理方法`scrollViewDidScroll`回调时，需要调用该代理方法传入的callback

    /// 将要重置listScrollView的contentOffset
    @objc optional func listScrollViewWillResetContentOffset()
    /// 可选实现，列表将要显示的时候调用
    @objc optional func listWillAppear()
    /// 可选实现，列表显示的时候调用
    @objc optional func listDidAppear()
    /// 可选实现，列表将要消失的时候调用
    @objc optional func listWillDisappear()
    /// 可选实现，列表消失的时候调用
    @objc optional func listDidDisappear()
}

@objc
public protocol PagingListContainerViewDataSource {
    /// 返回list的数量
    ///
    /// - Parameter listContainerView: PagingListContainerView
    func numberOfLists(in listContainerView: PagingListContainerView) -> Int

    /// 根据index初始化一个对应列表实例，需要是遵从`PagingViewListViewDelegate`协议的对象。
    /// 如果列表是用自定义UIView封装的，就让自定义UIView遵从`PagingViewListViewDelegate`协议，该方法返回自定义UIView即可。
    /// 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`PagingViewListViewDelegate`协议，该方法返回自定义UIViewController即可。
    /// 注意：一定要是新生成的实例！！！
    ///
    /// - Parameters:
    ///   - listContainerView: PagingListContainerView
    ///   - index: 目标index
    /// - Returns: 遵从PagingViewListViewDelegate协议的实例
    func listContainerView(_ listContainerView: PagingListContainerView, initListAt index: Int) -> PagingViewListViewDelegate?


    /// 控制能否初始化对应index的列表。有些业务需求，需要在某些情况才允许初始化某些列表，通过通过该代理实现控制。
    @objc optional func listContainerView(_ listContainerView: PagingListContainerView, canInitListAt index: Int) -> Bool

    /// 返回自定义UIScrollView或UICollectionView的Class
    /// 某些特殊情况需要自己处理UIScrollView内部逻辑。比如项目用了FDFullscreenPopGesture，需要处理手势相关代理。
    ///
    /// - Parameter listContainerView: PagingListContainerView
    /// - Returns: 自定义UIScrollView实例
    @objc optional func scrollViewClass(in listContainerView: PagingListContainerView) -> AnyClass
}

@objc protocol PagingListContainerViewDelegate {
    @objc optional func listContainerViewDidScroll(_ listContainerView: PagingListContainerView)
    @objc optional func listContainerViewWillBeginDragging(_ listContainerView: PagingListContainerView)
    @objc optional func listContainerViewDidEndScrolling(_ listContainerView: PagingListContainerView)
    @objc optional func listContainerView(_ listContainerView: PagingListContainerView, listDidAppearAt index: Int)
}

open class PagingListContainerView: UIView {
    public private(set) var type: PagingListContainerType
    public private(set) weak var dataSource: PagingListContainerViewDataSource?
    public private(set) var scrollView: UIScrollView?
    /// 已经加载过的列表字典。key是index，value是对应的列表
    public var validListDict = [Int: PagingViewListViewDelegate]()
    /// 滚动切换的时候，滚动距离超过一页的多少百分比，就触发列表的初始化。默认0.01（即列表显示了一点就触发加载）。范围0~1，开区间不包括0和1
    public var initListPercent: CGFloat = 0.01 {
        didSet {
            if initListPercent <= 0 || initListPercent >= 1 {
                assertionFailure("initListPercent值范围为开区间(0,1)，即不包括0和1")
            }
        }
    }
    public var listCellBackgroundColor: UIColor = .white
    /// 需要和segmentedView.defaultSelectedIndex保持一致，用于触发默认index列表的加载
    public var defaultSelectedIndex: Int = 0 {
        didSet {
            currentIndex = defaultSelectedIndex
        }
    }
    weak var delegate: PagingListContainerViewDelegate?
    private var currentIndex: Int = 0
    private var collectionView: UICollectionView?
    lazy var containerVC: PagingListContainerViewController = {
        let viewController = PagingListContainerViewController()
        return viewController
    }()

    var currentListView: UIScrollView? {
        return validListDict[currentIndex]?.listScrollView()
    }

    private var willAppearIndex: Int = -1
    private var willDisappearIndex: Int = -1

    public init(dataSource: PagingListContainerViewDataSource, type: PagingListContainerType = .collectionView) {
        self.dataSource = dataSource
        self.type = type
        super.init(frame: CGRect.zero)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func commonInit() {
        guard let dataSource = dataSource else { return }
        containerVC.view.backgroundColor = .clear
        addSubview(containerVC.view)
        handleContainerLifecycle()
        if type == .scrollView {
            initScrollView()
        } else if type == .collectionView {
            initCollectionView()
        }
    }
    
    private func handleContainerLifecycle() {
        containerVC.viewWillAppearClosure = {[weak self] in
            self?.listWillAppear(at: self?.currentIndex ?? 0)
        }
        containerVC.viewDidAppearClosure = {[weak self] in
            self?.listDidAppear(at: self?.currentIndex ?? 0)
        }
        containerVC.viewWillDisappearClosure = {[weak self] in
            self?.listWillDisappear(at: self?.currentIndex ?? 0)
        }
        containerVC.viewDidDisappearClosure = {[weak self] in
            self?.listDidDisappear(at: self?.currentIndex ?? 0)
        }
    }
    
    private func initScrollView() {
        scrollView = UIScrollView.init()
        if let scrollView = scrollView {
            scrollView.backgroundColor = .clear
            scrollView.delegate = self
            scrollView.isPagingEnabled = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.scrollsToTop = false
            scrollView.bounces = false
            if #available(iOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
            containerVC.view.addSubview(scrollView)
        }
    }

    private func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        if let collectionView = collectionView {
            collectionView.backgroundColor = .clear
            collectionView.isPagingEnabled = true
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.showsVerticalScrollIndicator = false
            collectionView.scrollsToTop = false
            collectionView.bounces = false
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            collectionView.isPrefetchingEnabled = false
            collectionView.contentInsetAdjustmentBehavior = .never
            containerVC.view.addSubview(collectionView)
            //让外部统一访问scrollView
            scrollView = collectionView
        }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        var next: UIResponder? = newSuperview
        while next != nil {
            if let vc = next as? UIViewController {
                vc.addChild(containerVC)
                break
            }
            next = next?.next
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard let dataSource = dataSource else { return }
        containerVC.view.frame = bounds
        if type == .scrollView {
            guard let scrollView = scrollView else {
                return
            }

            configScrollView(scrollView, dataSource: dataSource)
        } else {
            guard let collectionView = collectionView else {
                return
            }
            configCollectionView(collectionView)
        }
    }
    
    private func configScrollView(_ scrollView: UIScrollView, dataSource: PagingListContainerViewDataSource) {
        if scrollView.frame == CGRect.zero || scrollView.bounds.size != bounds.size {
            scrollView.frame = bounds
            scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(dataSource.numberOfLists(in: self)), height: scrollView.bounds.size.height)
            for (index, list) in validListDict {
                list.listView().frame = CGRect(x: CGFloat(index) * scrollView.bounds.size.width, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
            }
            scrollView.contentOffset = CGPoint(x: CGFloat(currentIndex) * scrollView.bounds.size.width, y: 0)
        } else {
            scrollView.frame = bounds
            scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(dataSource.numberOfLists(in: self)), height: scrollView.bounds.size.height)
        }
    }
    
    private func configCollectionView(_ collectionView: UICollectionView) {
        if collectionView.frame == CGRect.zero || collectionView.bounds.size != bounds.size {
            collectionView.frame = bounds
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.setContentOffset(CGPoint(x: CGFloat(currentIndex) * collectionView.bounds.size.width, y: 0), animated: false)
        } else {
            collectionView.frame = bounds
        }
    }

    // MARK: - SegmentedViewListContainer
    public func contentScrollView() -> UIScrollView {
           return scrollView ?? UIScrollView()
    }

    public func scrolling(from leftIndex: Int, to rightIndex: Int, percent: CGFloat, selectedIndex: Int) {
    }

    public func didClickSelectedItem(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        willAppearIndex = -1
        willDisappearIndex = -1
        if currentIndex != index {
            listWillDisappear(at: currentIndex)
            listWillAppear(at: index)
            listDidDisappear(at: currentIndex)
            listDidAppear(at: index)
        }
    }

    public func reloadData() {
        guard let dataSource = dataSource else { return }
        if currentIndex < 0 || currentIndex >= dataSource.numberOfLists(in: self) {
            defaultSelectedIndex = 0
            currentIndex = 0
        }
        validListDict.values.forEach { (list) in
            if let listVC = list as? UIViewController {
                listVC.removeFromParent()
            }
            list.listView().removeFromSuperview()
        }
        validListDict.removeAll()
        if type == .scrollView {
            if let scrollView = scrollView {
                scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(dataSource.numberOfLists(in: self)), height: scrollView.bounds.size.height)
            }
        } else {
            collectionView?.reloadData()
        }
        listWillAppear(at: currentIndex)
        listDidAppear(at: currentIndex)
    }

    // MARK: - Private
    func initListIfNeeded(at index: Int) {
        guard let dataSource = dataSource else { return }
        if dataSource.listContainerView?(self, canInitListAt: index) == false {
            return
        }
        var existedList = validListDict[index]
        if existedList != nil {
            //列表已经创建好了
            return
        }
        existedList = dataSource.listContainerView(self, initListAt: index)
        guard let list = existedList else {
            return
        }
        if let viewController = list as? UIViewController {
            containerVC.addChild(viewController)
        }
        validListDict[index] = list
        switch type {
        case .scrollView:
            if let scrollView = scrollView {
                list.listView().frame = CGRect(x: CGFloat(index) * scrollView.bounds.size.width, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
                scrollView.addSubview(list.listView())
            }
        case .collectionView:
            if let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) {
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                list.listView().frame = cell.contentView.bounds
                cell.contentView.addSubview(list.listView())
            }
        }
    }

    private func listWillAppear(at index: Int) {
        guard let dataSource = dataSource else { return }
        guard checkIndexValid(index) else {
            return
        }
        var existedList = validListDict[index]
        if existedList != nil {
            existedList?.listWillAppear?()
            if let viewController = existedList as? UIViewController {
                viewController.beginAppearanceTransition(true, animated: false)
            }
        } else {
            //当前列表未被创建（页面初始化或通过点击触发的listWillAppear）
            guard dataSource.listContainerView?(self, canInitListAt: index) != false else {
                return
            }
            existedList = dataSource.listContainerView(self, initListAt: index)
            guard let list = existedList else {
                return
            }
            if let viewController = list as? UIViewController {
                containerVC.addChild(viewController)
            }
            validListDict[index] = list
            if type == .scrollView {
                if list.listView().superview == nil {
                    if let scrollView = scrollView {
                        list.listView().frame = CGRect(x: CGFloat(index) * scrollView.bounds.size.width, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
                        scrollView.addSubview(list.listView())
                    }
                }
                list.listWillAppear?()
                if let viewController = list as? UIViewController {
                    viewController.beginAppearanceTransition(true, animated: false)
                }
            } else {
                let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
                cell?.contentView.subviews.forEach { $0.removeFromSuperview() }
                list.listView().frame = cell?.contentView.bounds ?? CGRect.zero
                cell?.contentView.addSubview(list.listView())
                list.listWillAppear?()
                if let viewController = list as? UIViewController {
                    viewController.beginAppearanceTransition(true, animated: false)
                }
            }
        }
    }

    private func listDidAppear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        currentIndex = index
        let list = validListDict[index]
        list?.listDidAppear?()
        if let viewController = list as? UIViewController {
            viewController.endAppearanceTransition()
        }
        delegate?.listContainerView?(self, listDidAppearAt: index)
    }

    private func listWillDisappear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        let list = validListDict[index]
        list?.listWillDisappear?()
        if let viewController = list as? UIViewController {
            viewController.beginAppearanceTransition(false, animated: false)
        }
    }

    private func listDidDisappear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        let list = validListDict[index]
        list?.listDidDisappear?()
        if let viewController = list as? UIViewController {
            viewController.endAppearanceTransition()
        }
    }

    private func checkIndexValid(_ index: Int) -> Bool {
        guard let dataSource = dataSource else { return false }
        let count = dataSource.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return false
        }
        return true
    }

    private func listDidAppearOrDisappear(scrollView: UIScrollView) {
        let currentIndexPercent = scrollView.contentOffset.x / scrollView.bounds.size.width
        if willAppearIndex != -1 || willDisappearIndex != -1 {
            let disappearIndex = willDisappearIndex
            let appearIndex = willAppearIndex
            handleListAppearOrDisappear(currentIndexPercent: currentIndexPercent, disappearIndex: disappearIndex, appearIndex: appearIndex)
        }
    }
    
    private func handleListAppearOrDisappear(currentIndexPercent: CGFloat, disappearIndex: Int, appearIndex: Int) {
        if willAppearIndex > willDisappearIndex {
            //将要出现的列表在右边
            if currentIndexPercent >= CGFloat(willAppearIndex) {
                willDisappearIndex = -1
                willAppearIndex = -1
                listDidDisappear(at: disappearIndex)
                listDidAppear(at: appearIndex)
            }
        } else {
            //将要出现的列表在左边
            if currentIndexPercent <= CGFloat(willAppearIndex) {
                willDisappearIndex = -1
                willAppearIndex = -1
                listDidDisappear(at: disappearIndex)
                listDidAppear(at: appearIndex)
            }
        }
    }
}

extension PagingListContainerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = dataSource else { return 0 }
        return dataSource.numberOfLists(in: self)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = listCellBackgroundColor
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let list = validListDict[indexPath.item]
        if let list = list {
            if list is UIViewController {
                list.listView().frame = cell.contentView.bounds
            } else {
                list.listView().frame = cell.bounds
            }
            cell.contentView.addSubview(list.listView())
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return bounds.size
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.listContainerViewDidScroll?(self)
        guard scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating else {
            return
        }
        let percent = scrollView.contentOffset.x / scrollView.bounds.size.width
        let maxCount = Int(round(scrollView.contentSize.width / scrollView.bounds.size.width))
        var leftIndex = Int(floor(Double(percent)))
        leftIndex = max(0, min(maxCount - 1, leftIndex))
        let rightIndex = leftIndex + 1
        if percent < 0 || rightIndex >= maxCount {
            listDidAppearOrDisappear(scrollView: scrollView)
            return
        }
        let remainderRatio = percent - CGFloat(leftIndex)
        if rightIndex == currentIndex {
            //当前选中的在右边，用户正在从右边往左边滑动
            if validListDict[leftIndex] == nil && remainderRatio < (1 - initListPercent) {
                initListIfNeeded(at: leftIndex)
            } else if validListDict[leftIndex] != nil {
                if willAppearIndex == -1 {
                    willAppearIndex = leftIndex
                    listWillAppear(at: willAppearIndex)
                }
            }
            if willDisappearIndex == -1 {
                willDisappearIndex = rightIndex
                listWillDisappear(at: willDisappearIndex)
            }
        } else {
            //当前选中的在左边，用户正在从左边往右边滑动
            if validListDict[rightIndex] == nil && remainderRatio > initListPercent {
                initListIfNeeded(at: rightIndex)
            } else if validListDict[rightIndex] != nil {
                if willAppearIndex == -1 {
                    willAppearIndex = rightIndex
                    listWillAppear(at: willAppearIndex)
                }
            }
            if willDisappearIndex == -1 {
                willDisappearIndex = leftIndex
                listWillDisappear(at: willDisappearIndex)
            }
        }
        listDidAppearOrDisappear(scrollView: scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //滑动到一半又取消滑动处理
        if willAppearIndex != -1 || willDisappearIndex != -1 {
            listWillDisappear(at: willAppearIndex)
            listWillAppear(at: willDisappearIndex)
            listDidDisappear(at: willAppearIndex)
            listDidAppear(at: willDisappearIndex)
            willDisappearIndex = -1
            willAppearIndex = -1
        }
        delegate?.listContainerViewDidEndScrolling?(self)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.listContainerViewWillBeginDragging?(self)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            delegate?.listContainerViewDidEndScrolling?(self)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.listContainerViewDidEndScrolling?(self)
    }
}

class PagingListContainerViewController: UIViewController {
    var viewWillAppearClosure: (() -> Void)?
    var viewDidAppearClosure: (() -> Void)?
    var viewWillDisappearClosure: (() -> Void)?
    var viewDidDisappearClosure: (() -> Void)?
    override var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearClosure?()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearClosure?()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearClosure?()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearClosure?()
    }
}

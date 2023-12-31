//
//  UDTabsListContainerView.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit
import UniverseDesignColor

/// 列表容器视图的类型
///- ScrollView: UIScrollView。优势：没有其他副作用。劣势：视图内存占用相对大一点。
/// - CollectionView: 使用UICollectionView。
/// 优势：因为列表被添加到cell上，视图的内存占用更少，适合内存要求特别高的场景。
/// 劣势：因为cell重用机制的问题，导致列表下拉刷新视图(比如MJRefresh)，
/// 会因为被removeFromSuperview而被隐藏。需要参考`LoadDataListViewController`类做特殊处理。
public enum UDTabsListContainerType {
    case scrollView
    case collectionView
}

/// UDTabs List Container View List Delegate
public protocol UDTabsListContainerViewDelegate: AnyObject {
    /// 如果列表是VC，就返回VC.view
    /// 如果列表是View，就返回View自己
    ///
    /// - Returns: 返回列表视图
    func listView() -> UIView
    /// 可选实现，列表将要显示的时候调用
    func listWillAppear()
    /// 可选实现，列表显示的时候调用
    func listDidAppear()
    /// 可选实现，列表将要消失的时候调用
    func listWillDisappear()
    /// 可选实现，列表消失的时候调用
    func listDidDisappear()
    /// 可选实现，可以由业务方提供特定 VC
    func listVC() -> UIViewController?
}

public extension UDTabsListContainerViewDelegate {
    func listWillAppear() {}
    func listDidAppear() {}
    func listWillDisappear() {}
    func listDidDisappear() {}
    func listVC() -> UIViewController? { return nil }
}

public protocol UDTabsListContainerDelegate: AnyObject {

    /// 通知代理 UDTabsListContainerView 将开始手势滑动
    func tabsContainerWillBeginDragging(_ tabsContainer: UDTabsListContainerView)

    /// 通知代理 UDTabsListContainerView 已停止手势滑动
    func tabsContainerDidEndDragging(_ tabsContainer: UDTabsListContainerView)
}

public extension UDTabsListContainerDelegate {
    func tabsContainerWillBeginDragging(_ tabsContainer: UDTabsListContainerView) {}
    func tabsContainerDidEndDragging(_ tabsContainer: UDTabsListContainerView) {}
}

/// UDTabs List Container View DataSource Protocol
public protocol UDTabsListContainerViewDataSource: AnyObject {
    /// 返回list的数量
    ///
    /// - Parameter listContainerView: UDTabsListContainerView
    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int

    /// 根据index初始化一个对应列表实例，需要是遵从`UDTabsListContainerViewListDelegate`协议的对象。
    /// 如果列表是用自定义UIView封装的，就让自定义UIView遵从`UDTabsListContainerViewListDelegate`协议，该方法返回自定义UIView即可。
    /// 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`UDTabsListContainerViewListDelegate`协议，
    /// 该方法返回自定义UIViewController即可。
    /// 注意：一定要是新生成的实例！！！
    ///
    /// - Parameters:
    ///   - listContainerView: UDTabsListContainerView
    ///   - index: 目标index
    /// - Returns: 遵从UDTabsListContainerViewListDelegate协议的实例
    func listContainerView(_ listContainerView: UDTabsListContainerView,
                           initListAt index: Int) -> UDTabsListContainerViewDelegate

    /// 控制能否初始化对应index的列表。有些业务需求，需要在某些情况才允许初始化某些列表，通过通过该代理实现控制。
    func listContainerView(_ listContainerView: UDTabsListContainerView, canInitListAt index: Int) -> Bool?

    /// 返回自定义UIScrollView或UICollectionView的Class
    /// 某些特殊情况需要自己处理UIScrollView内部逻辑。比如项目用了FDFullscreenPopGesture，需要处理手势相关代理。
    ///
    /// - Parameter listContainerView: UDTabsListContainerView
    /// - Returns: 自定义UIScrollView实例
    func scrollViewClass(in listContainerView: UDTabsListContainerView) -> AnyClass?
}

public extension UDTabsListContainerViewDataSource {
    func listContainerView(_ listContainerView: UDTabsListContainerView, canInitListAt index: Int) -> Bool? { nil }
    func scrollViewClass(in listContainerView: UDTabsListContainerView) -> AnyClass? { nil }
}

/// UD TabsView List Container Protocol
public protocol UDTabsViewListContainer {

    /// 默认选中
    var defaultSelectedIndex: Int { get set }

    /// 返回 UIScrollView
    func contentScrollView() -> UIScrollView

    /// 刷新
    func reloadData()

    /// 滚动
    func scrolling(from leftIndex: Int, to rightIndex: Int, percent: CGFloat, selectedIndex: Int)

    /// 选中对应的Item
    func didClickSelectedItem(at index: Int)
}

// swiftlint:disable empty_count
open class UDTabsListContainerView: UIView, UDTabsViewListContainer {
    public private(set) var type: UDTabsListContainerType
    public private(set) weak var dataSource: UDTabsListContainerViewDataSource?
    /// UDTabsListContainerView 的代理，用于处理手势滑动
    public weak var delegate: UDTabsListContainerDelegate?
    public private(set) var scrollView: UIScrollView!
    /// 已经加载过的列表字典。key是index，value是对应的列表
    open var validListDict = [Int: UDTabsListContainerViewDelegate]()
    /// 滚动切换的时候，滚动距离超过一页的多少百分比，就触发列表的初始化。默认0.01（即列表显示了一点就触发加载）。范围0~1，开区间不包括0和1
    open var initListPercent: CGFloat = 0.01 {
        didSet {
            if initListPercent <= 0 || initListPercent >= 1 {
                assertionFailure("initListPercent值范围为开区间(0,1)，即不包括0和1")
            }
        }
    }
    public var listCellBackgroundColor: UIColor = UDTabsColorTheme.tabsFixedBgColor
    /// 需要和tabsView.defaultSelectedIndex保持一致，用于触发默认index列表的加载
    public var defaultSelectedIndex: Int = 0 {
        didSet {
            currentIndex = defaultSelectedIndex
        }
    }
    private var currentIndex: Int = 0
    private var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    private var containerVC: UDTabsListContainerViewController!
    private var willAppearIndex: Int = -1
    private var willDisappearIndex: Int = -1
    /// 是否在内部触发VC的生命周期方法
    private let triggerLifeCycle: Bool

    public init(dataSource: UDTabsListContainerViewDataSource,
                type: UDTabsListContainerType = .scrollView,
                triggerLifeCycle: Bool = true) {
        self.dataSource = dataSource
        self.type = type
        self.triggerLifeCycle = triggerLifeCycle
        super.init(frame: CGRect.zero)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        containerVC = UDTabsListContainerViewController()
        containerVC.view.backgroundColor = .clear
        addSubview(containerVC.view)
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
        if type == .scrollView {
            if let scrollViewClass = dataSource?.scrollViewClass(in: self) as? UIScrollView.Type {
                scrollView = scrollViewClass.init()
            } else {
                scrollView = UIScrollView()
            }
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
            scrollView.frame = containerVC.view.bounds
        } else if type == .collectionView {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            if let collectionViewClass = dataSource?.scrollViewClass(in: self) as? UICollectionView.Type {
                collectionView = collectionViewClass.init(frame: CGRect.zero, collectionViewLayout: layout)
            } else {
                collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
            }
            collectionView.isPagingEnabled = true
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.showsVerticalScrollIndicator = false
            collectionView.scrollsToTop = false
            collectionView.bounces = false
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            if #available(iOS 10.0, *) {
                collectionView.isPrefetchingEnabled = false
            }
            if #available(iOS 11.0, *) {
                self.collectionView.contentInsetAdjustmentBehavior = .never
            }
            containerVC.view.addSubview(collectionView)
            //让外部统一访问scrollView
            scrollView = collectionView
        }
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
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

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let dataSource = dataSource else { return }

        containerVC.view.frame = bounds
        if type == .scrollView {
            if scrollView.frame == CGRect.zero || scrollView.bounds.size != bounds.size {
                scrollView.frame = bounds
                scrollView.contentSize = CGSize(width:
                                                    scrollView
                                                    .bounds.size.width * CGFloat(dataSource.numberOfLists(in: self)),
                                                height: scrollView.bounds.size.height)
                for (index, list) in validListDict {
                    list.listView().frame = CGRect(x: CGFloat(index) * scrollView.bounds.size.width,
                                                   y: 0,
                                                   width: scrollView.bounds.size.width,
                                                   height: scrollView.bounds.size.height)
                }
                scrollView.contentOffset = CGPoint(x: CGFloat(currentIndex) * scrollView.bounds.size.width,
                                                   y: 0)
            } else {
                scrollView.frame = bounds
                scrollView.contentSize = CGSize(width:
                                                    scrollView
                                                    .bounds.size.width * CGFloat(dataSource.numberOfLists(in: self)),
                                                height: scrollView.bounds.size.height)
            }
        } else {
            if collectionView.frame == CGRect.zero || collectionView.bounds.size != bounds.size {
                collectionView.frame = bounds
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.setContentOffset(
                    CGPoint(x: CGFloat(currentIndex) * collectionView.bounds.size.width,
                            y: 0),
                    animated: false)
            } else {
                collectionView.frame = bounds
            }
        }
    }

    // MARK: - UDTabsViewListContainer
    public func contentScrollView() -> UIScrollView {
           return scrollView
       }

    public func scrolling(from leftIndex: Int, to rightIndex: Int, percent: CGFloat, selectedIndex: Int) {
        if rightIndex == selectedIndex {
            //当前选中的在右边，用户正在从右边往左边滑动
            if percent < (1 - initListPercent) {
                initListIfNeeded(at: leftIndex)
            }
            if willAppearIndex == -1 {
                willAppearIndex = leftIndex
                if validListDict[leftIndex] != nil {
                    listWillAppear(at: willAppearIndex)
                }
            }
            if willDisappearIndex == -1 {
                willDisappearIndex = rightIndex
                listWillDisappear(at: willDisappearIndex)
            }
        } else {
            //当前选中的在左边，用户正在从左边往右边滑动
            if percent > initListPercent {
                initListIfNeeded(at: rightIndex)
            }
            if willAppearIndex == -1 {
                willAppearIndex = rightIndex
                if validListDict[rightIndex] != nil {
                    listWillAppear(at: willAppearIndex)
                }
            }
            if willDisappearIndex == -1 {
                willDisappearIndex = leftIndex
                listWillDisappear(at: willDisappearIndex)
            }
        }
    }

    open func didClickSelectedItem(at index: Int) {
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

    /// 该方法会把已经添加到视图层级上的 UIView / UIViewController 进行移除
    /// 不再对其进行持有
    open func reloadData() {
        guard let dataSource = dataSource else { return }

        if currentIndex < 0 || currentIndex >= dataSource.numberOfLists(in: self) {
            defaultSelectedIndex = 0
            currentIndex = 0
        }
        validListDict.values.forEach { list in
            var listVC: UIViewController?
            if let vc = list as? UIViewController {
                listVC = vc
            } else if let vc = list.listVC() as? UIViewController {
                listVC = vc
            }
            listVC?.willMove(toParent: nil)
            list.listView().removeFromSuperview()
            listVC?.removeFromParent()
        }
        validListDict.removeAll()
        if type == .scrollView {
            scrollView.contentSize = CGSize(
                width: scrollView.bounds.size.width * CGFloat(dataSource.numberOfLists(in: self)),
                height: scrollView.bounds.size.height)
        } else {
            collectionView.reloadData()
        }
        listWillAppear(at: currentIndex)
        listDidAppear(at: currentIndex)
    }

    // MARK: - Private
    func initListIfNeeded(at index: Int) {
        guard let dataSource = dataSource else { return }

        if dataSource.listContainerView(self, canInitListAt: index) == false {
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
        var listVC: UIViewController?
        if let vc = list as? UIViewController {
            containerVC.addChild(vc)
            listVC = vc
        } else if let vc = list.listVC() as? UIViewController {
            containerVC.addChild(vc)
            listVC = vc
        }
        validListDict[index] = list
        if type == .scrollView {
            list.listView().frame = CGRect(x: CGFloat(index) * scrollView.bounds.size.width,
                                           y: 0,
                                           width: scrollView.bounds.size.width,
                                           height: scrollView.bounds.size.height)
            scrollView.addSubview(list.listView())
        } else {
            let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
            cell?.contentView.subviews.forEach { $0.removeFromSuperview() }
            list.listView().frame = cell?.contentView.bounds ?? CGRect.zero
            cell?.contentView.addSubview(list.listView())
        }
        listVC?.didMove(toParent: containerVC)
    }

    private func listWillAppear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        guard let dataSource = dataSource else { return }

        var existedList = validListDict[index]
        if existedList != nil {
            existedList?.listWillAppear()
            if self.triggerLifeCycle {
                if let vc = existedList as? UIViewController {
                    vc.beginAppearanceTransition(true, animated: false)
                } else if let vc = existedList?.listVC() as? UIViewController {
                    vc.beginAppearanceTransition(true, animated: false)
                }
            }
        } else {
            //当前列表未被创建（页面初始化或通过点击触发的listWillAppear）
            guard dataSource.listContainerView(self, canInitListAt: index) != false else {
                return
            }
            existedList = dataSource.listContainerView(self, initListAt: index)
            guard let list = existedList else {
                return
            }
            var listVC: UIViewController?
            if let vc = list as? UIViewController {
                containerVC.addChild(vc)
                listVC = vc
            } else if let vc = existedList?.listVC() as? UIViewController {
                containerVC.addChild(vc)
                listVC = vc
            }
            validListDict[index] = list
            if type == .scrollView {
                if list.listView().superview == nil {
                    list.listView().frame = CGRect(x: CGFloat(index) * scrollView.bounds.size.width,
                                                   y: 0,
                                                   width: scrollView.bounds.size.width,
                                                   height: scrollView.bounds.size.height)
                    scrollView.addSubview(list.listView())
                }
                listVC?.didMove(toParent: containerVC)
                list.listWillAppear()
                if self.triggerLifeCycle {
                    if let vc = existedList as? UIViewController {
                        vc.beginAppearanceTransition(true, animated: false)
                    } else if let vc = existedList?.listVC() as? UIViewController {
                        vc.beginAppearanceTransition(true, animated: false)
                    }
                }
            } else {
                let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
                cell?.contentView.subviews.forEach { $0.removeFromSuperview() }
                list.listView().frame = cell?.contentView.bounds ?? CGRect.zero
                cell?.contentView.addSubview(list.listView())
                listVC?.didMove(toParent: containerVC)
                list.listWillAppear()
                if self.triggerLifeCycle {
                    if let vc = existedList as? UIViewController {
                        vc.beginAppearanceTransition(true, animated: false)
                    } else if let vc = existedList?.listVC() as? UIViewController {
                        vc.beginAppearanceTransition(true, animated: false)
                    }
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
        list?.listDidAppear()
        if self.triggerLifeCycle {
            if let vc = list as? UIViewController {
                vc.endAppearanceTransition()
            } else if let vc = list?.listVC() as? UIViewController {
                vc.endAppearanceTransition()
            }
        }
    }

    private func listWillDisappear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        let list = validListDict[index]
        list?.listWillDisappear()
        if self.triggerLifeCycle {
            if let vc = list as? UIViewController {
                vc.beginAppearanceTransition(false, animated: false)
            } else if let vc = list?.listVC() as? UIViewController {
                vc.beginAppearanceTransition(false, animated: false)
            }
        }
    }

    private func listDidDisappear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        let list = validListDict[index]
        list?.listDidDisappear()
        if self.triggerLifeCycle {
            if let vc = list as? UIViewController {
                vc.endAppearanceTransition()
            } else if let vc = list?.listVC() as? UIViewController {
                vc.endAppearanceTransition()
            }
        }
    }

    private func checkIndexValid(_ index: Int) -> Bool {
        guard let dataSource = dataSource else { return false }
        let count = dataSource.numberOfLists(in: self)
        if count == 0 || index >= count {
            return false
        }
        return true
    }
}

extension UDTabsListContainerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = dataSource else { return 0 }
        return dataSource.numberOfLists(in: self)
    }

    open func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = listCellBackgroundColor
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let list = validListDict[indexPath.item]
        if list != nil {
            list?.listView().frame = cell.contentView.bounds
            cell.contentView.addSubview(list!.listView())
        }
        return cell
    }

    open func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return bounds.size
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentIndexPercent = scrollView.contentOffset.x / scrollView.bounds.size.width
        if willAppearIndex != -1 || willDisappearIndex != -1 {
            let disappearIndex = willDisappearIndex
            let appearIndex = willAppearIndex
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

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if willAppearIndex != -1 || willDisappearIndex != -1 {
            listWillDisappear(at: willAppearIndex)
            listWillAppear(at: willDisappearIndex)
            listDidDisappear(at: willAppearIndex)
            listDidAppear(at: willDisappearIndex)
            willDisappearIndex = -1
            willAppearIndex = -1
        }
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.tabsContainerWillBeginDragging(self)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.tabsContainerDidEndDragging(self)
    }
}

class UDTabsListContainerViewController: UIViewController {

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
// swiftlint:enable empty_count

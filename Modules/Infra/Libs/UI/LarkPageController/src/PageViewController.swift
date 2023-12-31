//
//  SegmentViewController.swift
//  LarkSegmentController
//
//  Created by kongkaikai on 2018/12/7.
//  Copyright © 2018 kongkaikai. All rights reserved.
//

import Foundation
import UIKit

open class PageViewController: UIViewController {
    public typealias InnerController = UIViewController & PageInnerScrollableController

    // viewController reuse
    fileprivate var viewControllerClassCache: [String: AnyClass] = [: ]
    fileprivate var cacheControllerPool: [InnerController] = []

    // base ui component
    fileprivate var contentTableView: PageTableView = PageTableView(frame: .zero, style: .plain)
    fileprivate var pageController: UIPageViewController
    fileprivate var contentFrame: CGRect = .zero

    // 记录正确的位置，以便于做Appear动画
    fileprivate var pageFrame: CGRect = .zero
    fileprivate var isDisappering: Bool = false
    fileprivate var isFirstApper: Bool = true

    fileprivate var innerScrolleView: UIScrollView?

    fileprivate var currentController: InnerController?

    public var startIndex: Int = 0

    /// 顶部偏移量
    public var topOffset: CGFloat = 0

    public var headerMinHeight: CGFloat = 0 {
        didSet {
            headerMinHeight = round(headerMinHeight)
            contentTableView.reloadData()
            headerOffset = headerMaxHeight - headerMinHeight
        }
    }

    public var headerMaxHeight: CGFloat = 280 {
        didSet {
            headerMaxHeight = round(headerMaxHeight)
            setHeaderFrame()
            headerOffset = headerMaxHeight - headerMinHeight
        }
    }

    fileprivate var headerOffset: CGFloat = 0

    public var segmentHeight: CGFloat = 0 {
        didSet { setSegmentControlFrame() }
    }

    public var isDismissOffsetEnable: Bool = true
    public var dissmissOffset: CGFloat = -75

    public var isHeaderBouncesEnable: Bool = true
    private var isHeaderBouncesAnimationPalyed: Bool = false

    /// 默认是lazy的全屏的空view，有黑色透明度变化动画
    public private(set) var backgroudView: UIView = UIView()

    // header 之下的全屏空View，会随着滚动自动改变大小，默认为隐藏状态
    public var emptyCoverView: UIView = PageEmptyView()

    /// 自定义 TableHeader，默认为透明的
    public var headerView: UIView = UIView() {
        didSet {
            setHeaderFrame()
            contentTableView.tableHeaderView = headerView
        }
    }
    public var segmentControl: (PageSegmentControlProtocol & UIView)? {
        didSet {
            setSegmentControlFrame()
            contentTableView.reloadData()
        }
    }
    public weak var dataSource: PageViewControllerDataSource?
    public weak var scrollDelegate: PageViewControllerVerticalScrollDelegate?
    
    public var pageBackgroundColor: UIColor = UIColor.white {
        didSet {
            emptyCoverView.backgroundColor = pageBackgroundColor
            pageController.view.backgroundColor = pageBackgroundColor
        }
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        pageController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.mid])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.setNavigationBarHidden(true, animated: false)

        backgroudView.backgroundColor = UIColor.black
        backgroudView.alpha = 0.3
        backgroudView.frame = view.bounds
        view.addSubview(backgroudView)

        contentTableView.delegate = self
        contentTableView.dataSource = self
        contentTableView.tableHeaderView = headerView
        contentTableView.showsVerticalScrollIndicator = false
        contentTableView.separatorStyle = .none
        contentTableView.decelerationRate = .fast
        contentTableView.contentInsetAdjustmentBehavior = .never

        emptyCoverView.isHidden = true
        (emptyCoverView as? PageEmptyView)?.updateIsHidden = { [weak self] (isHidden) in
            if !isHidden {
                self?.updateEmptyViewFrame()
            }
        }
        emptyCoverView.backgroundColor = pageBackgroundColor

        contentTableView.backgroundColor = UIColor.clear
        contentTableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        view.addSubview(contentTableView)

        pageController.delegate = self
        pageController.dataSource = self
        pageController.view.backgroundColor = pageBackgroundColor

        self.addChild(pageController)
        reloadFrame()
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.setToolbarHidden(true, animated: false)
        setContentTableFrame()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.reloadFrame()
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard isFirstApper else { return }

        prepareApperAnimation()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard isFirstApper else { return }
        self.reloadFrame()

        // pageViewController 的布局会被重新设置，所以需要重新设置一次
        pageController.view.frame = pageFrame

        if startIndex < dataSource?.numberOfPage(in: self) ?? 0 {
            showpage(at: startIndex, animated: false)
            segmentControl?.select(itemAt: startIndex)
        }

        // 保证iPhone X系列机型的适配效果, 在view显示出来之后初始化第一个innerTableView的contentInset
        if let scrollView = currentController?.innerScrollView {
            addBottomSafeAreaInsets(to: scrollView)
        }

        // segmentControl 选择事件
        segmentControl?.onSelected = { [weak self] (index) in
            self?.showpage(at: index)
        }

        self.playApperAnimation()

        isFirstApper = false
    }

    /// reload data
    open func reloadData(_ animated: Bool = true) {

        // 获取合理的index
        let index = currentController?.pageIndex ?? startIndex

        // 触发 Segment reload
        segmentControl?.reload(with: index)

        // 滚动到指定页面
        showpage(at: index, animated: animated, isforced: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PageViewController: UITableViewDelegate, UITableViewDataSource {

    // 只有一个 cell
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: NSStringFromClass(UITableViewCell.self),
            for: indexPath)

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        cell.selectionStyle = .none

        if let segmentControl = segmentControl {
            cell.contentView.addSubview(segmentControl)
        }
        cell.contentView.addSubview(pageController.view)
        cell.contentView.addSubview(emptyCoverView)

        return cell
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // cell 高度等于Table高度减去Header最小高度
        return tableView.bounds.height - headerMinHeight
    }

    // scroll contentTableView 滚动事件
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        // 检查scrollView合法，且innerScrolleView有值
        guard scrollView == contentTableView, let inner = innerScrolleView, !isDisappering else { return }

        // 内部scrollView未滚动到指定状态则优先滚动内部
        if inner.contentOffset.y > 0 || scrollView.contentOffset.y > headerOffset {
            contentTableView.contentOffset = CGPoint(x: 0.0, y: headerOffset)
        }

        backgroudView.alpha = max(contentTableView.contentOffset.y / headerOffset * 0.5 + 0.3, 0.3)

        if !emptyCoverView.isHidden {
            updateEmptyViewFrame()
        }

        // 满足触发条件触发下拉退出动画
        if isDismissOffsetEnable, scrollView.contentOffset.y < dissmissOffset {

            isDisappering = true

            // 禁掉现有的滚动动画以避免重复触发退出事件
            scrollView.isUserInteractionEnabled = false
            inner.isUserInteractionEnabled = false

            // 固定现有offset
            scrollView.contentOffset = CGPoint(x: 0, y: dissmissOffset)

            playDisApperAnimation(autoDismiss: true, completion: nil)
        }

        scrollDelegate?.verticalScrollViewDidScroll(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollDelegate?.verticalScrollViewWillBeginDragging(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        // 如果速度大于1则按照速度方向处理动画
        if isHeaderBouncesEnable, abs(velocity.y) > 1 {
            if velocity.y < 0 {
                targetContentOffset.pointee.y = 0
            } else {
                targetContentOffset.pointee.y = headerOffset
            }
            isHeaderBouncesAnimationPalyed = true
        }

        scrollDelegate?.verticalScrollViewWillEndDragging(scrollView,
                                                          withVelocity: velocity,
                                                          targetContentOffset: targetContentOffset)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 如果没有减速，说明是手动拖动松开
        if !decelerate {
            tryPlayHeaderBouncesAnimation()
        }
        scrollDelegate?.verticalScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        tryPlayHeaderBouncesAnimation()
        scrollDelegate?.verticalScrollViewWillBeginDragging(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollDelegate?.verticalScrollViewDidEndDecelerating(scrollView)
    }

    private func tryPlayHeaderBouncesAnimation() {
        if isHeaderBouncesEnable, !isHeaderBouncesAnimationPalyed {
            let offsetY = contentTableView.contentOffset.y
            let shouldOffsetY: CGFloat
            if offsetY > headerOffset / 2 {
                shouldOffsetY = headerOffset
            } else {
                shouldOffsetY = 0
            }
            self.contentTableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
            self.contentTableView.setContentOffset(CGPoint(x: 0, y: shouldOffsetY), animated: true)
        } else {
            isHeaderBouncesAnimationPalyed = false
        }
    }
}

// MARK: - UIPageViewControllerDelegate，UIPageViewControllerDelegate
extension PageViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   willTransitionTo pendingViewControllers: [UIViewController]) {
        currentController?.pageWillTransition()
    }

    // pageview发生滚动时，获取最新的currentController
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool) {

        // 滚动结束后，因为是单页显示，所以“pageViewController.viewControllers?.first”即为当前显示的ViewController
        if finished, let controller = pageViewController.viewControllers?.first as? InnerController {

            // 更新记录的状态
            currentController = controller
            innerScrolleView = controller.innerScrollView
            segmentControl?.select(itemAt: controller.pageIndex)
        }

        currentController?.pageDidTransition()
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // -1 是指获取前一页，PageIndex - 1
        return self.viewController(with: viewController, with: -1)
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // 1 是指获取后一页，PageIndex + 1
        return self.viewController(with: viewController, with: 1)
    }

    private func viewController(with previousViewController: UIViewController,
                                with pageOffset: Int) -> UIViewController? {

        // 所以得 previousViewController 都应该是 InnerController
        guard let controller = previousViewController as? InnerController else { return nil }

        let index = controller.pageIndex + pageOffset

        // index 有效则获取对应的 Controller
        if isValid(index: index), var newController = dataSource?.segmentController(self, controllerAt: index) {
            newController.pageIndex = index
            configInnerScrollViewController(&newController)
            newController.reloadData()
            return newController
        }

        // index 无效或者无法成功获取对应的 Controller 则返回 nil
        return nil
    }

    /// 配置内部 scrollView 的滚动事件
    fileprivate func configInnerScrollViewController(_ viewController: inout InnerController) {
        viewController.innerScrollViewDidScroll = { [weak self] (scrollView) in
            guard let self = self else { return }

            self.innerScrolleView = scrollView

            // 如果 contentTableView 还未滚到顶部则优先滚动 contentTableView
            if self.contentTableView.contentOffset.y < self.headerMaxHeight - self.headerMinHeight {
                scrollView.contentOffset = CGPoint(x: 0, y: 0)
            }
        }

        addBottomSafeAreaInsets(to: viewController.innerScrollView)
    }

    // 保证iPhone X系列机型的适配效果，应该在viewWillLayoutSubviews之后调用才生效，此时self.view.safeAreaInsets才有正确的值
    fileprivate func addBottomSafeAreaInsets(to scrollView: UIScrollView) {
        var inset = scrollView.contentInset
        inset.bottom = self.view.safeAreaInsets.bottom
        scrollView.contentInset = inset
    }

    // 滚动到某一个 index
    fileprivate func showpage(
        at index: Int,
        animated: Bool = true,
        completion: ((Bool) -> Void)? = nil,
        isforced: Bool = false) {

        // 同一index不动
        guard index != currentController?.pageIndex || isforced else { return }

        // index 有效则获取对应的 Controller
        if isValid(index: index), var newController = dataSource?.segmentController(self, controllerAt: index) {

            // 判定滚动方向
            let direction: UIPageViewController.NavigationDirection =
                (index < currentController?.pageIndex ?? 0) ? .reverse: .forward

            // 设置新的Index的状态
            newController.pageIndex = index
            currentController = newController
            innerScrolleView = newController.innerScrollView
            configInnerScrollViewController(&newController)

            newController.reloadData()
            // 滚动到指定的 Index
            pageController.setViewControllers([newController],
                                              direction: direction,
                                              animated: animated,
                                              completion: completion)
        }
    }

    // 检查 pageIndex 合法性
    fileprivate func isValid(index: Int) -> Bool {
        return index > -1 && index < dataSource?.numberOfPage(in: self) ?? 0
    }
}

// MARK: - public func
extension PageViewController {

    /// 切换到指定页面
    ///
    /// - Parameters:
    ///   - index: 索引
    ///   - animated: 是否做动画
    ///   - completion: 动画结束回调
    public func switchPage(to index: Int, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        showpage(at: index, animated: animated, completion: completion)
        segmentControl?.select(itemAt: index)
    }

    /// 注册一个重用的Controller Class
    public func register(_ controllerClass: AnyClass, forControllerWithReuseIdentifier identifier: String) {
        viewControllerClassCache[identifier] = controllerClass
    }

    /// 取出一个可用的Controller
    public func dequeueReusableConrtoller(withReuseIdentifier identifier: String) -> InnerController {

        // 如果能找到一个未被使用的 Controller 则直接返回
        if let controller = cacheControllerPool.first(where: { $0.reuseIdentifier == identifier && $0.parent == nil }) {
            return controller

            // 根据 reuseIdentifier 获取对应的 class， 然后初始化一个对应的Controller
        } else if let clazz = viewControllerClassCache[identifier] as? UIViewController.Type {
            if var controller = clazz.init() as? InnerController {
                controller.reuseIdentifier = identifier
                cacheControllerPool.append(controller)
                return controller
            }
        }

        // 注册 reuse 情况下不应该走到这里
        assert(false, "SegmentViewController ReuseIdentifier: \(identifier) can't find any regisetr class")
        return PageInnerTableViewController()
    }

    fileprivate func setHeaderFrame() {
        var headerFrame = view.bounds
        headerFrame.size.height = headerMaxHeight
        headerView.frame = headerFrame
        self.contentTableView.tableHeaderView = headerView
    }

    // tableview的大小，去掉 safeAreaInsets
    fileprivate func setContentTableFrame() {
        var tableViewFrame = view.bounds
        tableViewFrame.origin.y = view.safeAreaInsets.top + topOffset
        tableViewFrame.size.height -= tableViewFrame.origin.y
        contentTableView.frame = tableViewFrame
        contentFrame = contentTableView.frame
        setPageFrame()
    }

    fileprivate func setEmptyViewFrame() {
        let emptyViewHeight = contentTableView.bounds.height - headerMaxHeight + contentTableView.contentOffset.y
        emptyCoverView.frame = CGRect(
            origin: .zero,
            size: CGSize(width: contentTableView.bounds.width, height: emptyViewHeight))
    }

    fileprivate func setSegmentControlFrame() {
        segmentControl?.frame = CGRect(
            origin: .zero,
            size: CGSize(width: view.bounds.width, height: segmentHeight))
        setPageFrame()
    }

    fileprivate func setPageFrame() {
        var pageFrame = CGRect(x: 0.0, y: 0.0, width: contentTableView.bounds.width, height: contentTableView.bounds.height)
        pageFrame.origin.y += segmentHeight
        pageFrame.size.width -= (contentTableView.safeAreaInsets.left + contentTableView.safeAreaInsets.right)
        pageFrame.size.height -= (segmentHeight + headerMinHeight)
        pageController.view.frame = pageFrame
        self.pageFrame = pageFrame
    }

    fileprivate func reloadFrame() {
        backgroudView.frame = view.bounds
        setContentTableFrame()
        setHeaderFrame()
        setEmptyViewFrame()
        setSegmentControlFrame()
    }

    fileprivate func updateEmptyViewFrame() {
        let emptyViewHeight = contentTableView.bounds.height - headerMaxHeight + contentTableView.contentOffset.y
        var frame = emptyCoverView.frame
        frame.size.height = emptyViewHeight
        emptyCoverView.frame = frame
    }
}

extension PageViewController {
    private func prepareApperAnimation() {
        contentTableView.isHidden = true
        backgroudView.alpha = 0
    }

    private func playApperAnimation() {
        var frame = contentFrame
        frame.origin.y = view.bounds.height
        contentTableView.frame = frame
        contentTableView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.backgroudView.alpha = 0.3
            self.contentTableView.frame = self.contentFrame
        }
    }

    // swiftlint:disable missing_docs
    public func playDisApperAnimation(autoDismiss: Bool, completion: ((Bool) -> Void)?) {
        var frame = contentFrame
        frame.origin.y = view.bounds.height

        UIView.animate(withDuration: 0.25, animations: {
            self.backgroudView.alpha = 0
            self.contentTableView.frame = frame
        }, completion: { [weak self] (finish) in
            completion?(finish)
            if finish, autoDismiss {
                (self?.navigationController ?? self)?.dismiss(animated: false, completion: nil)
            }
        })
    }
    // swiftlint:enable missing_docs
}

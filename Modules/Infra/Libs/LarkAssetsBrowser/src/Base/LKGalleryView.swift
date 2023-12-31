//
//  LKGalleryView.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

public protocol LKGalleryViewDelegate: NSObjectProtocol {

    // DataSource methods

    /// 从代理获取页面总数
    func numberOfPages(in galleryView: LKGalleryView) -> Int

    /// 从代理获取与 index 相对应的页面类型
    func classForPage(in galleryView: LKGalleryView, atIndex index: Int) -> LKGalleryPage.Type

//    func galleryView(_ galleryView: LKGalleryView, pageAtIndex index: Int) -> LKGalleryPage

    // Delegate methods

    /// 当前页标发生变化，可在此时机更新页面指示器
    func galleryView(_ galleryView: LKGalleryView, didChangePageIndex index: Int)

    /// 通知代理该页面已被完全展示在 LKGalleryView 中，可在此时机加载大图
    func galleryView(_ galleryView: LKGalleryView, didShowPage page: LKGalleryPage, atIndex index: Int)

    func galleryView(_ galleryView: LKGalleryView, willScrollOutPage page: LKGalleryPage, atIndex index: Int)

    func galleryView(_ galleryView: LKGalleryView, shouldReloadDataForPage page: LKGalleryPage, atIndex index: Int)

    /// 通知代理 LKGalleryView 刚刚创建该页面，可以在此时机为页面加载必要的展示数据，如加载缩略图等操作
    func galleryView(_ galleryView: LKGalleryView, didPreparePage page: LKGalleryPage, atIndex index: Int)

    /// 通知代理 LKGalleryView 将要回收该页面，可以在此时机手动释放资源
    func galleryView(_ galleryView: LKGalleryView, didRecyclePage page: LKGalleryPage, atIndex index: Int)
}

open class LKGalleryView: UIView, UIScrollViewDelegate {

    public enum ScrollDirection {
        case horizontal
        case vertical
    }

    public weak var delegate: LKGalleryViewDelegate?

    /// 弱引用 AssetBrowser
    open weak var assetBrowser: LKAssetBrowser?

    // MARK: DataSource

    /// 滑动方向
    public var scrollDirection: ScrollDirection = .horizontal

    /// 页间距
    public var pageSpacing: CGFloat = 20

    /// 当前页码。给本属性赋值不会触发`didChangedPageIndex`闭包。
    public var currentPageIndex: Int = 0 {
        didSet {
            previousPageIndex = oldValue
            // UGLY, not use flags
            if currentPageIndex != oldValue {
                isPageIndexChanged = true
                pageIndexInitial = false
                delegate?.galleryView(self, didChangePageIndex: currentPageIndex)
            }
            if pageIndexInitial {
                pageIndexInitial = false
                delegate?.galleryView(self, didChangePageIndex: currentPageIndex)
            }
        }
    }

    /// 页码是否已改变
    private var isPageIndexChanged = true
    private var pageIndexInitial = true
    private var previousPageIndex: Int = 0

    /// 容器
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        return scrollView
    }()

    /// 是否旋转
    var isDeviceRotating = false

    deinit {
        LKAssetBrowserLogger.debug("deinit - \(self.classForCoder)")
    }

    public init(delegate: LKGalleryViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }

    private override init(frame: CGRect) {
        fatalError("Should assign a delegate at init stage.")
    }

    public required init?(coder: NSCoder) {
        fatalError("Should assign a delegate at init stage.")
    }

    public func setup() {
        addSubview(scrollView)
        backgroundColor = .clear
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = frameForScrollView()
        reloadData()
    }

    /// 刷新数据，同时刷新Cell布局
    public func reloadData() {
        // 修正pageIndex，同步数据源的变更
        let pageCount = delegate!.numberOfPages(in: self)
        currentPageIndex = min(max(currentPageIndex, 0), pageCount)
        resetContentSize()
        rearrangePages()
        resetContentOffset()

        // UGLY: 初次打开，或者 reloadData 后，通知回调当前展示的页面
        if let currentPage = visiblePages[currentPageIndex] {
            delegate?.galleryView(self, didShowPage: currentPage, atIndex: currentPageIndex)
        }
    }

    private func resetContentSize() {
        let pageCount = delegate!.numberOfPages(in: self)
        scrollView.contentSize = contentSizeForPageCount(pageCount, withFrame: scrollView.frame)
    }

    /// 根据页码更新滑动位置
    private func resetContentOffset() {
        scrollView.contentOffset = contentOffsetForPage(atIndex: currentPageIndex, withFrame: scrollView.frame)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 屏幕旋转时会触发本方法。此时不可更改pageIndex
        if isDeviceRotating {
            // 这里只需要调 layoutVisiblePages() 就够了，没必要 reloadData()
            layoutFrameForNewVisiblePages(visiblePages)
            isDeviceRotating = false
            return
        }
        // 计算当前的 pageIndex
        currentPageIndex = calculateCurrentPageIndex(for: scrollView)
        // 如果页码变化，重新布局页面，刷新数据源
        if isPageIndexChanged {
            isPageIndexChanged = false
            rearrangePages()
//            delegate?.galleryView(self, didChangePageIndex: currentPageIndex)
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let page = visiblePages[currentPageIndex] {
            delegate?.galleryView(self, willScrollOutPage: page, atIndex: currentPageIndex)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let page = visiblePages[currentPageIndex] {
            delegate?.galleryView(self, didShowPage: page, atIndex: currentPageIndex)
        }
    }

    // MARK: - Reuse & Recycle

    public var currentPage: LKGalleryPage? {
        return visiblePages[currentPageIndex]
    }

    /// 显示中的Cell，key: index
    private var visiblePages = [Int: LKGalleryPage]()

    /// 缓存中的Cell，key: reuseIdentifier
    private var reusablePages = [String: [LKGalleryPage]]()

    /// 当前展示前、后各预加载页面的数量
    public var preloadThreshold: Int = 1
    
    /// 是否允许复用页面，默认为 true
    public var isReuseEnabled: Bool = true

    private func rearrangePages() {
        let newPages = recyclePagesIfNeeded()
        // 如果用 newPages 做 layout，则在旋转屏幕的情况下，首页不会被调到，会导致 layout 错误
        // 所以此处暂时采用全部刷新 frame 的策略
        layoutFrameForNewVisiblePages(visiblePages)
        reloadDataForNewVisiblePages(newPages)
    }

    /// 重置所有Cell的位置。更新 visiblePages 和 reusablePages
    private func recyclePagesIfNeeded() -> [Int: LKGalleryPage] {
        let pageCount = delegate!.numberOfPages(in: self)
        let firstVisibleIndex = max(currentPageIndex - preloadThreshold, 0)
        let lastVisibleIndex = min(currentPageIndex + preloadThreshold, pageCount - 1)
        let visibleRange = firstVisibleIndex...lastVisibleIndex
        guard let browser = assetBrowser else { return [:] }
        // 回收预加载区域外的页面
        for (index, page) in visiblePages where !visibleRange.contains(index) {
            delegate?.galleryView(self, didRecyclePage: page, atIndex: index)
            page.removeFromSuperview()
            visiblePages.removeValue(forKey: index)
            enqueueUnusedPage(page)
        }
        // 补全预加载区域内的页面
        var newPages: [Int: LKGalleryPage] = [:]
        for index in visibleRange where visiblePages[index] == nil {
            let clazz = delegate!.classForPage(in: self, atIndex: index)
            LKAssetBrowserLogger.info("Required class name: \(String(describing: clazz))")
            LKAssetBrowserLogger.info("index:\(index) 出列!")
            let page = dequeueReusablePage(withType: clazz, browser: browser)
            visiblePages[index] = page
            scrollView.addSubview(page)
            newPages[index] = page
            // 为新创建的页面加载数据
            delegate?.galleryView(self, didPreparePage: page, atIndex: index)
        }
        return newPages
    }

    /// 刷新所有显示中的Cell位置
    private func layoutFrameForNewVisiblePages(_ newPages: [Int: LKGalleryPage]) {
        for (index, page) in newPages {
            page.frame = frameForPage(atIndex: index)
        }
    }

    /// 刷新所有Cell的数据
    private func reloadDataForNewVisiblePages(_ newPages: [Int: LKGalleryPage]) {
        newPages.forEach { [weak self] (index, page) in
            guard let `self` = self else { return }
            self.delegate?.galleryView(self, shouldReloadDataForPage: page, atIndex: index)
            page.setNeedsLayout()
        }
    }

    /// 入队
    private func enqueueUnusedPage(_ page: LKGalleryPage) {
        if !isReuseEnabled {
            return
        }
        let reuseIdentifier = page.reuseIdentifier
        if var array = reusablePages[reuseIdentifier] {
            array.append(page)
            reusablePages[reuseIdentifier] = array
        } else {
            reusablePages[reuseIdentifier] = [page]
        }
    }

    /// 出队，没缓存则新建
    private func dequeueReusablePage(withType pageType: LKGalleryPage.Type, browser: LKAssetBrowser) -> LKGalleryPage {
        var page: LKGalleryPage
        let reuseIdentifier = pageType.reuseIdentifier
        if isReuseEnabled, var array = reusablePages[reuseIdentifier], !array.isEmpty {
            LKAssetBrowserLogger.info("命中缓存！\(reuseIdentifier)")
            page = array.removeFirst()
            page.prepareForReuse()
            reusablePages[reuseIdentifier] = array
        } else {
            LKAssetBrowserLogger.info("新建Cell! \(reuseIdentifier)")
            page = pageType.generate(with: browser)
        }
        return page
    }
}

// MARK: - Layout

extension LKGalleryView {

    /// 计算当前偏移量的页码
    private func calculateCurrentPageIndex(for scrollView: UIScrollView) -> Int {
        switch scrollDirection {
        case .horizontal:
            guard scrollView.bounds.width > 0 else { return 0 }
            return Int(round(scrollView.contentOffset.x / (scrollView.bounds.width)))
        case .vertical:
            guard scrollView.bounds.height > 0 else { return 0 }
            return Int(round(scrollView.contentOffset.y / (scrollView.bounds.height)))
        }
    }

    /// 返回 ScrollView 的位置
    private func frameForScrollView() -> CGRect {
        switch scrollDirection {
        case .horizontal:
            return CGRect(x: 0, y: 0, width: bounds.width + pageSpacing, height: bounds.height)
        case .vertical:
            return CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + pageSpacing)
        }
    }

    /// 计算 ScrollView 的 contentSize
    private func contentSizeForPageCount(_ pageCount: Int, withFrame frame: CGRect) -> CGSize {
        switch scrollDirection {
        case .horizontal:
            return CGSize(
                width: frame.width * CGFloat(pageCount),
                height: frame.height
            )
        case .vertical:
            return CGSize(
                width: frame.width,
                height: frame.height * CGFloat(pageCount)
            )
        }
    }

    /// 计算页面在 ScrollView 中的偏移量
    private func contentOffsetForPage(atIndex pageIndex: Int, withFrame frame: CGRect) -> CGPoint {
        switch scrollDirection {
        case .horizontal:
            return CGPoint(x: CGFloat(pageIndex) * frame.width, y: 0)
        case .vertical:
            return CGPoint(x: 0, y: CGFloat(pageIndex) * frame.height)
        }
    }

    /// 计算页面在 ScrollView 中的位置
    private func frameForPage(atIndex index: Int) -> CGRect {
        let pageWidth = bounds.width
        let pageHeight = bounds.height
        switch scrollDirection {
        case .horizontal:
            return CGRect(
                x: (pageWidth + pageSpacing) * CGFloat(index),
                y: 0,
                width: pageWidth,
                height: pageHeight
            )
        case .vertical:
            return CGRect(
                x: 0,
                y: (pageHeight + pageSpacing) * CGFloat(index),
                width: pageWidth,
                height: pageHeight
            )
        }
    }
}

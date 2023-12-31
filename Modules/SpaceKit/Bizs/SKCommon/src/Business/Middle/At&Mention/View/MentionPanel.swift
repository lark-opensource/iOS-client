//
//  MentionPanel.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/25.
//  

import UIKit
import SnapKit
import SpaceInterface

public final class MentionPanel: UIView {
    public typealias SelectAction = (MentionInfo) -> Void
    public typealias CancelAction = () -> Void
    public typealias DidInvalidLayout = () -> Void

    // MARK: - action properties
    /// 选中列表项，执行的操作
    public var selectAction: MentionPanel.SelectAction? {
        didSet {
            pageViews.forEach { $0.selectAction = selectAction }
        }
    }

    /// 退出时，执行的操作
    public var cancelAction: MentionPanel.CancelAction?

    /// Page 布局
    public var invalidLayoutAction: MentionPanel.DidInvalidLayout?

    // MARK: - config
    private(set) var config: MentionConfig

    public init(config: MentionConfig) {
        self.config = config
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - view properties
    private lazy var atTypeSelectView: MentionTypeSelectView = {
        let view = MentionTypeSelectView(handlers: self.config.cards)
        return view
    }()

    private let shadowHeight: CGFloat = 20

    private var pageViews = [MentionPageView]()
    private var shadowEdgeViews = [ShadowEdgeView]()
    private let scrollContentView = UIView()
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.isDirectionalLockEnabled = true
        view.bounces = false
        return view
    }()

    private var currentSearchParams = MentionPanelSearchParams()

    // MARK: - state properties
    /// reset 之后，不要更新listData的数据
    private var hasBeenReset = false

    private class MentionPanelSearchParams: NSObject {
        var keyword: String?
        var animated: Bool = false

        func reset() {
            keyword = nil
        }
    }

    // MARK: - layout
    override public var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize

        size.height = pageViews.compactMap({ $0.intrinsicContentSize.height }).max()! + atTypeSelectView.bounds.height
        return size
    }

    private func setup() {
        self.backgroundColor = .clear
        atTypeSelectView.selectDelegate = self
        configLayout()
    }

    private func configLayout() {
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        (0..<pageViewCount).forEach {index in
            let pageView = MentionPageView(handler: config.cards[index])
            pageViews.append(pageView)
            pageView.maxVisuableItems = hasTypeSelectView ? Int.max : 3
            scrollContentView.addSubview(pageView)
            pageView.accessibilityIdentifier = "\(index) pageview"
            pageView.delegate = self
            pageView.setup()
            let shadowEdgeView = ShadowEdgeView(frame: .zero)
            shadowEdgeViews.append(shadowEdgeView)
            scrollContentView.insertSubview(shadowEdgeView, belowSubview: pageView)
            shadowEdgeView.snp.makeConstraints({ (make) in
                make.leading.trailing.equalTo(pageView)
                make.bottom.equalTo(pageView.snp.top)
                make.height.equalTo(0)
            })
        }
        addSubview(atTypeSelectView)
        atTypeSelectView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().labeled("底部对齐")
            make.height.equalTo(hasTypeSelectView ? 44 : 0).labeled("指定高度")
        }
        scrollView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(atTypeSelectView.snp.top).labeled("和选择框底部对齐")
            make.top.equalToSuperview()
        }
        scrollContentView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview().labeled("四周对齐")
            make.top.equalToSuperview().offset(shadowHeight)
            make.bottom.equalTo(atTypeSelectView.snp.top).labeled("和选择框底部对齐")
            make.top.equalTo(self).offset(shadowHeight).labeled("和顶部对齐")
        }
        pageViews.forEach { (pageView) in
            pageView.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.width.equalTo(self).labeled("宽度和父view对齐")
                make.height.lessThanOrEqualToSuperview()
            })
        }
        pageViews.last?.snp.makeConstraints({ (make) in
            make.trailing.equalToSuperview().labeled("最后一个右对齐")
        })
        for (right, left) in zip(pageViews[1...], pageViews[..<(pageViewCount - 1)]) {
            right.snp.makeConstraints { (make) in
                make.leading.equalTo(left.snp.trailing).labeled("各个page之间没有间距")
            }
        }
        pageViews.first?.snp.makeConstraints({ (make) in
            make.leading.equalToSuperview().labeled("第一个左对齐")
        })
    }

    func reset() {
//        spaceAssert(Thread.isMainThread)
        currentSearchParams.reset()
        atTypeSelectView.reset()
        pageViews.forEach { $0.reset() }
        scrollView.setContentOffset(.zero, animated: false)
    }
}

// MARK: - Private
extension MentionPanel {
    private func dismissSelf() {
        cancelAction?()
        reset()
    }

    private var pageViewCount: Int {
        return config.cards.count
    }

    private var currentPageView: MentionPageView {
        return pageViews[0]
    }

    private var currentIndex: Int {
        guard hasTypeSelectView, bounds.width > 0 else { return 0 }
        let index = Int(floor(scrollView.contentOffset.x / bounds.width))
        return index
    }
}
// MARK: - 搜索逻辑
extension MentionPanel {
    public func refresh(with keyword: String, animated: Bool = false) {
        if currentIndex >= config.cards.count {
//            spaceAssertionFailure("数组越界")
            return
        }

        hasBeenReset = false
        currentSearchParams.keyword = keyword
        currentSearchParams.animated = animated

        perform(#selector(delayRefresh(params:)), with: currentSearchParams, afterDelay: 0.25)
    }
    @objc
    private func delayRefresh(params: MentionPanelSearchParams) {
        guard hasBeenReset == false else { return }
        pageViews.forEach { pageView in
            pageView.refresh(with: currentSearchParams.keyword ?? "")
        }
    }
}
// MARK: - MentionTypeSelectViewProtocol
extension MentionPanel: MentionTypeSelectViewProtocol {
    func didClickCancel(_ selectView: MentionTypeSelectView) {
//        spaceAssert(selectView == self.atTypeSelectView)
        dismissSelf()
    }

    func selectView(_ selectView: MentionTypeSelectView, didSelectedAt index: Int) {
//        spaceAssert(selectView == self.atTypeSelectView)
        scrollView.setContentOffset(contentOffset(for: index), animated: true)
    }

    private func contentOffset(for index: Int) -> CGPoint {
        return CGPoint(x: bounds.width * CGFloat(index), y: 0)
    }

    /// 底部是否有选择类型的view
    private var hasTypeSelectView: Bool {
        return !(config.cards.count == 1)
    }
}

// MARK: - MentionPageViewDelegate
extension MentionPanel: MentionPageViewDelegate {
    func atListPageViewDidInvalidLayout(_ pageView: MentionPageView) {
        guard currentPageView == pageView else { return }
        invalidateIntrinsicContentSize()
        if self.bounds.height == 0 || hasTypeSelectView == false {
            // 第一次，不要做动画。否则，frame会从0跳到很大的值
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
            self.invalidLayoutAction?()
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                //如果已经展示过了，要调用superview 的layout，否则自己的frame会跳动
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }, completion: { (_) in
                self.invalidLayoutAction?()
            })
        }
    }
    func atListPageViewDismiss(_ pageView: MentionPageView) {
        if hasTypeSelectView && currentPageView == pageView {
            dismissSelf()
        }
    }
}
// MARK: - UIScrollViewDelegate
extension MentionPanel: UIScrollViewDelegate {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == self.scrollView else { return }
        let targetX = targetContentOffset.pointee.x
        let index = Int(floor(targetX / bounds.width))
        atTypeSelectView.updateSelectedState(to: index)
    }
}

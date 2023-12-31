//
//  RefreshBackgroundView.swift
//  LarkUIKit
//
//  Created by liluobin on 2021/4/15.
//

import Foundation
import UIKit
import SnapKit
/// 下拉刷新状态
public enum RefreshUIState: Hashable {
    /// 不展示任何信息，用户未下拉任何距离
    case none
    /// 显示'下拉刷新'，用户下拉了小于self.height距离，isDragging表示用户是否在拖动
    case showDragDownHint(isDragging: Bool)
    /// 显示'释放刷新'，用户下拉了大于self.height距离，isDragging表示用户是否在拖动
    case showReleaseHint(isDragging: Bool)
    /// 正在loading，用户下拉了大于self.height距离然后松手
    case loading
}

/// 下拉刷新视图
open class RefreshBackgroundView: UIView, PullDownRefreshProtocol {
    private typealias Action = () -> Void
    /// 下拉刷新视图加到哪个滚动视图上
    private weak var scrollView: UIScrollView?
    /// 当前下拉刷新状态
    private var state: RefreshUIState = .none
    /// loading中应触发的事件
    var handler: (() -> Void)?
    /// 设置是否可用
    public var enabled: Bool = true {
        didSet {
            if enabled {
                resetFrame()
            } else {
                changeState(.none)
            }
        }
    }
    /// 布局时frame.origin.y往下偏移多少位置
    var downOffsetValueForOriginY: CGFloat = 0.0 {
        didSet {
            if oldValue != downOffsetValueForOriginY {
                resetFrame()
            }
        }
    }
    /// 下拉刷新、拖动释放相关控件
    private let dragAndReleaseViewWrapper = UIView()
    private let dragAndReleaseIcon = UIImageView()
    private let dragAndReleaseHintView = UILabel()
    /// loading控件
    private let loadingView = UIView()
    /// scrollView初始状态的contentInset，self被移除时会清空，其他时候值不会变化
    private var originalContentInset: UIEdgeInsets = UIEdgeInsets.zero
    /// 存放状态转换时执行的Action
    private var statusRoutes: [RefreshUIState: [RefreshUIState: Action]] = [:]
    /// 需要往下拖动多少距离才进行loading态
    private let startLoadingOffset: CGFloat

    init(height: CGFloat, scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.startLoadingOffset = height
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: height))
        self.originalContentInset = scrollView.contentInset
        // 添加下拉刷新、拖动释放控件
        self.layoutDragAndReleaseView()
        // 添加loading控件
        self.layoutLoadingView()
        // 设置一次self.frame
        self.resetFrame()
        // 设置状态转换时执行的Action
        registerStatusMachine()
    }

    /// 外界代码调用，进入loading态
    public func beginRefresh() {
        scrollView?.setContentOffset(CGPoint(x: 0, y: -startLoadingOffset - originalContentInset.top), animated: false)
        self.showLoadingHint()
    }

    /// 外界代码调用，退出loading态，恢复初始状态
    public func endLoadMore() {
        self.changeState(.none)
        self.endInfiniteScrolling()
    }

    private func layoutDragAndReleaseView() {
        let text = BundleI18n.LarkUIKit.Lark_Groups_Pulldowntorefresh
        let wordsWidth: CGFloat = widthForString(text, withFont: UIFont.systemFont(ofSize: 16))
        let totalWidth = wordsWidth + 24
        let leadingOffSet = (UIScreen.main.bounds.width - totalWidth) / 2
        self.addSubview(dragAndReleaseViewWrapper)
        dragAndReleaseViewWrapper.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(24)
        }
        dragAndReleaseViewWrapper.isHidden = true

        dragAndReleaseViewWrapper.addSubview(dragAndReleaseIcon)
        dragAndReleaseIcon.tintColor = .ud.N600
        dragAndReleaseIcon.snp.makeConstraints { (make) in
            make.centerY.leading.equalToSuperview()
            make.width.height.equalTo(20)
        }
        dragAndReleaseIcon.image = Resources.refreshRelease.withRenderingMode(.alwaysTemplate)

        dragAndReleaseViewWrapper.addSubview(dragAndReleaseHintView)
        dragAndReleaseHintView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(dragAndReleaseIcon.snp.trailing).offset(4)
            make.height.equalTo(20)
            make.trailing.equalToSuperview()
        }
        dragAndReleaseHintView.font = UIFont.systemFont(ofSize: 16)
        dragAndReleaseHintView.textColor = UIColor.ud.N600
    }

    private func layoutLoadingView() {
        let indicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
        indicator.color = UIColor.ud.N600
        indicator.startAnimating()
        let label = UILabel()
        loadingView.addSubview(indicator)
        loadingView.addSubview(label)
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N600
        indicator.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(indicator.snp.trailing).offset(4)
            make.trailing.equalToSuperview()
        }
        label.text = BundleI18n.LarkUIKit.Lark_Groups_RefreshLoading
        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(24)
        }
        loadingView.isHidden = true
    }

    private func registerStatusMachine() {
        register(fromState: .none, toState: .showDragDownHint(isDragging: true)) { [weak self] in
            self?.showDragDownHint()
        }
        register(fromState: .showDragDownHint(isDragging: true), toState: .none) { [weak self] in
            self?.hideHint()
        }
        register(fromState: .showDragDownHint(isDragging: true), toState: .showReleaseHint(isDragging: true)) { [weak self] in
            self?.showReleaseHint()
        }
        register(fromState: .showReleaseHint(isDragging: true), toState: .showDragDownHint(isDragging: true)) { [weak self] in
            self?.showDragDownHint()
        }
        register(fromState: .showReleaseHint(isDragging: true), toState: .showReleaseHint(isDragging: false)) { [weak self] in
            self?.showLoadingHint()
        }
        /// 从释放刷新的拖拽状态 松手后进入下拉刷新也是需要load的
        register(fromState: .showReleaseHint(isDragging: true), toState: .showDragDownHint(isDragging: false)) { [weak self] in
            self?.showLoadingHint()
        }

        register(fromState: .loading, toState: .none) { [weak self] in
            self?.endInfiniteScrolling()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObserver(self.superview)
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        self.removeObserver(self.superview)
        self.addObserver(newSuperview)
        if newSuperview == nil {// 被从superView上面移走
            UIView.animate(withDuration: 0.25) {
                self.scrollView?.contentInset = self.originalContentInset
            }
            self.originalContentInset = .zero
        }
    }

    public func endRefresh() {
        self.endLoadMore()
    }

    private func addObserver(_ view: UIView?) {
        guard let scrollView = view as? UIScrollView else {
            return
        }
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
    }

    private func removeObserver(_ view: UIView?) {
        view?.removeObserver(self, forKeyPath: "contentOffset")
    }

    // swiftlint:disable:next block_based_kvo
    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let scrollView = self.scrollView else {
            return
        }
        // self sizing 诡异事件
        if keyPath == "contentOffset" {
            if scrollView.frame.origin.y < 0 || !enabled || change == nil {
                return
            }
            if let change, let offSet = change[.newKey] as? CGPoint {
                scrollViewDidScroll(offSet)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func scrollViewDidScroll(_ contentOffset: CGPoint) {
        // if state == .loading. not change state when change scroll. 已经在loading状态时不应该在响应didScroll引起的文案变化。
        if self.state == .loading {
            return
        }
        let dragOffset: CGFloat = -originalContentInset.top
        let triggerOffset: CGFloat = -originalContentInset.top - startLoadingOffset
        if contentOffset.y <= triggerOffset {
            changeState(.showReleaseHint(isDragging: scrollView?.isDragging ?? false))
        } else if contentOffset.y > triggerOffset && contentOffset.y < dragOffset {
            changeState(.showDragDownHint(isDragging: scrollView?.isDragging ?? false))
        } else {
            changeState(.none)
        }
    }

    private func endInfiniteScrolling() {
        endInfiniteScrolling(withStoppingContentOffset: false)
    }

    /// stopContentOffset：contentInset恢复后是否保持contentOffset不变
    private func endInfiniteScrolling(withStoppingContentOffset stopContentOffset: Bool) {
        stopInfiniteScroll(withStoppingContentOffset: stopContentOffset)
    }

    private func stopInfiniteScroll(withStoppingContentOffset stopContentOffset: Bool) {
        guard let scrollView = self.scrollView,
            scrollView.contentInset != originalContentInset else { return }
        scrollView.bounces = false
        // 得到因为loading态改变后的contentInset
        var contentInset: UIEdgeInsets = scrollView.contentInset
        // 这里为啥要改变contentInset.bottom？
        contentInset.bottom -= frame.height
        let offset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y)
        setScrollViewContentInset(contentInset, animated: !stopContentOffset, completion: { [weak self] (_ finished: Bool) -> Void in
            guard let `self` = self else { return }
            if stopContentOffset {
                scrollView.contentOffset = offset
            }
            if finished {
                scrollView.bounces = true
                self.loadingView.isHidden = true
                self.resetScrollViewContentInset(withCompletion: {(_ finished: Bool) -> Void in
                    self.changeState(.none)
                })
            }
        })
    }

    private func resetScrollViewContentInset(withCompletion completion: @escaping (_ finished: Bool) -> Void) {
        UIView.animate(withDuration: 0.3, delay: 0, options: ([.allowUserInteraction, .beginFromCurrentState]), animations: {() -> Void in
            self.setScrollViewContentInset(self.originalContentInset)
        }, completion: completion)
    }

    private func changeState(_ state: RefreshUIState) {
        if self.state == state {
            return
        }
        let fromState = self.state
        let toState = state
        self.state = state
        listen(fromState: fromState, toState: toState)
    }

    private func register(fromState: RefreshUIState, toState: RefreshUIState, action: @escaping () -> Void) {
        var routes = statusRoutes[fromState] ?? [:]
        routes[toState] = action
        statusRoutes[fromState] = routes
    }

    private func listen(fromState: RefreshUIState, toState: RefreshUIState) {
        if let action = statusRoutes[fromState]?[toState] {
            action()
        }
    }

    @objc
    private func callInfiniteScrollActionHandler() {
        handler?()
    }

    private func showDragDownHint() {
        dragAndReleaseViewWrapper.isHidden = false
        loadingView.isHidden = true
        UIView.animate(withDuration: 0.2) {
            self.dragAndReleaseIcon.transform = CGAffineTransform(rotationAngle: 0)
        }
        dragAndReleaseIcon.image = Resources.refreshDrag.withRenderingMode(.alwaysTemplate)
        dragAndReleaseHintView.text = BundleI18n.LarkUIKit.Lark_Groups_Pulldowntorefresh
    }

    private func showReleaseHint() {
        dragAndReleaseViewWrapper.isHidden = false
        loadingView.isHidden = true
        UIView.animate(withDuration: 0.2) {
            // give a very small angle to make sure anticlockwise
            self.dragAndReleaseIcon.transform = CGAffineTransform(rotationAngle: CGFloat.pi + 0.0001)
        }
        dragAndReleaseHintView.text = BundleI18n.LarkUIKit.Lark_Groups_Releasetorefresh
    }

    private func showLoadingHint() {
        if state == .loading {
            return
        }
        dragAndReleaseViewWrapper.isHidden = true
        loadingView.isHidden = false
        changeState(.loading)
        startInfiniteScroll()
    }

    private func hideHint() {
        resetFrame()
    }

    private func startInfiniteScroll() {
        guard var contentInset = scrollView?.contentInset,
              contentInset.top != originalContentInset.top + frame.height else { return }
        contentInset.top = originalContentInset.top + frame.height
        // 改变contentInset，使得loading视图能一直出现在视野内
        setScrollViewContentInset(contentInset, animated: true, completion: { _ in })
        perform(#selector(self.callInfiniteScrollActionHandler), with: self, afterDelay: 0.1, inModes: [.default])
    }

    public func resetFrame() {
        guard let width = self.scrollView?.bounds.width else {
            return
        }
        let height = bounds.size.height
        let frame = CGRect(
            x: -originalContentInset.left,
            y: -height + downOffsetValueForOriginY,
            width: width == 0 ? UIScreen.main.bounds.width : width,
            height: height
        )
        self.frame = frame
    }

    private func setScrollViewContentInset(_ contentInset: UIEdgeInsets, animated: Bool, completion: @escaping (_ finished: Bool) -> Void) {
        let updateBlock: (() -> Void) = {() -> Void in
            self.setScrollViewContentInset(contentInset)
        }
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,
                options: ([.allowUserInteraction, .beginFromCurrentState]),
                animations: updateBlock,
                completion: completion
            )
        } else {
            UIView.performWithoutAnimation(updateBlock)
            completion(true)
        }
    }

    private func setScrollViewContentInset(_ contentInset: UIEdgeInsets) {
        scrollView?.contentInset = contentInset
    }

    private func widthForString(_ string: String, withFont font: UIFont) -> CGFloat {
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }
}

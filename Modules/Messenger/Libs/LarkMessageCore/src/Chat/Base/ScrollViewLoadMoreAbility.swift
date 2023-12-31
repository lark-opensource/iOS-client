//
//  ScrollViewLoadMoreAbility.swift
//  LarkMessageCore
//
//  Created by zhaojiachen on 2023/8/7.
//

import UIKit
import SnapKit
import LarkUIKit
import LKCommonsTracker
import LarkCore
import LarkKeyCommandKit
import LKCommonsLogging
import LarkFoundation
import RxSwift

public protocol CommonScrollViewLoadMoreDelegate: AnyObject {
    /// 展示loading时会产生回调
    func showTopLoadMore(status: ScrollViewLoadMoreStatus)
    /// 展示loading时会产生回调
    func showBottomLoadMore(status: ScrollViewLoadMoreStatus)
    func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
}

// MARK: - UIScrollView public extesnion
extension UIScrollView {

    @objc
    open func canPreLoadMoreOffset() -> Bool {
        return self.contentOffset.y > 0
    }

    @objc
    open func headerRefreshStyle() -> ScrollViewHeaderRefreshStyle {
        return .activityIndicator
    }

    public func setLoadMoreHandlerDelegate(_ delegate: CommonScrollViewLoadMoreDelegate) {
        assert(Thread.isMainThread)
        self.loadMoreDelegate = delegate
    }

    public var enableTopPreload: Bool {
        get {
            return config.enableTopPreload
        }
        set {
            config.enableTopPreload = newValue
        }
    }

    public var enableBottomPreload: Bool {
        get {
            return config.enableBottomPreload
        }
        set {
            config.enableBottomPreload = newValue
        }
    }

    public var triggerOffSet: CGFloat {
        get {
            return config.triggerOffSet
        }
        set {
            config.triggerOffSet = newValue
        }
    }

    public var hasHeader: Bool {
        get {
            return config.hasHeader
        }
        set {
            config.hasHeader = newValue
            if newValue {
                self.resetTableViewHeader()
            } else {
                self.removeTopLoadMore()
            }
        }
    }

    public var hasFooter: Bool {
        get {
            return config.hasFooter
        }
        set {
            config.hasFooter = newValue
            if newValue {
                self.addBottomLoadMoreView(height: loadMoreHeight, infiniteScrollActionImmediatly: false, handler: { [weak self] in
                    self?.loadMoreDelegate?.showBottomLoadMore(status: .start)
                    self?.loadMoreDelegate?.loadMoreBottomContent(finish: { [weak self] result in
                        self?.mainOrAsync { [weak self] in
                            self?.bottomPreloadHasError = !result.isValid()
                            self?.loadMoreDelegate?.showBottomLoadMore(status: .finish(result))
                        }
                    })
                })
            } else {
                self.removeBottomLoadMore()
            }
        }
    }

    public func excutePreload() {
        if runLoopMonitor == nil {
            runLoopMonitor = CommonTableRunloopMonitor()
        }
        runLoopMonitor?.task = { [weak self] in
            /*预加载逻辑放到runloop闲时
            1.在布局过程中也会调用didScroll,一些瞬时中间状态会导致预加载的“误触发”，afterWaiting时，布局是完成态，不会有“误触发”产生
            2.didScroll调用十分频繁，此处也算是一种降频 (1)只在闲时状态处理回调 (2)只处理最后一次回调
            3.非关键业务，适合放到runloop闲时处理*/
            if self?.enableTopPreload ?? false && !(self?.topPreloadHasError ?? false) {
                self?.preLoadMoreTopContent()
            }
            if self?.enableBottomPreload ?? false && !(self?.bottomPreloadHasError ?? false) {
                self?.preLoadMoreBottomContent()
            }
        }
    }
}

private struct CommonScrollViewLoadMoreAbilityConfig {
    var preLoadingTopContent: Bool = false
    var preLoadingBottomContent: Bool = false
    /// 顶部预加载开关
    var enableTopPreload: Bool = true
    /// 底部预加载开关
    var enableBottomPreload: Bool = true
    /// 触发刷新的偏移量
    var triggerOffSet: CGFloat = 0
    /// 顶部预加载遇到错误，暂停功能
    var topPreloadHasError: Bool = false
    /// 底部预加载遇到错误，暂停功能
    var bottomPreloadHasError: Bool = false
    var hasHeader: Bool = false
    var hasFooter: Bool = false
}

private var CommonScrollViewLoadMoreAbilityConfigKey: String = "CommonScrollViewLoadMoreAbilityConfigKey"
private var CommonScrollViewLoadMoreDelegateKey: String = "CommonScrollViewLoadMoreDelegateKey"
private var CommonScrollViewLoadMoreRunLoopMonitorKey: String = "CommonScrollViewLoadMoreRunLoopMonitorKey"

// MARK: - UIScrollView private extesnion
extension UIScrollView {

    private var config: CommonScrollViewLoadMoreAbilityConfig {
        get {
            assert(Thread.isMainThread)
            if let loadMoreAbilityConfig = objc_getAssociatedObject(self, &CommonScrollViewLoadMoreAbilityConfigKey) as? CommonScrollViewLoadMoreAbilityConfig {
                return loadMoreAbilityConfig
            } else {
                let loadMoreAbilityConfig = CommonScrollViewLoadMoreAbilityConfig()
                objc_setAssociatedObject(self, &CommonScrollViewLoadMoreAbilityConfigKey, loadMoreAbilityConfig, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return loadMoreAbilityConfig
            }
        }
        set {
            assert(Thread.isMainThread)
            objc_setAssociatedObject(self, &CommonScrollViewLoadMoreAbilityConfigKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var loadMoreDelegate: CommonScrollViewLoadMoreDelegate? {
        get {
            return (objc_getAssociatedObject(self, &CommonScrollViewLoadMoreDelegateKey) as? CommonScrollViewLoadMoreDelegate)
        }
        set(newValue) {
            objc_setAssociatedObject(self, &CommonScrollViewLoadMoreDelegateKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }

    private var runLoopMonitor: CommonTableRunloopMonitor? {
        get { return (objc_getAssociatedObject(self, &CommonScrollViewLoadMoreRunLoopMonitorKey) as? CommonTableRunloopMonitor) }
        set(newValue) { objc_setAssociatedObject(self, &CommonScrollViewLoadMoreRunLoopMonitorKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var preLoadingTopContent: Bool {
        get {
            return config.preLoadingTopContent
        }
        set {
            config.preLoadingTopContent = newValue
        }
    }

    private var preLoadingBottomContent: Bool {
        get {
            return config.preLoadingBottomContent
        }
        set {
            config.preLoadingBottomContent = newValue
        }
    }

    private var topPreloadHasError: Bool {
        get {
            return config.topPreloadHasError
        }
        set {
            config.topPreloadHasError = newValue
        }
    }

    private var bottomPreloadHasError: Bool {
        get {
            return config.bottomPreloadHasError
        }
        set {
            config.bottomPreloadHasError = newValue
        }
    }

    private var loadMoreHeight: CGFloat { return 44 }
    private var preLoadMoreEdge: CGFloat { return UIScreen.main.bounds.height * 2 }

    private func preLoadMoreTopContent() {
        guard !preLoadingTopContent, self.hasHeader else { return }
        let offsetY = self.contentOffset.y
        if offsetY <= preLoadMoreEdge && self.canPreLoadMoreOffset() {
            preLoadingTopContent = true
            self.loadMoreDelegate?.loadMoreTopContent { [weak self] result in
                self?.mainOrAsync { [weak self] in
                    self?.topPreloadHasError = !result.isValid()
                    self?.preLoadingTopContent = false
                }
            }
        }
    }

    private func preLoadMoreBottomContent() {
        guard !preLoadingBottomContent, self.hasFooter else { return }
        let offsetY = self.contentOffset.y
        if offsetY + self.frame.size.height >= self.contentSize.height - preLoadMoreEdge {
            preLoadingBottomContent = true
            self.loadMoreDelegate?.loadMoreBottomContent { [weak self] result in
                self?.mainOrAsync { [weak self] in
                    self?.bottomPreloadHasError = !result.isValid()
                    self?.preLoadingBottomContent = false
                }
            }
        }
    }

    private func resetTableViewHeader() {
        switch headerRefreshStyle() {
        case .activityIndicator:
            self.addTopLoadMoreView(height: loadMoreHeight, infiniteScrollActionImmediatly: false, triggerOffSet: self.triggerOffSet, handler: { [weak self] in
                self?.loadMoreDelegate?.showTopLoadMore(status: .start)
                self?.loadMoreDelegate?.loadMoreTopContent(finish: { [weak self] result in
                    self?.mainOrAsync { [weak self] in
                        self?.topPreloadHasError = !result.isValid()
                        self?.loadMoreDelegate?.showTopLoadMore(status: .finish(result))
                    }
                })
            })
        case .rotateArrow:
            self.addRefreshView(height: loadMoreHeight) { [weak self] in
                self?.loadMoreDelegate?.showTopLoadMore(status: .start)
                self?.loadMoreDelegate?.loadMoreTopContent(finish: { [weak self] result in
                    self?.mainOrAsync { [weak self] in
                        self?.topPreloadHasError = !result.isValid()
                        self?.loadMoreDelegate?.showTopLoadMore(status: .finish(result))
                    }
                })
            }
        }
    }

    private func mainOrAsync(task: @escaping () -> Void) {
        if Thread.isMainThread {
            task()
        } else {
            DispatchQueue.main.async { task() }
        }
    }
}

private final class CommonTableRunloopMonitor {
    var observer: CFRunLoopObserver?
    var task: (() -> Void)?
    init() {
        let activityToObserve: CFRunLoopActivity = [.beforeWaiting, .exit]
        self.observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activityToObserve.rawValue, true, 0) { [weak self] (_, _) in
            self?.task?()
            self?.task = nil
        }
        CFRunLoopAddObserver(RunLoop.main.getCFRunLoop(), observer, CFRunLoopMode.commonModes)
    }

    deinit {
        guard let observer = self.observer else { return }
        CFRunLoopRemoveObserver(RunLoop.main.getCFRunLoop(), observer, CFRunLoopMode.commonModes)
    }
}

//
//  BTContainerGesturePlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/10/10.
//

import SKFoundation
import SKUIKit

class BTContainerGesturePlugin: BTContainerBasePlugin {
    private static let yOffsetNoise = 10.0

    enum ViewType {
        case header
        case catalogue
        case browser
        case custom
    }
    private struct WeakWrapper {
        weak var value: UIView?
        let type: ViewType
    }

    // 是否滚动到顶部
    private var _scrolledToTop: Bool = true
    
    private var touching: Bool = false  // 手指是否在屏幕上
    private var isValidTouching: Bool = false
    private var currentViewType: ViewType?

    private var ancestorViews: [WeakWrapper] = []  // 限制 touch 区域

    private var startPoint: CGPoint?
    private var endPoint: CGPoint?

    // 是否启用
    var enable: Bool = true
    
    override func setupView(hostView: UIView) {
        super.setupView(hostView: hostView)

        if UserScopeNoChangeFG.LYL.disableAllViewAnimation {
            return
        }

        if let view = service?.headerPlugin.view {
            registerAncestorView(view: view, type: .header)
        }
        if let view = service?.viewCataloguePlugin.view {
            registerAncestorView(view: view, type: .catalogue)
        }
        if let view = service?.browserViewPlugin.editorView {
            registerAncestorView(view: view, type: .browser)
        }

        DocsLogger.btInfo("BTContainerGesturePlugin \(self) init")
        NotificationCenter.default.addObserver(self, selector: #selector(handleEventNotify(_:)),
                                               name: Notification.Name.Docs.appliationSentEvent, object: nil)
    }

    func registerAncestorView(view: UIView, type: ViewType = .custom) {
        ancestorViews.append(WeakWrapper(value: view, type: type))
    }

    func unregisterAncestorView(view: UIView) {
        for (idx, wrapper) in ancestorViews.enumerated() {
            guard wrapper.value == view else {
                continue
            }
            ancestorViews.remove(at: idx)
            return
        }
    }

    // 重置 scrolledToTop（不会触发手势动作）
    func resetToTop() {
        _scrolledToTop = true
    }
    // 滚动到顶
    func scrolledToTop(_ isTop: Bool) {
        guard _scrolledToTop != isTop else {
            return
        }
        _scrolledToTop = isTop
        if !touching, isTop {
            // 手指离屏的情况下，说明是惯性滚动触发，则自动触发
            shouldScrollToDirection(direction: .down)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        DocsLogger.btInfo("BTContainerGesturePlugin \(self) deinit")
    }
    
    @objc
    func handleEventNotify(_ notify: Notification) {
        guard enable, let event = notify.userInfo?["event"] as? UIEvent else {
            return
        }
        self.handle(event: event)
    }
    
    func handle(event: UIEvent) {
        debugPrint("receiveEvent: \(event)")
        // 只支持单指操作。
        guard let touch = event.allTouches?.first else {
            return
        }
        let currentPoint = touch.location(in: touch.window)
        switch touch.phase {
        case .began:
            touching = true
            let check = canHandle(touch: touch)
            if check.canHande {
                // 检测触摸起点是否是 ancestorView 或其子视图
                clearPoint()
                updatePoint(curPoint: currentPoint)
                currentViewType = check.viewType
                isValidTouching = true
            } else {
                clearPoint()
            }
        case .moved, .stationary:
            if isValidTouching {
                updatePoint(curPoint: currentPoint)
            }
        case .ended, .cancelled:
            touching = false
            if isValidTouching {
                updatePoint(curPoint: currentPoint)

                let direction = TranslationDirectionDetector.detect(getTranslation())
                if direction == .up || direction == .down {
                    shouldScrollToDirection(direction: direction)
                }
            }
            clearPoint()
        default: break
        }
    }

    private func canHandle(touch: UITouch) -> (canHande: Bool, viewType: ViewType?) {
        guard status.fullScreenType == .none else {
            DocsLogger.btInfo("[BTContainerGesturePlugin] can not handle touch because is fullScreen")
            return (false, nil)
        }
        for viewWrapper in ancestorViews {
            guard let view = viewWrapper.value else {
                continue
            }
            if touch.view == view || touch.view?.isDescendant(of: view) == true {
                return (true, viewWrapper.type)
            }
        }
        return (false, nil)
    }

    private func updatePoint(curPoint: CGPoint) {
        if startPoint == nil || endPoint == nil {
            startPoint = curPoint
            endPoint = curPoint
            return
        }
        guard let startPoint = startPoint, let endPoint = endPoint else {
            return
        }
        if (curPoint.y > startPoint.y && curPoint.y > endPoint.y)
            || (curPoint.y < startPoint.y && curPoint.y < endPoint.y) {
            self.endPoint = curPoint
            return
        }
        if abs(curPoint.y - endPoint.y) >= Self.yOffsetNoise {
            self.startPoint = self.endPoint
            self.endPoint = curPoint
        }
    }

    private func clearPoint() {
        startPoint = nil
        endPoint = nil
        currentViewType = nil
        isValidTouching = false
    }

    func getTranslation(useMaxCount: Int = 20) -> CGPoint {
        guard let startPoint = startPoint, let endPoint = endPoint else {
            return .zero
        }
        return CGPoint(x: endPoint.x - startPoint.x, y: endPoint.y - startPoint.y)
    }
    
    private func shouldScrollToDirection(direction: TranslationDirectionDetector.ScrollDirection) {
        if direction == .up {
            // 滑动视图栏不触发 toolbar 的显示隐藏
            let canSwitchToolBar = !(currentViewType == .catalogue && status.baseHeaderHidden)
            /*
             客户端是在 touchEnd 的时候执行动画
             但是实际测试发现，前端此时还在接受 touchMove 事件，并且因为 webView 在动画期间移动，对应的 touchMove 的 point 也在跟随反向变化
             直接导致 faster 一个反向的移动
             */
            DispatchQueue.main.async { [weak self] in
                self?.service?.headerPlugin.trySwitchHeader(baseHeaderHidden: true)
                if canSwitchToolBar {
                    self?.service?.toolBarPlugin.trySwitchToolBar(toolBarHidden: true)
                }
            }
        } else if direction == .down {
            // 滑动视图栏不触发 toolbar 的显示隐藏，但是如果滑动到顶部，则依旧显示 toolbar
            let canSwitchToolBar = !(currentViewType == .catalogue && status.baseHeaderHidden && !_scrolledToTop)
            // 滑动视图栏的时候，即使没有 scrolledToTop，依旧显示 header
            let canSwitchHeader = currentViewType == .catalogue
            let scrolledToTop = self._scrolledToTop
            // 必须要延迟到下个 runloop，不然 faster 内容会抖动
            DispatchQueue.main.async { [weak self] in
                if canSwitchToolBar {
                    self?.service?.toolBarPlugin.trySwitchToolBar(toolBarHidden: false)
                }
                if scrolledToTop || canSwitchHeader {
                    self?.service?.headerPlugin.trySwitchHeader(baseHeaderHidden: false)
                }
            }
        }
    }
}

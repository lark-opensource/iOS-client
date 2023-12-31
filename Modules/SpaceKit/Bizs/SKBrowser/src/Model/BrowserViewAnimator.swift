//
//  BrowserViewAnimator.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/4.
//

import UIKit
import RxSwift
import SnapKit
import SKCommon
import SKUIKit
import SKFoundation
import LarkUIKit

/// 负责处理DocBrowserView的动画逻辑(工具栏跟随键盘、隐藏导航栏、Banner)
class BrowserViewAnimator: NSObject {
    // MARK: Element to be executed
    weak var toolContainer: DocsToolContainer?
    weak var scrollProxy: EditorScrollViewProxy?
    weak var keyboardObservingView: DocsKeyboardObservingView?
    var bannerTopConstraints: Constraint?
    /// 指定能否更新沉浸式浏览状态(正常状态为：未开始 -> 进行中(允许更新) -> 结束)
    var isFullScreenInProgress: Bool {
        return _fullscreenOngoing
    }

    // MARK: Data
    private let topContainerHeightProvider: () -> CGFloat
    private let bottomSafeAreaHeightProvider: () -> CGFloat
    private var hideKeyboardOptions: Keyboard.KeyboardOptions?
    private var inputAccssoryHeight: CGFloat {
        return keyboardObservingView?.frame.height ?? 0
    }
    private var _fullscreenOngoing: Bool = false
    private var _fullscreenStoredOffset: CGPoint = .zero
    private var ignoreKeyboardEvent = false
    private let startNotify = Notification.Name.MakeDocsAnimationStartIgnoreKeyboard
    private let endNotify = Notification.Name.MakeDocsAnimationEndIgnoreKeyboard
    private let minPanelHeight: CGFloat = 180
    //308只是一个兜底值，悬浮键盘出来的时候会用真实的键盘高度重新设置
    var floatKeyBoardHeight: CGFloat = 308
    private var lastKeyboadType: Keyboard.DisplayType = .default

    init(topContainerHeightProvider: @escaping () -> CGFloat, bottomSafeAreaHeightProvider: @escaping () -> CGFloat) {
        self.topContainerHeightProvider = topContainerHeightProvider
        self.bottomSafeAreaHeightProvider = bottomSafeAreaHeightProvider
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(listenStartIgnoreNotify), name: startNotify, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenEndIgnoreNotify), name: endNotify, object: nil)
    }

    @objc
    func listenStartIgnoreNotify() {
        ignoreKeyboardEvent = true
    }

    @objc
    func listenEndIgnoreNotify() {
        ignoreKeyboardEvent = false
    }

    // MARK: External Interface
    /// 键盘事件响应
    func keyboardDidChangeState(_ options: Keyboard.KeyboardOptions, _ floatKeyboardHasSubPanel: Bool = false) {
        // Tips: 工具栏跟随键盘动画只需要接收willShow和willHide两个事件
        switch options.event {
        case .willShow, .didShow:
            handleKeyboardShow(options)
        case .willHide, .didHide:
            handleKeyboardHide(options)
        case .didChangeFrame:
            updateContainer(with: options, animated: true, floatKeyboardHasSubPanel)
        default:
            break
        }
    }

    /// 下拉收起键盘等系统未回调事件导致的键盘frame变化事件处理
    func keyboardFrameChanged(_ frame: CGRect) {
        // 仅下拉收起键盘之类interactive经由此API
        guard scrollProxy?.isTracking == true else { return }
        let bottomSafeAreaHeight = bottomSafeAreaHeightProvider()
        guard let containerView = self.toolContainer, let containerViewSuperView = containerView.superview else {
            DocsLogger.info("BrowserViewAnimator, containerViewSuperView = nil")
            return
        }
        let pointKeyboardInWindow = CGPoint(x: frame.origin.x, y: frame.origin.y + inputAccssoryHeight)
        let pointInSuperView = containerViewSuperView.convert(pointKeyboardInWindow, from: nil)

        let bottomOffset = containerView.frame.height - pointInSuperView.y
        let targetBottomOffset = min(-bottomOffset, -bottomSafeAreaHeight)
        if targetBottomOffset == -bottomSafeAreaHeight {
            NotificationCenter.default.post(name: Keyboard.needHideKeyBoardNotification, object: nil)
        }
        updateContainer(with: targetBottomOffset)
    }

    func updateToolContainer(with bottomOffset: CGFloat) {
        updateContainer(with: bottomOffset)
    }

    /// 开始沉浸式浏览过程，必须保证结束时调用endFullscreenProgress结束
    func beginFullscreenProgress() {
        _fullscreenOngoing = true
    }

    /// 更新沉浸式浏览过程，返回进度
    func updateFullscreenProgress(with contentOffset: CGPoint) -> CGFloat {
        spaceAssert(_fullscreenOngoing, "Can't update fullcreen progress without any ongoing process")
        let threshold = topContainerHeightProvider()
        defer {
            _fullscreenStoredOffset = contentOffset
        }
        if _fullscreenStoredOffset.y > contentOffset.y {
            return -contentOffset.y / threshold
        } else {
            return contentOffset.y / threshold
        }
    }

    /// 结束沉浸式浏览过程，返回进度
    func endFullscreenProgress() {
        spaceAssert(_fullscreenOngoing, "Can't update fullcreen progress without any ongoing process")
        _fullscreenOngoing = false
    }
}

// MARK: Keyboard action handle method
extension BrowserViewAnimator {
    private func handleKeyboardShow(_ options: Keyboard.KeyboardOptions) {
        updateContainer(with: options, animated: true)
    }

    private func handleKeyboardHide(_ options: Keyboard.KeyboardOptions) {
        updateContainer(with: options, animated: true)
    }
    
    private func pointKeyboardInView(keyboardFrame: CGRect, in view: UIView) -> CGPoint {
        //当前window是否为全屏
        let isFullScreen = SKDisplay.windowBounds(view).height == SKDisplay.mainScreenBounds.height
        let keyboardOrigin = keyboardFrame.origin
        
        //使用系统通知keyboardFrame计算出的point
        let keyboardPoint = CGPoint(x: keyboardOrigin.x, y: keyboardOrigin.y + inputAccssoryHeight)
        
        //使用UIInputSetHostView的frame计算出的point
        let hostViewPoint = CGPoint(x: keyboardOrigin.x, y: Keyboard.keyboardHostView?.frame.origin.y ?? keyboardOrigin.y + inputAccssoryHeight)
        
        var pointInKeyboardWindow: CGPoint
        var pointInWindow: CGPoint

        //keyboardFrame为zero时，预期键盘应该是收起或将要收起状态，但此时keyboardHostView的frame可能是错误的
        //所以keyboardFrame为zero时使用键盘事件来布局工具栏
        //https://meego.feishu.cn/larksuite/issue/detail/7807599
        if #available(iOS 16.0, *), keyboardFrame != .zero {
            //键盘在keyboardWindow的位置
            pointInKeyboardWindow = CGPoint(x: keyboardPoint.x, y: keyboardPoint.y + inputAccssoryHeight)
            //使用搜狗输入法会出现两个的keyboardWindow，无法取到正确的window去convert坐标
            //这里的keyboardPoing.y值已经是文档window顶部到键盘顶部的距离，所以也不需要再从键盘window convert坐标。
            pointInWindow = pointInKeyboardWindow
        } else {
            pointInKeyboardWindow = keyboardPoint
            //convert键盘在文档window上的的位置
            pointInWindow = Keyboard.keyboardWindow?.convert(pointInKeyboardWindow, to: view.window) ?? pointInKeyboardWindow
        }
        //convert键盘在文档视图上的位置
        var pointInView = view.convert(pointInWindow, from: nil)
        if pointInView.y > view.frame.height {
            pointInView = CGPoint(x: pointInView.x, y: view.frame.height)
        }
        return pointInView
    }

    // swiftlint:disable cyclomatic_complexity
    private func updateContainer(with options: Keyboard.KeyboardOptions, animated: Bool, _ floatKeyboardHasSubPanel: Bool = false) {
        guard ignoreKeyboardEvent == false else { return }
        guard let containerView = self.toolContainer, let containerViewSuperView = containerView.superview else {
            DocsLogger.info("BrowserViewAnimator, containerViewSuperView = nil")
            return
        }

        if options.event == .willShow || options.event == .didShow {
            let beginKeyboardY = options.beginFrame.origin.y
            let endKeyboardY = options.endFrame.origin.y

            //iOS15悬浮键盘，拖动停止后，键盘下落的过程中，会收到willShow事件
            //这时的beginFrame会等于endFrame，这种情况不需要更新工具栏的frame
            if beginKeyboardY == endKeyboardY {
                return
            }
        }
        
        var pointInSuperView = self.pointKeyboardInView(keyboardFrame: options.endFrameInWindow, in: containerViewSuperView)

        let bottomInset: CGFloat = containerViewSuperView.safeAreaInsets.bottom

        if let originY = self.toolContainer?.frame.origin.y {
            self.toolContainer?.frame = CGRect(x: 0, y: originY, width: containerViewSuperView.frame.size.width, height: containerViewSuperView.frame.size.height)
        }
        
        DocsLogger.info("updateContainer event:\(options.event) beginFrame:\(options.beginFrame) endFrame:\(options.endFrame) containerView:\(containerView), pointInSuperView: \(pointInSuperView)", component: LogComponents.toolbar)
        
        var targetBottomOffset: CGFloat = min(-(containerViewSuperView.frame.height - pointInSuperView.y), -bottomInset)
        
        lastKeyboadType = options.displayType
        
        
        guard options.displayType == .floating || targetBottomOffset > -containerView.frame.height else { return }
        toolContainer?.layer.removeAllAnimations()
        #if canImport(ShazamKit)
        if #available(iOS 15.0, *),
           SKDisplay.pad,
           (options.event == .willShow || options.event == .didShow || options.event == .didChangeFrame) {
            //https://bits.bytedance.net/meego/docx/issue/detail/2760660#detail
            //在iOS15下，iPad键盘是悬浮状态，需要将工具栏向上移动4个pt，避免工具栏被悬浮键盘的阴影遮挡
            if targetBottomOffset > -180 {
                targetBottomOffset -= 4
            } else {
                //https://meego.feishu.cn/larksuite/issue/detail/4779392#detail
                //在iOS15下，打开图片选择器，后退出，再次聚焦打开图片选择器，系统键盘事件发送的键盘高度跟实际的键盘高度不符
                //键盘上TUISystemInputAssistantView在iPad iOS15上正常的高度为55，该异常情况下为69，相差14
                let keyBoardHostViewHeight = Keyboard.keyboardHostView?.bounds.height ?? options.endFrame.height
                if keyBoardHostViewHeight - options.endFrame.height == 14 {
                    targetBottomOffset -= 14
                    DocsLogger.info("updateContainer modify keyboardHeight keyBoardHostViewHeight:\(keyBoardHostViewHeight)", component: LogComponents.toolbar)
                }
            }
        }
        #endif
        
        if options.displayType == .floating {
            //ipad悬浮键盘出现时会有hide事件传出，这里屏蔽掉
            if options.event == .didHide {
                return
            }
            if options.event == .didChangeFrame, options.endFrame == .zero {
                targetBottomOffset = 0
            } else if floatKeyboardHasSubPanel {
                let containerWindow = containerViewSuperView.window
                let pointInWindow = containerViewSuperView.convert(CGPoint(x: 0, y: containerViewSuperView.frame.maxY), to: containerWindow)
                let bottomHeight = (containerWindow?.bounds.height ?? SKDisplay.mainScreenBounds.height) - pointInWindow.y
                //迫不得已的方法，悬浮键盘传的高度有时会是362左右，但是真实高度是308左右，后续整理一下参考文档
                if options.endFrame.height > 350 {
                    targetBottomOffset = -floatKeyBoardHeight + bottomHeight
                } else {
                    if options.endFrame.height > minPanelHeight {
                        floatKeyBoardHeight = options.endFrame.height
                    }
                    targetBottomOffset = -floatKeyBoardHeight + bottomHeight
                }
            } else {
                targetBottomOffset = 0
            }
        }

        DocsLogger.info("updateContainer setTargetBottomOffset:\(targetBottomOffset) containerView:\(containerView)", component: LogComponents.toolbar)

        if animated {
            let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
            UIView.animate(withDuration: options.animationDuration, delay: 0, options: animationCurve, animations: {
                self.toolContainer?.frame.origin.y = targetBottomOffset
            }, completion: { _ in
            })
        } else {
            self.toolContainer?.frame.origin.y = targetBottomOffset
        }
    }

    @inline(__always)
    private func updateContainer(with bottomOffset: CGFloat) {
        guard ignoreKeyboardEvent == false else { return }
        toolContainer?.layer.removeAllAnimations()
        self.toolContainer?.frame.origin.y = bottomOffset
    }
}

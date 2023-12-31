//
//  LarkSheetMenuController.swift
//  LarkSheetMenu
//
//  Created by Zigeng on 2023/1/23.
//

import Foundation
import UIKit
import SnapKit
import LarkEmotionKeyboard

enum LarkSheetMenuState {
    case fold
    case expanded
}

enum LarkSheetMenuStyle {
    case sheet
    case padPopover
}

class PassthroughView: UIView {
    weak var menuBGView: UIView?
    weak var passThroughView: UIView?
    var dismissAction: (() -> Void)?
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = passThroughView?.hitTest(self.convert(point, to: passThroughView), with: event)
        // 在背景区域内,用户点击位置不为触控可透传区域,dismiss当前菜单
        if view == nil {
            dismissAction?()
        }
        return view
    }
}

class LarkSheetMenuPresentationController: UIPresentationController {
    private let fixedPassthroughView: PassthroughView

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.addSubview(fixedPassthroughView)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        fixedPassthroughView.frame = containerView?.bounds ?? .zero
    }

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, fixedPassthroughView: PassthroughView) {
        self.fixedPassthroughView = fixedPassthroughView
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
}

class LarkSheetMenuController: UIViewController, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return LarkSheetMenuPresentationController(presentedViewController: presented, presenting: presenting, fixedPassthroughView: fixedPassthroughView)
    }

    var fixedPassthroughView: PassthroughView {
        let fixedPassthroughView = PassthroughView(frame: self.view.bounds)
        fixedPassthroughView.menuBGView = self.view
        fixedPassthroughView.passThroughView = self.fatherView
        fixedPassthroughView.dismissAction = { [weak self] in
            self?.interface.dismiss(completion: nil)
        }
        return fixedPassthroughView
    }

    var reactionOffsetYThreshold: CGFloat? {
        return -50
    }

    var cornerLayerWidth: CGFloat = 10
    var viewModel: LarkSheetMenuViewModel
    var partialDatasource: [LarkSheetMenuActionItem] {
        return viewModel.dataSource.flatMap { $0.sectionItems }
    }
    var layout: LarkSheetMenuLayout
    var source: LarkSheetMenuSourceInfo
    var moreViewScrollContainer: UIScrollView?
    weak var menuDelegate: SheetMenuLifeCycleDelegate?
    weak var fatherView: UIView?
    let unHideLock = NSLock()
    /// Normal Menu View
    lazy var menuView: LarkSheetMenuView = {
        let view = LarkSheetMenuView(layout: layout,
                                     style: style,
                                     viewModel: MenuViewModel(dataSourceFetchBlock: { [weak self] in
            return self?.viewModel.dataSource ?? []
        }),
                                     header: header,
                                     moreView: moreView,
                                     updateMenuHeightCallBack: { [weak self] toHeight in
            self?.updateMenuHeight(toHeight)
        }, dismissCallBack: { [weak self] in
            self?.interface.dismiss(completion: nil)
        })
        return view
    }()

    /// Patial Select Mode Menu View
    lazy var partialView: PartialView = {
        let view = PartialView(vMargin: layout.partialTopAndBottomMargin)
        view.isHidden = true
        view.setSubCells(dataSource: partialDatasource)
        return view
    }()

    unowned var interface: LarkSheetMenuInterface!

    // reaction注入服务
    private let dependency: EmojiDataSourceDependency? = EmojiImageService.default

    // 是否已经 dismiss
    public internal(set) var hadDismiss: Bool = false

    // 是否可以把触摸传递到下一层视图
    var _enableTransmitTouch: Bool = false
    // 优先级高于 handleTouchView
    var _handleTouchArea: ((CGPoint, UIViewController) -> Bool)?
    // 返回响应 hitTest 的 view
    var _handleTouchView: ((CGPoint, UIViewController) -> UIView?)?

    // background view gesture
    private var tapGesture: UITapGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?

    var style: LarkSheetMenuStyle {
        assertionFailure("Need To Override")
        return .sheet
    }

    /// 更新Menu的高度，如果不指定高度，使用默认策略
    func updateMenuHeight(_ toHeight: CGFloat? = nil) {
        assertionFailure("Need To Override")
    }

    var menuHeight: CGFloat {
        return self.menuView.frame.size.height
    }

    /// 当前是否在更多面板
    var isInMoreMode = false

    /// 是否为部分选择态
    var isInPartial: Bool = false {
        didSet {
            if oldValue != isInPartial {
                if isInPartial {
                    setUpPatialStyle()
                } else {
                    setUpNormalStyle()
                }
            }
        }
    }

    /// 设置更多面板是否可以滚动（为了解决和外层容器的手势冲突）
    public func setMoreViewScrollEnabled(isEnabled: Bool) {
        moreViewScrollContainer?.isScrollEnabled = isEnabled
    }

    /// 设置为普通弹出式抽屉样式
    public func setUpNormalStyle() {
        self.menuView.reloadData()
        self.updateMenuHeight()
        partialView.isHidden = true
        menuView.isHidden = false
        interface.hide(animated: false, completion: nil)
    }

    /// 设置为部分选择态样式
    public func setUpPatialStyle() {
        partialView.setSubCells(dataSource: partialDatasource)
        partialView.alpha = 0
        menuView.isHidden = true
        partialView.isHidden = false
    }

    public func hidePartialView(completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            self.partialView.alpha = 0
        }) { finished in
            completion?(finished)
        }
    }

    public func showPartial() {
        guard let window = self.view.window,
              let rect = source.partialRect?() ?? source.sourceView.superview?.convert(source.sourceView.frame, to: self.view) else {
            return
        }
        if partialView.superview == nil {
            self.view.addSubview(partialView)
        }
        partialView.reLayout(sourceRect: window.convert(rect, to: self.view))
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            self.partialView.alpha = 1
        })
    }

    /// disMiss动画结束后的行为
    public func dismissAfterAnimation(completion: (() -> Void)?) {
        if self.parent != nil {
            self.removeFromParent()
            self.view.removeFromSuperview()
            completion?()
            self.menuDelegate?.menuDidDismiss(self.interface)
        } else if self.presentingViewController != nil {
            self.dismiss(animated: false) {
                self.menuDelegate?.menuDidDismiss(self.interface)
                completion?()
            }
        } else {
            self.menuDelegate?.menuDidDismiss(self.interface)
            completion?()
        }
        if let gesture = self.tapGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }
        if let gesture = self.longPressGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        menuDelegate?.menuWillAppear(interface)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        interface.dismiss(completion: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(vm: LarkSheetMenuViewModel,
                source: LarkSheetMenuSourceInfo,
                layout: LarkSheetMenuLayout) {
        self.viewModel = vm
        let menuLayout = layout
        let selectionCount = vm.dataSource.count
        var itemCount = 0
        vm.dataSource.forEach { section in
            itemCount += section.sectionItems.count
        }
        self.layout = menuLayout.updateLayout(sectionCount: selectionCount,
                                               itemCount: itemCount,
                                               header: vm.header)
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    public override func loadView() {
        let view = LarkSheetMenuBGView(delegate: self, shadowDown: style == .padPopover)
        changeBackGroundAlphaTo = { alpha in
            view.changeBackGroundAlphaTo(alpha)
        }
        self.view = view
    }

    var changeBackGroundAlphaTo: ((CGFloat) -> Void)?

    deinit {
        if let gesture = self.tapGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }

        if let gesture = self.longPressGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }
    }
}

extension LarkSheetMenuController {
    private func hasMenuVC(in vc: UIViewController) -> Bool {
        for childrenVC in vc.children where (childrenVC as? LarkSheetMenuController) != nil {
            return true
        }
        return false
    }

    func dismissOthers(in vc: UIViewController) {
        for childrenVC in vc.children where (childrenVC as? LarkSheetMenuController) != nil {
            if !(childrenVC === self) {
                (childrenVC as? LarkSheetMenuInterface)?.dismiss(completion: nil)
            }
        }
    }
}

// MARK: 顶部Header区域与更多面板
extension LarkSheetMenuController {
    var supportMoreReactions: Bool {
        switch viewModel.moreView {
        case.emoji:
            return true
        default:
            return false
        }
    }

    /// Header
    var header: UIView? {
        switch viewModel.header {
        case .custom(let view):
            return view
        case .emoji(let emojiItem):
            let bar = ReactionBar(config: .init(reactionSize:CGSize(width: 30, height: 30), moreIconSize: CGSize(width: 30, height: 30), items: emojiItem, supportMoreReactions: supportMoreReactions, supportSheetMenu: true, edgeInset: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 22)))
            bar.clickMoreBlock = { [weak self] in
                self?.interface.switchToMoreView()
            }
            return bar
        case .invisible:
            return nil
        }
    }

    /// 更多面板
    var moreView: UIView? {
        let offsetYThreshold: CGFloat = -50
        switch viewModel.moreView {
        case .custom(let view):
            return view
        case .emoji(let emojiGroup, let clickBlock):
            let config: ReactionPanelConfig = .init(clickReactionBlock: clickBlock,
                                                    scrollViewDidScrollBlock: { [weak self] contentOffset in
                if let offsetYThreshold = self?.reactionOffsetYThreshold, contentOffset.y < offsetYThreshold {
                                                            self?.interface.dismiss(completion: nil)
                                                        }
                                                    },
                                                    reactionSize: CGSize(width: 30, height: 30),
                                                    supportSheetMenu: true)
            let reactionPanel = ReactionPanel(config: config)
            moreViewScrollContainer = reactionPanel.collection
            return reactionPanel
        case .invisible:
            return nil
        }
    }
}

// MARK: Tap & LongPress Dismiss Gesture
extension LarkSheetMenuController: UIGestureRecognizerDelegate {
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !isInPartial {
            if self.menuView.isHidden || self.menuView.alpha <= 0 {
                return false
            }
            let point = gestureRecognizer.location(in: self.menuView)
            if self.menuView.bounds.contains(point) {
                return false
            }
        } else {
            if self.partialView.isHidden || self.partialView.alpha <= 0 {
                return false
            }
            let point = gestureRecognizer.location(in: self.partialView)
            if self.partialView.bounds.contains(point) {
                return false
            }
        }
        if let handleTouchArea = self._handleTouchArea,
            handleTouchArea(gestureRecognizer.location(in: self.view), self) {
            return false
        }

        if let handleTouchView = self._handleTouchView,
            handleTouchView(gestureRecognizer.location(in: self.view), self) != nil {
            return false
        }
        return true
    }

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            if String(describing: type(of: otherGestureRecognizer)).hasPrefix("_") || otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
            return true
        }
        return false
    }

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        if String(describing: type(of: otherGestureRecognizer)).hasPrefix("_") || otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
            return false
        }
        return true
    }

    func addDismissTap(view: UIView) {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDismissGesuture(gesture:))
        )

        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.delegate = self
        self.tapGesture = tapGesture
        view.addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleDismissGesuture(gesture:))
        )
        longPressGesture.minimumPressDuration = 0.15
        longPressGesture.delegate = self
        self.longPressGesture = longPressGesture
        view.addGestureRecognizer(longPressGesture)
    }

    @objc
    private func handleDismissGesuture(gesture: UIGestureRecognizer) {
        self.interface.dismiss(completion: nil)
    }
}

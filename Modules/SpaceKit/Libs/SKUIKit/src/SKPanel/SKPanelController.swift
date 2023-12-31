//
//  SKPanelController.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/8/24.
//

import Foundation
import SnapKit
import LarkTraitCollection
import RxSwift
import UniverseDesignColor
import UIKit
import SKFoundation

/// 是否要在特定场景自动 dismiss 掉 panel
public struct SKPanelDismissalStrategy: OptionSet {
    /// 系统 sizeClass 改变时 dismiss
    public static let systemSizeClassChanged = SKPanelDismissalStrategy(rawValue: 1 << 0)
    /// Lark sizeClass 改变时 dismiss
    public static let larkSizeClassChanged = SKPanelDismissalStrategy(rawValue: 1 << 1)
    /// view 尺寸改变时 dismiss
    public static let viewSizeChanged = SKPanelDismissalStrategy(rawValue: 1 << 2)

    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

open class SKPanelController: UIViewController, SKPanelAnimationController {
    
    public var isFormSheet = false

    // swiftlint:disable:next weak_delegate
    private(set) public lazy var adaptivePresentationDelegate: UIAdaptivePresentationControllerDelegate = SKPanelAdaptivePresentationDelegate.default

    // swiftlint:disable:next weak_delegate
    private(set) public lazy var panelTransitioningDelegate: UIViewControllerTransitioningDelegate = SKPanelTransitioningDelegate()

    // swiftlint:disable:next weak_delegate
    private(set) public lazy var panelFormSheetTransitioningDelegate: UIViewControllerTransitioningDelegate = SKPanelFormSheetTransitioningDelegate()

    // sizeClass 变换时是否需要重新布局，仅当 modalPresentationStyle 在 R C 视图没有区别时，才考虑设为 false
    // 设为 false 后，transitionToRegularSize() 不会被调用，请在 transitionToOverFullScreen() 方法内完成布局
    // 注意，此属性没有经过验证，如果设为 false 请加强自测，不支持在 present 后更新此属性
    public var updateLayoutWhenSizeClassChanged = true

    public var automaticallyAdjustsPreferredContentSize = true

    public var inRegularSize: Bool {
        return updateLayoutWhenSizeClassChanged && SKDisplay.pad && isMyWindowRegularSize()
    }

    private(set) public var inRegularSizeLayout: Bool = false

    private(set) public lazy var backgroundMaskView: UIControl = {
        let view = UIControl()
        view.backgroundColor = animationBackgroundColor
        return view
    }()

    private(set) public lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = .top
        return view
    }()

    // viewDidLoad 中，因为取不到window，固定是非popover layout，随后会收到一次 traitCollectionChanged 事件，在此之后才真正表明是不是 popover
    // didAppear 之后，如果再收到 traitCollectionChanged 事件，且 popover layout 需要改变，会根据 dismissWhenSizeClassChanged 按需 dismiss
    public var dismissalStrategy: SKPanelDismissalStrategy = .systemSizeClassChanged
    private var hasAppeared = false
    private let disposeBag = DisposeBag()

    public func setupPopover(sourceView: UIView, direction: UIPopoverArrowDirection) {
        transitioningDelegate = panelTransitioningDelegate
        modalPresentationStyle = .popover
        // 配置 iPad 场景 popover 降级为 overFullScreen 功能
        presentationController?.delegate = adaptivePresentationDelegate
        popoverPresentationController?.backgroundColor = UDColor.bgFloat
        popoverPresentationController?.permittedArrowDirections = direction
        popoverPresentationController?.sourceView = sourceView
        popoverPresentationController?.sourceRect = sourceView.bounds
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // viewDidLoad 的时候，实际上无法判断当前 sizeClass，都会先走到 overFullScreen 样式
        transitionToOverFullScreen()

        if automaticallyAdjustsPreferredContentSize {
            adjustsPreferredContentSize()
        }

        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: view)
            .observeOn(MainScheduler.instance)
            .filter { change in
                change.old.horizontalSizeClass != change.new.horizontalSizeClass
            }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                guard self.dismissalStrategy.contains(.larkSizeClassChanged) else { return }
                self.dismissByStrategy()
            })
            .disposed(by: disposeBag)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 修复 iPad 场景，从 C 视图 overFullScreen，切换到 R 视图 popover，再切回 C 视图时，布局在屏幕外，导致无法交互的问题
        // 怀疑和 Lark 重写了 traitCollection 有关系，待写 demo 验证
        if hasAppeared,
           !inRegularSize,
           view.bounds.size.height == 0 {
            self.dismissByStrategy()
        }
    }

#if swift(>=5.9)
    @available(iOS 13.0, *)
    open override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        guard inRegularSize != inRegularSizeLayout else {
            return
        }
        if inRegularSize {
            transitionToRegularSize()
        } else {
            transitionToOverFullScreen()
        }
    }
#endif

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if hasAppeared, // didAppear 之后才开始判断
           dismissalStrategy.contains(.systemSizeClassChanged) { // 判断是否需要监听系统变化
            self.dismissByStrategy()
            return
        }

        guard inRegularSize != inRegularSizeLayout else {
            return
        }
        if inRegularSize {
            transitionToRegularSize()
        } else {
            transitionToOverFullScreen()
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if hasAppeared, // didAppear 之后才开始判断
           dismissalStrategy.contains(.viewSizeChanged) {
            dismissByStrategy()
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
    }

    open func setupUI() {
        view.addSubview(backgroundMaskView)
        backgroundMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backgroundMaskView.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)

        view.addSubview(containerView)
    }

    // 转换为 popover、formSheet 等 RegularSize 下特有的样式
    open func transitionToRegularSize() {
        inRegularSizeLayout = true
        backgroundMaskView.isHidden = true
        if modalPresentationStyle == .popover {
            containerView.backgroundColor = UDColor.bgFloat
        } else {
            containerView.backgroundColor = UDColor.bgBody
        }
        // 内容区域避开箭头位置
        containerView.snp.remakeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
        if automaticallyAdjustsPreferredContentSize {
            adjustsPreferredContentSize()
        }
    }

    open func adjustsPreferredContentSize() {
        view.layoutIfNeeded()
        var compressSize = UIView.layoutFittingCompressedSize
        let width: CGFloat = isFormSheet ? 575 : 375
        compressSize.width = width
        var preferredSize = containerView.systemLayoutSizeFitting(compressSize)
        // 默认宽度 width
        preferredSize.width = width
        preferredContentSize = preferredSize
    }

    open func transitionToOverFullScreen() {
        inRegularSizeLayout = false
        backgroundMaskView.isHidden = false
        containerView.backgroundColor = UDColor.bgBody
        // 延伸到安全区域下
        containerView.snp.remakeConstraints { make in
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, self.isFormSheet {
                make.edges.equalToSuperview()
            } else {
            make.bottom.equalToSuperview()
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            }
        }
    }

    /// 点击 mask 的处理，默认 dismiss 掉自己
    @objc
    open func didClickMask() {
        dismiss(animated: true)
    }

    open func dismissByStrategy() {
        dismiss(animated: false)
    }

    // MARK: - SKPanelAnimationController
    public var animationBackgroundColor: UIColor {
        UDColor.bgMask
    }

    public var animationBackgroundView: UIView {
        backgroundMaskView
    }

    public var animationContentView: UIView {
        containerView
    }
}

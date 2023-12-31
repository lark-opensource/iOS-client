//
//  BTDraggableViewController.swift
//  SKBitable
//
//  Created by zoujie on 2022/5/18.
//  


import Foundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignShadow
import UIKit
import SKFoundation

class BTDraggableViewController: UIViewController,
                                 BTPanelAnimationController {
    enum ViewHeightMode {
        case minHeight
        case maxHeight
        case initHeight
    }

    var currentViewHeightMode: ViewHeightMode = .minHeight

    var dismissBlock: (() -> Void)?
    
    /// VC 被关闭
    var removeFromParentBlock: (() -> Void)?

    var shouldShowDragBar: Bool
    /// 是否在 Panel 外的区域显示半透明 Mask
    let shouldShowAlphaMask: Bool
    /// 页面dismiss后会调用，调用方可以用来做埋点上报等操作
    var shouldShowDoneButton: Bool
    /// 页面初始高度，仅在页面不可拖拽且modalPresentationStyle非formSheet下有效
    var initViewHeight: CGFloat = 0
    /// 完成按钮文案
    var doneButtonTitle = BundleI18n.SKResource.Bitable_Common_ButtonDone
    /// 外部决定是否要转屏
    var supportedInterfaceOrientationsSetByOutside: UIInterfaceOrientationMask?
    
    private var currentOrientation: UIInterfaceOrientation = .portrait
    
    var popoverOn = false

    // swiftlint:disable:next weak_delegate
    private(set) public lazy var panelTransitioningDelegate: UIViewControllerTransitioningDelegate = BTPanelTransitioningDelegate(shouldShowAlphaMask: shouldShowAlphaMask)

    // swiftlint:disable:next weak_delegate
    private(set) public lazy var panelNavigationDelegate: UINavigationControllerDelegate = BTPanelAnimation(navigationOperation: nil, showMask: shouldShowAlphaMask)

    private(set) public lazy var headerBottomSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    private(set) public lazy var backgroundMaskView = UIControl().construct { it in
        it.backgroundColor = .clear
    }

    lazy var containerView = UIView().construct { it in
        it.backgroundColor = .clear
        it.layer.cornerRadius = 12
        it.layer.maskedCorners = .top
    }

    private lazy var closeButton = UIButton().construct { it in
        it.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
        it.backgroundColor = .clear
        it.addTarget(self, action: #selector(closePage), for: .touchUpInside)
    }

    private lazy var doneButton: UIButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.isHidden = true
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.setTitle(doneButtonTitle, for: .normal)
        it.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        it.addTarget(self, action: #selector(didClickDoneButton), for: .touchUpInside)
    }

    private lazy var titleLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
    }

    private lazy var dragViewLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
        it.layer.cornerRadius = 2
    }

    private lazy var headerView = UIView().construct { it in
        it.backgroundColor = .clear
        it.addSubview(titleLabel)
        it.addSubview(closeButton)
        it.addSubview(doneButton)
        it.addSubview(dragViewLine)

        dragViewLine.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(24)
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.lessThanOrEqualTo(doneButton.snp.left)
        }

        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        doneButton.snp.makeConstraints { make in
            make.width.equalTo(0)
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }
    
    public var customHeader: UIView {
        return headerView
    }

    lazy var contentView = UIView().construct { it in
        it.backgroundColor = .clear
    }

    var maxViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * 0.8
    }

    var midViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * 0.65
    }

    var draggableMinViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * 0.50
    }

    var minViewHeight: CGFloat {
        236
    }

    var fullViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height - self.view.safeAreaInsets.top
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let supportedInterfaceOrientationsSetByOutside = supportedInterfaceOrientationsSetByOutside {
            return supportedInterfaceOrientationsSetByOutside
        }
        return [.allButUpsideDown]
    }

    init(title: String,
         shouldShowDragBar: Bool,
         shouldShowDoneButton: Bool = false,
         shouldShowAlphaMask: Bool = true
    ) {
        self.shouldShowDragBar = shouldShowDragBar
        self.shouldShowDoneButton = shouldShowDoneButton
        self.shouldShowAlphaMask = shouldShowAlphaMask
        super.init(nibName: nil, bundle: nil)
        self.containerView.backgroundColor = UDColor.bgFloatBase
        self.titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.addSubview(backgroundMaskView)
        backgroundMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backgroundMaskView.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        view.addSubview(containerView)
        
        if shouldShowAlphaMask {
            containerView.layer.ud.setShadowColor(.clear)
        } else {
            containerView.layer.ud.setShadow(type: .s4Up)
        }

        let headerHeightZero = popoverOn
        containerView.addSubview(customHeader)
        containerView.addSubview(headerBottomSeparator)
        containerView.addSubview(contentView)
        customHeader.snp.makeConstraints { make in
            make.top.left.right.equalTo(containerView.safeAreaLayoutGuide)
            if headerHeightZero {
                make.height.equalTo(0)
            } else {
            make.height.equalTo(60)
            }
        }

        headerBottomSeparator.snp.makeConstraints { make in
            make.top.equalTo(customHeader.snp.bottom)
            make.left.right.equalToSuperview()
            if headerHeightZero {
                make.height.equalTo(0)
            } else {
                make.height.equalTo(0.5)
            }
        }

        if self.navigationController?.modalPresentationStyle == .formSheet || popoverOn {
            backgroundMaskView.isHidden = true
            closeButton.isHidden = false
            if popoverOn {
                closeButton.isHidden = true
            }
            dragViewLine.isHidden = true
            // 内容区域避开箭头位置
            containerView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            if titleLabel.superview != nil {
                titleLabel.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(18)
                }
            }
        } else {
            backgroundMaskView.isHidden = false
            closeButton.isHidden = shouldShowDragBar
            dragViewLine.isHidden = !shouldShowDragBar

            if shouldShowDragBar {
                let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panToChangeSize(sender:)))
                customHeader.addGestureRecognizer(panGestureRecognizer)
                initViewHeight = draggableMinViewHeight
            } else {
                currentViewHeightMode = .initHeight
                if titleLabel.superview != nil {
                    titleLabel.snp.updateConstraints { make in
                        make.top.equalToSuperview().offset(14)
                    }
                }
                if customHeader.superview != nil {
                    customHeader.snp.updateConstraints { make in
                        if headerHeightZero {
                            make.height.equalTo(0)
                        } else {
                        make.height.equalTo(48)
                        }
                    }
                } else {
                    DocsLogger.btError("[BTDraggableViewController] header has no superview")
                }
            }

            // 延伸到安全区域下
            containerView.snp.remakeConstraints { make in
                make.height.equalTo(initViewHeight)
                make.left.right.bottom.equalToSuperview()
            }
        }

        remakeContentViewConstraints()
        currentOrientation = UIApplication.shared.statusBarOrientation
        
        setDoneButtonHide(!shouldShowDoneButton)
        if hasBackPage {
            //有上级页面
            closeButton.setImage(UDIcon.leftSmallCcmOutlined.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
        }
    }
    
    /// 设置完成按钮的显示隐藏
    func setDoneButtonHide(_ isHidden: Bool) {
        doneButton.isHidden = isHidden
        doneButton.sizeToFit()
        doneButton.snp.updateConstraints { make in
            make.width.equalTo(!isHidden ? doneButton.bounds.width : 0)
        }
    }
    
    ///
    func setHeaderBottomSeparator(isHidden: Bool) {
        headerBottomSeparator.isHidden = isHidden
    }

    /// 重新布局 contentView，因为有些页面是不需要安全区域的。
    func remakeContentViewConstraints(isContainBottomSafeArea: Bool = false) {
        contentView.snp.remakeConstraints { make in
            make.top.equalTo(headerBottomSeparator.snp.bottom)
            make.left.right.equalTo(containerView.safeAreaLayoutGuide)
            if isContainBottomSafeArea {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalTo(containerView.safeAreaLayoutGuide)
            }
        }
    }
    
    /// 通过代码而不是手势切换高度模式，主要用于可拖拽的时候
    func changeViewHeightMode(_ viewHeightMode: ViewHeightMode, animateDuration: TimeInterval = 0, completed: (() -> Void)? = nil) {
        guard self.navigationController?.modalPresentationStyle == .overFullScreen else {
            completed?()
            return 
        }
        guard viewHeightMode != currentViewHeightMode else {
            completed?()
            return
        }
        self.currentViewHeightMode = viewHeightMode
        self.updateContainerViewHeight(by: viewHeightMode, animateDuration: animateDuration, completed: completed)
    }
 
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
        }) { [self] _ in
            if UIApplication.shared.statusBarOrientation != currentOrientation,
               self.navigationController?.modalPresentationStyle == .overFullScreen {
                currentOrientation = UIApplication.shared.statusBarOrientation
                self.updateContainerViewHeight(by: currentViewHeightMode)
            }
        }
    }
    
    /// 获取 container 的高度
    private func updateContainerViewHeight(by viewHeightMode: ViewHeightMode, animateDuration: TimeInterval = 0, completed: (() -> Void)? = nil) {
        var viewHeight = shouldShowDragBar ? draggableMinViewHeight : minViewHeight
        switch viewHeightMode {
        case .maxHeight:
            viewHeight = maxViewHeight
        case .initHeight:
            viewHeight = min(initViewHeight, maxViewHeight)
        default:
            break
        }
        containerView.snp.updateConstraints { make in
            make.height.equalTo(viewHeight)
        }
        view.setNeedsLayout()
        UIView.animate(withDuration: animateDuration, delay: 0, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animateDuration, execute: {
            completed?()
        })
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            self.removeFromParentBlock?()
        }
    }

    override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: animated, completion: completion)
        self.dismissBlock?()
    }

    @objc
    private func closePage() {
        if hasBackPage {
            didClickBackPage()
        } else {
            didClickClose()
        }
    }

    func didClickBackPage() {
        self.navigationController?.popViewController(animated: true)
    }

    func didClickClose() {
        dismiss(animated: true)
    }

    @objc
    func didClickDoneButton() {
        dismiss(animated: true)
    }

    /// 点击 mask 的处理，默认 dismiss 掉自己
    @objc
    func didClickMask() {
        dismiss(animated: true)
    }

    var animationContentView: UIView {
        containerView
    }
    
    /// 监听拖拽时 containerView 的变化，留给子视图实现
    func containerViewHeightUpdate(byDrag state: UIGestureRecognizer.State, height: CGFloat) {
        
    }

    @objc
    private func panToChangeSize(sender: UIPanGestureRecognizer) {
        let fingerY = sender.location(in: self.view).y
        var fingerHeight = self.view.bounds.height - fingerY
        let translation = sender.translation(in: self.view)
        let panUp = translation.y < 0
        let containerHeight: CGFloat
        var needsAnimate = false
        switch sender.state {
        case .began, .changed:
            fingerHeight = min(fingerHeight, fullViewHeight)
            containerView.snp.updateConstraints { make in
                make.height.equalTo(fingerHeight)
            }
            containerHeight = fingerHeight
        case .ended:
            var endHeight = draggableMinViewHeight
            currentViewHeightMode = .minHeight
            if panUp {
                endHeight = maxViewHeight
                currentViewHeightMode = .maxHeight
            }
            if !panUp, fingerHeight < minViewHeight {
                //下掉面板
                self.dismiss(animated: true)
                return
            }

            containerView.snp.updateConstraints { make in
                make.height.equalTo(endHeight)
            }
            containerHeight = endHeight
            needsAnimate = true
        case .cancelled, .failed:
            let height = currentViewHeightMode == .minHeight ? draggableMinViewHeight : maxViewHeight
            containerView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            containerHeight = height
            needsAnimate = true
        default:
            containerHeight = self.containerView.frame.size.height
        }
        containerViewHeightUpdate(byDrag: sender.state, height: containerHeight)
        
        guard needsAnimate else {
            return
        }
        view.setNeedsLayout()
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            self.view.layoutIfNeeded()
        }
    }
}

extension BTDraggableViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.dismissBlock?()
    }
}

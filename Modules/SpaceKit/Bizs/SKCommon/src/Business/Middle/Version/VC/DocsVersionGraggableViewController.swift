//
//  DocsVersionGraggableViewController.swift
//  SKBrowser
//
//  Created by ByteDance on 2022/9/6.
//

import Foundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UIKit

open class DocsVersionGraggableViewController: UIViewController,
                                               UIViewControllerTransitioningDelegate {
    enum ViewHeightMode {
        case minHeight
        case maxHeight
        case initHeight
    }
    /// 是否执行了present转场动画
    private let animateDuration: Double = 0.3

    var currentViewHeightMode: ViewHeightMode = .minHeight

    public var dismissBlock: (() -> Void)?

    var shouldShowDragBar: Bool
    /// 页面初始高度，仅在页面不可拖拽且modalPresentationStyle非formSheet下有效
    var initViewHeight: CGFloat = 404
    /// 外部决定是否要转屏
    var supportedInterfaceOrientationsSetByOutside: UIInterfaceOrientationMask?
    
    private var currentOrientation: UIInterfaceOrientation = .portrait
    
    private(set) public lazy var headerBottomSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    private(set) public lazy var backgroundMaskView = UIControl().construct { it in
        it.backgroundColor = UDColor.bgMask
    }

    lazy var containerView = UIView().construct { it in
        it.backgroundColor = .clear
        it.clipsToBounds = true
        it.layer.cornerRadius = 12
        it.layer.maskedCorners = .top
    }

    private lazy var closeButton = UIButton().construct { it in
        it.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
        it.backgroundColor = .clear
        it.addTarget(self, action: #selector(closePage), for: .touchUpInside)
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
        }

        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(24)
        }
    }

    lazy var contentView = UIView().construct { it in
        it.backgroundColor = .clear
    }

    var maxViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * (UIApplication.shared.statusBarOrientation.isLandscape ? 0.95 : 0.8)
    }

    var midViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * 0.65
    }

    var draggableMinViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * (UIApplication.shared.statusBarOrientation.isLandscape ? 0.60 : 0.45)
    }

    var minViewHeight: CGFloat {
        236
    }

    var fullViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height - self.view.safeAreaInsets.top
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let supportedInterfaceOrientationsSetByOutside = supportedInterfaceOrientationsSetByOutside {
            return supportedInterfaceOrientationsSetByOutside
        }
        return [.allButUpsideDown]
    }

    init(title: String,
         shouldShowDragBar: Bool) {
        self.shouldShowDragBar = shouldShowDragBar
        super.init(nibName: nil, bundle: nil)
        self.titleLabel.text = title
        self.transitioningDelegate = self
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissBlock?()
    }
    
    func setupUI() {
        view.addSubview(backgroundMaskView)
        backgroundMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backgroundMaskView.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        view.addSubview(containerView)

        containerView.addSubview(headerView)
        containerView.addSubview(headerBottomSeparator)
        containerView.addSubview(contentView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(containerView.safeAreaLayoutGuide)
            make.height.equalTo(60)
        }

        headerBottomSeparator.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        if self.navigationController?.modalPresentationStyle == .formSheet {
            backgroundMaskView.isHidden = true
            dragViewLine.isHidden = true
            // 内容区域避开箭头位置
            containerView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }

            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(18)
            }
        } else {
            backgroundMaskView.isHidden = false
            dragViewLine.isHidden = !shouldShowDragBar
            closeButton.isHidden = !shouldShowDragBar
            if shouldShowDragBar {
                let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panToChangeSize(sender:)))
                headerView.addGestureRecognizer(panGestureRecognizer)
                initViewHeight = draggableMinViewHeight
                // 延伸到安全区域下
                containerView.snp.remakeConstraints { make in
                    make.height.equalTo(initViewHeight)
                    make.left.right.bottom.equalToSuperview()
                }
            } else {
                self.preferredContentSize = CGSize(width: CGFloat.scaleBaseline, height: 440)
                backgroundMaskView.backgroundColor = .clear
                currentViewHeightMode = .initHeight
                titleLabel.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(14)
                }
                containerView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
                headerView.snp.updateConstraints { make in
                    make.height.equalTo(48)
                }
            }
        }

        remakeContentViewConstraints()
        currentOrientation = UIApplication.shared.statusBarOrientation
        
        if hasBackPage {
            //有上级页面
            closeButton.setImage(UDIcon.leftSmallCcmOutlined.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
        }
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
    func changeViewHeightMode(_ viewHeightMode: ViewHeightMode) {
        guard self.navigationController?.modalPresentationStyle == .overFullScreen else {
            return
        }
        guard viewHeightMode != currentViewHeightMode else {
            return
        }
        self.currentViewHeightMode = viewHeightMode
        self.updateContainerViewHeight(by: viewHeightMode)
    }
 
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
    private func updateContainerViewHeight(by viewHeightMode: ViewHeightMode) {
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
    }

    public override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: animated, completion: completion)
        self.dismissBlock?()
    }

    @objc
    public func closePage() {
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

    /// 点击 mask 的处理，默认 dismiss 掉自己
    @objc
    func didClickMask() {
        dismiss(animated: true)
    }

    public var animationContentView: UIView {
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
        case .cancelled, .failed:
            let height = currentViewHeightMode == .minHeight ? draggableMinViewHeight : maxViewHeight
            containerView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            containerHeight = height
        default:
            containerHeight = self.containerView.frame.size.height
        }
        containerViewHeightUpdate(byDrag: sender.state, height: containerHeight)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        return DocsVersionPresentTransitioning(animateDuration: self.animateDuration,
                                                 willPresent: nil,
                                                 animation: nil,
                                                 completion: { [weak self] in
                                                    guard let self = self else { return }
            if self.navigationController?.modalPresentationStyle == .formSheet {
                self.backgroundMaskView.isHidden = true
            } else {
                self.backgroundMaskView.isHidden = false
            }
        })
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        return DocsVersionDismissTransitioning(animateDuration: self.animateDuration,
                                                 willDismiss: nil,
                                                 animation: nil,
                                                 completion: nil)
    }
}

extension DocsVersionGraggableViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.dismissBlock?()
    }
}

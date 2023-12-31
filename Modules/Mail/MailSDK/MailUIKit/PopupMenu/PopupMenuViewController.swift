//
//  PopupMenuViewController.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/17.
//

import UIKit
import SnapKit
import FigmaKit
import UniverseDesignShadow

typealias PopupMenuActionCallBack = (UIViewController, PopupMenuActionItem) -> Void

class PopupMenuActionItem {
    let title: String
    let icon: UIImage
    var actionCallBack: PopupMenuActionCallBack
    var tag: AnyHashable? // 如果需要自己做一些特殊标识
    var isEnabled: Bool = true
    var placeHolderTitle: Bool = false
    var iconColor: UIColor?
    var titleColor: UIColor?

    init(title: String,
         icon: UIImage,
         iconColor: UIColor? = nil,
         titleColor: UIColor? = nil,
         callback: @escaping PopupMenuActionCallBack) {
        self.title = title
        self.icon = icon
        self.actionCallBack = callback
        self.iconColor = iconColor
        self.titleColor = titleColor
    }
}

class PopupMenuViewController: UIViewController {
    private var items: [PopupMenuActionItem] = []
    private let container: UIView = UIView()
    private let innerContainer: UIView = UIView()

    private let itemHeight: Int = 50

    private var rightConstraint: Constraint!
    private var topConstraint: Constraint!
    private var heightConstraint: Constraint!
    private var widthConstraint: Constraint!

    // animator
    var animator: PopupMenuAnimator = DefaultPopupMenuAnimator()

    var animateInfo: PopupMenuAnimateInfo {
        return PopupMenuAnimateInfo(rightConstraint: rightConstraint,
                                    topConstraint: topConstraint,
                                    heightConstraint: heightConstraint,
                                    widthConstraint: widthConstraint,
                                    view: view,
                                    container: container)
    }

    // MARK: life Circle
    init(items: [PopupMenuActionItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.alpha = 0

        container.layer.ud.setBorderColor(UDShadowColorTheme.s5DownColor)
        container.layer.ud.setShadowColor(UDShadowColorTheme.s5DownColor)
        container.layer.shadowOpacity = 0.2
        container.layer.shadowRadius = 12
        container.layer.shadowOffset = CGSize(width: 0, height: 6)

        setupBlurEffectView()
        // 容器
        innerContainer.layer.cornerRadius = 6
        innerContainer.layer.masksToBounds = true
        container.addSubview(innerContainer)

        self.view.addSubview(container)
        makeConstraint(screenWidth: self.view.bounds.size.width)

        // 点击view
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundHandler))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)

        self.setupActionsViews()
    }

    private func makeConstraint(screenWidth: CGFloat) {
        innerContainer.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }

        container.snp.makeConstraints({ make in
            topConstraint = make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50).constraint
            make.left.equalTo(self.view.snp.right).priority(.medium)
            rightConstraint = make.right.equalToSuperview().offset(-12).priority(.high).constraint
            heightConstraint = make.height.greaterThanOrEqualTo(self.items.count * itemHeight).constraint
            widthConstraint = make.width.greaterThanOrEqualTo(137).constraint
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.show()
    }

    func setupActionsViews() {
        var totalHeight = 0
        self.items.enumerated().forEach { (index, actionItem) in
            let floatView = PopupMenuItemView(frame: .zero, hideIconImage: false)
            self.innerContainer.addSubview(floatView)
            floatView.setContent(icon: actionItem.icon, title: actionItem.title, accessibilityIdentifier: MailAccessibilityIdentifierKey.PopupCellKey + "\(index)")
            floatView.snp.makeConstraints({ (make) in
                make.left.right.equalToSuperview()
                if !Display.pad {
                    make.width.lessThanOrEqualTo(300)
                    make.top.equalToSuperview().offset(totalHeight)
                    var height = itemHeight
                    if let testHeight = floatView.label.text?.getTextHeight(font: UIFont.systemFont(ofSize: 16), width: 300) {
                        height = testHeight > 20.0 ? itemHeight + Int(ceil(testHeight/20)) * 10 : itemHeight
                    }
                    totalHeight = totalHeight + height
                    make.height.equalTo(height)
                    container.snp.updateConstraints({ make in
                        heightConstraint = make.height.greaterThanOrEqualTo(totalHeight).constraint
                    })
                } else {
                    make.width.lessThanOrEqualTo(375)
                    make.height.lessThanOrEqualTo(itemHeight)
                    make.top.equalToSuperview().offset(itemHeight * index)
                }
            })
            floatView.selectedBlock = { [weak self] in
                self?.didClickActionItem(actionItem)
            }
            if let iconColor = actionItem.iconColor {
                floatView.iconColor = iconColor
            }
            floatView.isEnabled = actionItem.isEnabled
            floatView.placeHolderTitle = actionItem.placeHolderTitle
        }
    }

    // MARK: action
    fileprivate func hide() {
        CATransaction.begin()
        if let timing = animator.hideTimingFunctionn() {
            CATransaction.setAnimationTimingFunction(timing)
        } else if let curve = animator.hideAnimationCurve() {
            UIView.setAnimationCurve(curve)
        }
        animator.willHide(info: animateInfo)
        UIView.animate(withDuration: timeIntvl.normal, delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
            self.animator.hiding(info: self.animateInfo)
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.dismiss(animated: false)
        })
        CATransaction.commit()
    }

    private func show() {
        CATransaction.begin()
        if let timing = animator.showTimingFunction() {
            CATransaction.setAnimationTimingFunction(timing)
        } else if let curve = animator.showAnimationCurve() {
            UIView.setAnimationCurve(curve)
        }
        animator.willShow(info: animateInfo)
        let animateDuration: Double = 0.45
        UIView.animate(withDuration: animateDuration, delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
            self.animator.showing(info: self.animateInfo)
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.animator.didShow(info: self.animateInfo)
        })
        CATransaction.commit()
    }

    private func setupBlurEffectView() {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloatPush
        blurView.blurRadius = 40
        innerContainer.addSubview(blurView)
        innerContainer.sendSubviewToBack(blurView)
        blurView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }

    @objc
    private func tapBackgroundHandler() {
        self.hide()
    }

    private func didClickActionItem(_ actionItem: PopupMenuActionItem) {
        self.dismiss(animated: false) {
            actionItem.actionCallBack(self, actionItem)
        }
    }

    // MARK: config
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension PopupMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.container) ?? false {
            return false
        }
        return true
    }
}

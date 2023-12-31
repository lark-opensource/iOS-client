//
//  PopupMenuViewController.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/17.
//

import Foundation
import UIKit
import SnapKit

public typealias PopupMenuActionCallBack = (UIViewController, PopupMenuActionItem) -> Void

public final class PopupMenuActionItem {
    let title: String
    let icon: UIImage
    var actionCallBack: PopupMenuActionCallBack
    var tag: AnyHashable? // 如果需要自己做一些特殊标识
    var isEnabled: Bool = true

    public init(title: String, icon: UIImage, callback: @escaping PopupMenuActionCallBack) {
        self.title = title
        self.icon = icon
        self.actionCallBack = callback
    }
}

public final class PopupMenuViewController: UIViewController {
    private var items: [PopupMenuActionItem] = []
    private let container: UIView = UIView()
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
    public init(items: [PopupMenuActionItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        self.view.alpha = 0

        // 容器
        container.layer.cornerRadius = 6
        container.layer.masksToBounds = true
        container.backgroundColor = UIColor.ud.N00
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
        container.snp.makeConstraints({ make in
            if #available(iOS 11.0, *) {
                topConstraint = make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50).constraint
            } else {
                topConstraint = make.top.equalTo(topLayoutGuide.snp.bottom).offset(50).constraint
            }

            make.left.equalTo(self.view.snp.right).priority(.medium)
            rightConstraint = make.right.equalToSuperview().offset(-12).priority(.high).constraint
            heightConstraint = make.height.equalTo(self.items.count * itemHeight).constraint
            widthConstraint = make.width.greaterThanOrEqualTo(137).constraint
        })
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.show()
    }

    func setupActionsViews() {
        self.items.enumerated().forEach { (index, actionItem) in
            let floatView = PopupMenuItemView(frame: .zero)
            self.container.addSubview(floatView)
            floatView.setContent(icon: actionItem.icon, title: actionItem.title, accessibilityIdentifier: "PopupCellKey\(index)")
            floatView.snp.makeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(itemHeight)
                make.top.equalToSuperview().offset(itemHeight * index)
            })
            floatView.selectedBlock = { [weak self] in
                self?.didClickActionItem(actionItem)
            }
            if index != items.count - 1 {
                floatView.addItemBorder()
            }
            floatView.isEnabled = actionItem.isEnabled
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
        UIView.animate(withDuration: 0.5, delay: 0.0,
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
        self.view.alpha = 0
        container.alpha = 0
        animator.willShow(info: animateInfo)
        UIView.animate(withDuration: 0.45, delay: 0.0,
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
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension PopupMenuViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.container) ?? false {
            return false
        }
        return true
    }
}

//
//  FeedFloatMenuMaskViewController.swift
//  LarkFeed
//
//  Created by Meng on 2019/8/22.
//

import UIKit
import FigmaKit
import Foundation
import SnapKit
import UniverseDesignShadow
import LarkOpenFeed

extension FeedFloatMenuMaskViewController {
    enum Layout {
        static let actionTop: CGFloat = 60.0
        static let actionTrailing: CGFloat = 16.0
    }
}

final class FeedFloatMenuMaskViewController: UIViewController, FeedPresentAnimationViewController {

    let menuView: FeedFloatMenuView
    let shadowView: UIView

    var dismissAction: (() -> Void)?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var actionLeading: Constraint?

    init(menuView: FeedFloatMenuView) {
        self.menuView = menuView
        self.shadowView = UIView()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0)

        shadowView.layer.ud.setBorderColor(UDShadowColorTheme.s5DownColor)
        shadowView.layer.ud.setShadowColor(UDShadowColorTheme.s5DownColor)
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 12
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.addSubview(shadowView)
        shadowView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Layout.actionTop)
            actionLeading = make.leading.equalTo(view.snp.trailing).constraint
            make.leading.greaterThanOrEqualTo(view.snp.leading).offset(Layout.actionTrailing)
            make.trailing.equalToSuperview().offset(-Layout.actionTrailing).priority(.high)
        }

        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
        blurView.blurRadius = 40
        blurView.fillOpacity = 1.0
        shadowView.addSubview(blurView)
        blurView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        shadowView.addSubview(menuView)
        menuView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        blurView.layer.cornerRadius = 8
        blurView.layer.masksToBounds = true
        menuView.layer.cornerRadius = 8
        menuView.layer.masksToBounds = true

        actionLeading?.activate()

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundHandler))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func showAnimation(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.45, delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
            self.actionLeading?.deactivate()
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion()
        })
    }

    func hideAnimation(animated: Bool, completion: @escaping () -> Void) {
        if animated {
            UIView.animate(withDuration: 0.45, delay: 0.0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.0,
                           options: .curveEaseInOut,
                           animations: {
                self.actionLeading?.activate()
                self.view.layoutIfNeeded()
            }, completion: { _ in
                completion()
            })
        } else {
            view.alpha = 1.0
            self.actionLeading?.activate()
            self.view.layoutIfNeeded()
            completion()
        }
    }

    @objc
    private func tapBackgroundHandler() {
        dismissAction?()
    }
}

extension FeedFloatMenuMaskViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view?.isDescendant(of: menuView) ?? false)
    }
}

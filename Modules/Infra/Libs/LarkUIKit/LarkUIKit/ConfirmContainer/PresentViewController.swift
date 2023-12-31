//
//  PresentViewController.swift
//  Lark
//
//  Created by lichen on 2017/4/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public typealias CustomAnimateCallback = (
    _ superVC: UIViewController,
    _ subVC: UIViewController,
    _ callback: @escaping () -> Void
) -> Void

open class PresentViewController: UIViewController {
    public var clickDismissEnable = true

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.mask?.backgroundColor = UIColor(white: 0, alpha: 0.3)
        self.mask?.isUserInteractionEnabled = clickDismissEnable
        self.appear()
    }

    public lazy var mask: UIButton? = { [weak self] in
        var btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(clickCancelMask), for: .touchUpInside)
        self?.view.insertSubview(btn, at: 0)
        btn.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return btn
    }()

    private var animate: PresentAnimateType = .bottom
    private var presentedVC: UIViewController?

    public convenience init(presentedVC: UIViewController, animate: PresentAnimateType = .bottom) {
        self.init()
        self.presentedVC = presentedVC
        self.animate = animate
        self.addChild(presentedVC)
    }

    public func appear() {
        if let presentedVC = self.presentedVC {
            animate.appear(superVC: self, subVC: presentedVC)
        }
    }

    public func update(animate: PresentAnimateType, animation: Bool) {
        self.animate = animate
        guard let presentedVC = self.presentedVC, presentedVC.view.superview == self.view else {
            return
        }
        self.animate.update(superVC: self, subVC: presentedVC, animation: animation)
    }

    @objc
    func clickCancelMask() {
        self.disappear()
    }

    @objc
    public func disappear(_ completion: (() -> Void)? = nil) {
        if let presentedVC = self.presentedVC {
            animate.disappear(superVC: self, subVC: presentedVC, completion: {
                self.removeFromParent()
                self.view.removeFromSuperview()
                completion?()
            })
        } else {
            self.removeFromParent()
            self.view.removeFromSuperview()
            completion?()
        }
    }

    public func show(in controller: UIViewController?) {
        guard let controller = controller else {
            return
        }
        controller.addChild(self)
        controller.view.addSubview(self.view)
        self.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

public enum PresentAnimateType {
    case bottom
    case top
    case center(CGPoint)
    case left
    case right
    case custom(appearCallBack: CustomAnimateCallback, disappearCallBack: CustomAnimateCallback)

    public func update(superVC: UIViewController, subVC: UIViewController, animation: Bool) {
        switch self {
        case .bottom:
            subVC.view.snp.remakeConstraints({ (make) in
                make.left.right.bottom.equalToSuperview()
            })
        case .top:
            subVC.view.snp.remakeConstraints({ (make) in
                make.left.right.top.equalToSuperview()
            })
        case .center(let offset):
            subVC.view.snp.remakeConstraints({ (make) in
                make.centerX.equalToSuperview().offset(offset.x)
                make.centerY.equalToSuperview().offset(offset.y)
            })
        case .left:
            subVC.view.snp.remakeConstraints({ (make) in
                make.top.bottom.left.equalToSuperview()
            })
        case .right:
            subVC.view.snp.remakeConstraints({ (make) in
                make.top.bottom.right.equalToSuperview()
            })
        case .custom(let appearCallBack, _):
            appearCallBack(superVC, subVC, {})
        }

        if animation {
            UIView.animate(withDuration: 0.25, animations: {
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func appear(superVC: UIViewController, subVC: UIViewController) {
        superVC.view.addSubview(subVC.view)
        switch self {
        case .bottom:
            appearFromBottom(superVC, subVC)
        case .top:
            appearFromTop(superVC, subVC)
        case .center(let offset):
            appearFromCenter(superVC, subVC, offset)
        case .left:
            appearFromLeft(superVC, subVC)
        case .right:
            appearFromRight(superVC, subVC)
        case .custom(let appearCallBack, _):
            appearCallBack(superVC, subVC, {})
        }
    }

    public func disappear(superVC: UIViewController, subVC: UIViewController, completion: @escaping () -> Void) {
        switch self {
        case .bottom:
            disappearFromBottom(superVC, subVC, completion)
        case .top:
            disappearFromTop(superVC, subVC, completion)
        case .center:
            disappearFromCenter(superVC, subVC, completion)
        case .left:
            disappearFromLeft(superVC, subVC, completion)
        case .right:
            disappearFromRight(superVC, subVC, completion)
        case .custom( _, let disappearCompletion):
            disappearCompletion(superVC, subVC, {
                completion()
            })
        }
    }

    func appearFromBottom(_ superVC: UIViewController, _ subVC: UIViewController) {
        superVC.view.alpha = 0
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(superVC.view.snp.bottom)
        })
        superVC.view.layoutIfNeeded()
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.bottom.equalToSuperview()
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 1
            superVC.view.layoutIfNeeded()
        })
    }

    func appearFromTop(_ superVC: UIViewController, _ subVC: UIViewController) {
        superVC.view.alpha = 0
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(superVC.view.snp.top)
        })
        superVC.view.layoutIfNeeded()
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.top.equalToSuperview()
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 1
            superVC.view.layoutIfNeeded()
        })
    }

    func appearFromCenter(_ superVC: UIViewController, _ subVC: UIViewController, _ offset: CGPoint) {
        superVC.view.alpha = 0
        subVC.view.snp.remakeConstraints({ (make) in
            make.centerX.equalToSuperview().offset(offset.x)
            make.centerY.equalToSuperview().offset(offset.y)
        })
        subVC.view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        superVC.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 1
            subVC.view.transform = CGAffineTransform.identity
        })
    }

    func appearFromLeft(_ superVC: UIViewController, _ subVC: UIViewController) {
        superVC.view.alpha = 0
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.right.equalTo(superVC.view.snp.left)
        })
        superVC.view.layoutIfNeeded()
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.left.equalToSuperview()
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 1
            superVC.view.layoutIfNeeded()
        })
    }

    func appearFromRight(_ superVC: UIViewController, _ subVC: UIViewController) {
        superVC.view.alpha = 0
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(superVC.view.snp.right)
        })
        superVC.view.layoutIfNeeded()
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.right.equalToSuperview()
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 1
            superVC.view.layoutIfNeeded()
        })
    }

    func disappearFromBottom(
        _ superVC: UIViewController,
        _ subVC: UIViewController,
        _ completion: @escaping () -> Void
    ) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(superVC.view.snp.bottom)
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 0
            superVC.view.layoutIfNeeded()
        }, completion: { (_) in
            completion()
        })
    }

    func disappearFromTop(
        _ superVC: UIViewController,
        _ subVC: UIViewController,
        _ completion: @escaping () -> Void
    ) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(superVC.view.snp.top)
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 0
            superVC.view.layoutIfNeeded()
        }, completion: { (_) in
            completion()
        })
    }

    func disappearFromCenter(
        _ superVC: UIViewController,
        _ subVC: UIViewController,
        _ completion: @escaping () -> Void
    ) {
        superVC.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 0
            subVC.view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        }, completion: { (_) in
            completion()
        })
    }

    func disappearFromLeft(
        _ superVC: UIViewController,
        _ subVC: UIViewController,
        _ completion: @escaping () -> Void
    ) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.right.equalTo(superVC.view.snp.left)
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 0
            superVC.view.layoutIfNeeded()
        }, completion: { (_) in
            completion()
        })
    }

    func disappearFromRight(
        _ superVC: UIViewController,
        _ subVC: UIViewController,
        _ completion: @escaping () -> Void
    ) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(superVC.view.snp.right)
        })
        UIView.animate(withDuration: 0.25, animations: {
            superVC.view.alpha = 0
            superVC.view.layoutIfNeeded()
        }, completion: { (_) in
            completion()
        })
    }
}

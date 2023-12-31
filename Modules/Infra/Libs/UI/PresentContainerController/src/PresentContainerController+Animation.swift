//
//  PresentContainerController+Animation.swift
//  Pods
//
//  Created by 李晨 on 2019/3/15.
//

import Foundation
import UIKit
import SnapKit

public protocol PresentContainerAnimation {
    // 用户从其他 animation 更新到当前 animation
    func update(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool)
    // present 出现动画
    func appear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?)
    // present present 消失动画
    func disappear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?)
}

public struct PresentFromBottom: PresentContainerController.Animation {

    public var duration: TimeInterval
    public init(duration: TimeInterval = 0.25) {
        self.duration = duration
    }

    public func update(superVC: UIViewController, subVC: UIViewController, animation: Bool) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.bottom.equalToSuperview()
        })
        if animation {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func appear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        if !animation {
            superVC.view.alpha = 1
            subVC.view.snp.remakeConstraints({ (make) in
                make.left.right.bottom.equalToSuperview()
            })
        } else {
            superVC.view.alpha = 0
            subVC.view.snp.remakeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(superVC.view.snp.bottom)
            })
            superVC.view.layoutIfNeeded()
            subVC.view.snp.remakeConstraints({ (make) in
                make.left.right.bottom.equalToSuperview()
            })
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 1
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func disappear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool, completion: (() -> Void)?) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(superVC.view.snp.bottom)
        })
        if !animation {
            completion?()
        } else {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 0
                superVC.view.layoutIfNeeded()
            }, completion: { (_) in
                completion?()
            })
        }
    }
}

public struct PresentFromTop: PresentContainerController.Animation {

    public var duration: TimeInterval
    public init(duration: TimeInterval = 0.25) {
        self.duration = duration
    }

    public func update(superVC: UIViewController, subVC: UIViewController, animation: Bool) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.top.equalToSuperview()
        })
        if animation {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func appear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        if !animation {
            superVC.view.alpha = 1
            subVC.view.snp.remakeConstraints({ (make) in
                make.left.right.top.equalToSuperview()
            })
        } else {
            superVC.view.alpha = 0
            subVC.view.snp.remakeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(superVC.view.snp.top)
            })
            superVC.view.layoutIfNeeded()
                subVC.view.snp.remakeConstraints({ (make) in
                    make.left.right.top.equalToSuperview()
                })
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 1
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func disappear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(superVC.view.snp.top)
        })
        if !animation {
            completion?()
        } else {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 0
                superVC.view.layoutIfNeeded()
            }, completion: { (_) in
                completion?()
            })
        }
    }
}

public struct PresentFromCenter: PresentContainerController.Animation {

    public var duration: TimeInterval
    public var offset: CGPoint
    public init(offset: CGPoint = .zero, duration: TimeInterval = 0.25) {
        self.duration = duration
        self.offset = offset
    }

    public func update(superVC: UIViewController, subVC: UIViewController, animation: Bool) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.centerX.equalToSuperview().offset(offset.x)
            make.centerY.equalToSuperview().offset(offset.y)
        })
        if animation {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func appear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        if !animation {
            superVC.view.alpha = 1
            subVC.view.transform = CGAffineTransform.identity
            subVC.view.snp.remakeConstraints({ (make) in
                make.centerX.equalToSuperview().offset(offset.x)
                make.centerY.equalToSuperview().offset(offset.y)
            })
        } else {
            superVC.view.alpha = 0
            subVC.view.snp.remakeConstraints({ (make) in
                make.centerX.equalToSuperview().offset(offset.x)
                make.centerY.equalToSuperview().offset(offset.y)
            })
            subVC.view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            superVC.view.layoutIfNeeded()
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 1
                subVC.view.transform = CGAffineTransform.identity
            })
        }
    }

    public func disappear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        if !animation {
            completion?()
        } else {
            superVC.view.layoutIfNeeded()
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 0
                subVC.view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }, completion: { (_) in
                completion?()
            })
        }
    }
}

public struct PresentFromLeft: PresentContainerController.Animation {

    public var duration: TimeInterval
    public init(duration: TimeInterval = 0.25) {
        self.duration = duration
    }

    public func update(superVC: UIViewController, subVC: UIViewController, animation: Bool) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.left.equalToSuperview()
        })
        if animation {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func appear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        if !animation {
            superVC.view.alpha = 1
            subVC.view.snp.remakeConstraints({ (make) in
                make.top.bottom.left.equalToSuperview()
            })
        } else {
            superVC.view.alpha = 0
            subVC.view.snp.remakeConstraints({ (make) in
                make.top.bottom.equalToSuperview()
                make.right.equalTo(superVC.view.snp.left)
            })
            superVC.view.layoutIfNeeded()
            subVC.view.snp.remakeConstraints({ (make) in
                make.top.bottom.left.equalToSuperview()
            })
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 1
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func disappear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.right.equalTo(superVC.view.snp.left)
        })
        if !animation {
            completion?()
        } else {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 0
                superVC.view.layoutIfNeeded()
            }, completion: { (_) in
                completion?()
            })
        }
    }
}

public struct PresentFromRight: PresentContainerController.Animation {

    public var duration: TimeInterval
    public init(duration: TimeInterval = 0.25) {
        self.duration = duration
    }

    public func update(superVC: UIViewController, subVC: UIViewController, animation: Bool) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.right.equalToSuperview()
        })
        if animation {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func appear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        superVC.view.alpha = 0
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(superVC.view.snp.right)
        })
        superVC.view.layoutIfNeeded()
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.right.equalToSuperview()
        })
        UIView.animate(withDuration: self.duration, animations: {
            superVC.view.alpha = 1
            superVC.view.layoutIfNeeded()
        })
    }

    public func disappear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(superVC.view.snp.right)
        })
        UIView.animate(withDuration: self.duration, animations: {
            superVC.view.alpha = 0
            superVC.view.layoutIfNeeded()
        }, completion: { (_) in
            completion?()
        })
    }
}

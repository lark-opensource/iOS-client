//
//  PresentContainerController.swift
//  AudioSessionScenario
//
//  Created by 李晨 on 2019/3/15.
//

import Foundation
import UIKit
import SnapKit

/// NOTE: subViewController 必须是有宽高约束的，如果没有相应约束 请使用 PresentWrapperController 包装一层

public final class PresentContainerController: UIViewController {

    public static func presentContainer(for vc: UIViewController) -> PresentContainerController? {
        var targetVC: UIViewController? = vc
        while targetVC != nil {
            if let presentContainerVC = targetVC?.parent as? PresentContainerController {
                return presentContainerVC
            }
            targetVC = targetVC?.parent
        }
        return nil
    }

    public typealias Animation = PresentContainerAnimation

    public var clickDismissEnable = true {
        didSet {
            if self.isViewLoaded {
                self.mask?.isUserInteractionEnabled = clickDismissEnable
            }
        }
    }

    public var maskViewColor: UIColor = UIColor(white: 0, alpha: 0.3) {
        didSet {
            if self.isViewLoaded {
                self.mask?.backgroundColor = self.maskViewColor
            }
        }
    }

    private var viewAppeared: Bool = false

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.mask?.backgroundColor = UIColor(white: 0, alpha: 0.3)
        self.mask?.isUserInteractionEnabled = clickDismissEnable
        self.view.addSubview(self.subViewController.view)
        self.appear(animated: true, completion: nil)
    }

    lazy public var mask: UIButton? = { [weak self] in
        var btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(clickCancelMask), for: .touchUpInside)
        self?.view.insertSubview(btn, at: 0)
        btn.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return btn
    }()

    private var animate: Animation
    private var subViewController: UIViewController

    public init(
        subViewController: UIViewController,
        animate: Animation = PresentFromBottom()) {
        self.subViewController = subViewController
        self.animate = animate
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
        self.addChild(subViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func appear(animated flag: Bool, completion: (() -> Void)? = nil) {
        if self.viewAppeared { return }
        self.viewAppeared = true
        animate.appear(superVC: self, subVC: subViewController, animation: flag, completion: completion)
    }

    public func update(animate: Animation, animation: Bool) {
        self.animate = animate
        self.animate.update(superVC: self, subVC: self.subViewController, animation: animation)
    }

    @objc
    func clickCancelMask() {
        self.dismiss(animated: true, completion: nil)
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.disappear(animated: flag) {
            self.removeFromWindow(completion)
        }
    }

    public func removeFromParentView(animated flag: Bool, _ completion: (() -> Void)? = nil) {
        self.disappear(animated: flag) {
            self.removeFromWindow(completion)
        }
    }

    private func removeFromWindow(_ completion: (() -> Void)? = nil) {
        if let presentingViewController = self.presentingViewController,
            presentingViewController.presentedViewController == self {
            super.dismiss(animated: false, completion: completion)
        } else {
            self.removeFromParent()
            self.view.removeFromSuperview()
            completion?()
        }
    }

    @objc
    func disappear(animated flag: Bool, _ completion: (() -> Void)? = nil) {
        animate.disappear(superVC: self, subVC: self.subViewController, animation: flag, completion: {
            completion?()
        })
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

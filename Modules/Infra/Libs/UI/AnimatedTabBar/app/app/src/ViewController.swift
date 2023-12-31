//
//  ViewController.swift
//  AnimatedTabBarDev
//
//  Created by 李晨 on 2020/1/9.
//

import Foundation
import UIKit
import AnimatedTabBar

class Navi: UINavigationController, UINavigationControllerDelegate {

    private var lastLayoutBounds: CGRect = .zero
    private var needLayoutWhenVCDidShow: Bool = false
    private var isPushing: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.view.backgroundColor = UIColor.green
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = self.view.bounds
        /// 在 Push 过程中发生了 bounds 的变化
        /// 标记 needLayoutWhenVCDidShow 为 true
        /// 在 push 结束之后重新触发 layout
        if self.lastLayoutBounds != .zero,
            bounds != self.lastLayoutBounds,
            self.isPushing {
            self.needLayoutWhenVCDidShow = true
        }
        self.lastLayoutBounds = bounds
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        isPushing = true
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        isPushing = false
        if needLayoutWhenVCDidShow {
            needLayoutWhenVCDidShow = false
            self.view.setNeedsLayout()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
}

class ViewController: UIViewController {
    let accessoryView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Root VC"
        self.view.backgroundColor = UIColor.red

        let textField: UITextField = UITextField()
        textField.frame = CGRect(x: 100, y: 100, width: 200, height: 44)
        textField.placeholder = "text field"
        self.view.addSubview(textField)
        self.accessoryView.backgroundColor = UIColor.red
        self.accessoryView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)

        let button: UIButton = UIButton()
        button.frame = CGRect(x: 100, y: 200, width: 200, height: 44)
        button.setTitle("Push", for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc
    func click() {
        self.navigationController?.pushViewController(
            SubViewController(),
            animated: true
        )
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
}

class SubViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red

        self.title = "Sub VC"
        let textField: UITextField = UITextField()
        textField.frame = CGRect(x: 100, y: 100, width: 200, height: 44)
        textField.placeholder = "text field"
        self.view.addSubview(textField)

        let button: UIButton = UIButton()
        button.frame = CGRect(x: 100, y: 200, width: 200, height: 44)
        button.setTitle("Present", for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc
    func click() {
        let vc = PresentController()
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: true, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        self.view.endEditing(true)
        super.present(viewControllerToPresent, animated: flag, completion: nil)
    }
}

class PresentController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.title = "Present VC"
        let textField: UITextField = UITextField()
        textField.frame = CGRect(x: 100, y: 150, width: 200, height: 44)
        textField.placeholder = "text field"
        self.view.addSubview(textField)

        let button: UIButton = UIButton()
        button.frame = CGRect(x: 100, y: 350, width: 200, height: 44)
        button.setTitle("Dismiss", for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc
    func click() {
        self.dismiss(animated: true, completion: nil)
    }
}

//
//  ViewController.swift
//  LarkKeyCommandKitDev
//
//  Created by 李晨 on 2020/2/5.
//

import Foundation
import UIKit
import LarkKeyCommandKit
import WebKit

func rootViewController() -> UIViewController {

    let nav1 = NAV1()
    nav1.setViewControllers([VC1(), VC2(), VC3()], animated: false)

    let nav2 = NAV2()
    nav2.setViewControllers([VC1(), VC2(), VC3()], animated: false)

    let split = SplitVC1()
    split.viewControllers = navs()
    split.preferredDisplayMode = .allVisible

    let split2 = SplitVC2()
    split2.viewControllers = navs()
    split2.preferredDisplayMode = .allVisible

    let tab = TabVC()
    tab.setViewControllers([split, split2], animated: false)

    return tab
}

func navs() -> [UIViewController] {
    let nav1 = NAV1()
    nav1.setViewControllers([VC1(), VC2(), VC3()], animated: false)

    let nav2 = NAV2()
    nav2.setViewControllers([VC1(), VC2(), VC3()], animated: false)

    return [nav1, nav2]
}

class SplitVC1: UISplitViewController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "a",
                modifierFlags: .command,
                discoverabilityTitle: "splitvc1"
            ).binding {
                print("click splitvc 1")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "split1"
    }
}

class SplitVC2: UISplitViewController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "b",
                modifierFlags: .command,
                discoverabilityTitle: "splitvc2"
            ).binding {
                print("click splitvc 2")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "split2"
    }
}

class TabVC: UITabBarController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "c",
                modifierFlags: .command,
                discoverabilityTitle: "TAB"
            ).binding {
                print("click TAB")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.title = "tab"
    }
}

class NAV1: UINavigationController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "d",
                modifierFlags: .command,
                discoverabilityTitle: "NAV1"
            ).binding {
                print("click NAV 1")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.tabBarItem.title = "nav1"
        self.tabBarItem.title = "nav1"
    }
    override var canBecomeFirstResponder: Bool {
      return true
    }
}

class NAV2: UINavigationController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "e",
                modifierFlags: .command,
                discoverabilityTitle: "NAV2"
            ).binding {
                print("click NAV 2")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.title = "nav2"
        self.tabBarItem.title = "nav2"
    }
    override var canBecomeFirstResponder: Bool {
      return true
    }
}

class VC1: UIViewController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "f",
                modifierFlags: .command,
                discoverabilityTitle: "VC1"
            ).binding {
                print("click VC1")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "vc1"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "present",
            style: .done,
            target: self,
            action: #selector(presentVC)
        )
    }

    @objc
    func presentVC() {
        let nav = UINavigationController(rootViewController: PVC1())
        nav.modalPresentationStyle = .fullScreen

        self.present(nav, animated: true, completion: nil)
    }
}

class VC2: UIViewController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "g",
                modifierFlags: .command,
                discoverabilityTitle: "VC2"
            ).binding {
                print("click VC2")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "vc2"
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem(
            title: "present",
            style: .done,
            target: self,
            action: #selector(presentVC)
        )
    }

    @objc
    func presentVC() {
        let nav = UINavigationController(rootViewController: PVC2())
        nav.modalPresentationStyle = .currentContext
        self.present(nav, animated: true, completion: nil)
    }
}

class VC3: UIViewController {

    var view1 = View1()

    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "h",
                modifierFlags: .command,
                discoverabilityTitle: "VC3"
            ).binding {
                print("click VC3")
            }.wraper
        ]
    }

    override func subProviders() -> [KeyCommandProvider] {
        return [self.view1]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "vc3"
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem(
                title: "present",
                style: .done,
                target: self,
                action: #selector(presentVC)
            )
    }

    @objc
    func presentVC() {
        let nav = UINavigationController(rootViewController: PVC3())
        nav.modalPresentationStyle = .overFullScreen
        self.present(nav, animated: true, completion: nil)
    }
}

class View1: UIView {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputTab,
                modifierFlags: .shift,
                discoverabilityTitle: "View1 inputTab"
            ).binding {
                print("click View1 inputTab")
            }.wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputBackspace,
                modifierFlags: .shift,
                discoverabilityTitle: "View1 inputBackspace"
            ).binding {
                print("click View1 inputBackspace")
            }.wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .shift,
                discoverabilityTitle: "View1 inputReturn"
            ).binding {
                print("click View1 inputReturn")
            }.wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDelete,
                modifierFlags: .shift,
                discoverabilityTitle: "View1 inputDelete"
            ).binding {
                print("click View1 inputDelete")
            }.wraper
        ]
    }
}

class PVC1: UIViewController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "f",
                modifierFlags: .shift,
                discoverabilityTitle: "PVC1"
            ).binding {
                print("click PVC1")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "Pvc1"
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem(
                title: "DISMIS",
                style: .done,
                target: self,
                action: #selector(dismissVC)
        )
        self.modalPresentationStyle = .fullScreen

    }

    @objc
    func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
}

class PVC2: UIViewController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "g",
                modifierFlags: .shift,
                discoverabilityTitle: "PVC2"
            ).binding {
                print("click PVC2")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "Pvc2"
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem(
                title: "DISMIS",
                style: .done,
                target: self,
                action: #selector(dismissVC)
        )
        self.modalPresentationStyle = .fullScreen

    }

    @objc
    func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
}

class PVC3: UIViewController {
    override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "h",
                modifierFlags: .shift,
                discoverabilityTitle: "PVC3"
            ).binding {
                print("click PVC3")
            }.wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: [],
                discoverabilityTitle: "上"
            ).binding {
                print("click inputUpArrow")
            }.wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: [],
                discoverabilityTitle: "下"
            ).binding {
                print("click inputDownArrow")
            }.wraper
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.title = "Pvc3"
        self.modalPresentationStyle = .overCurrentContext
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem(
                title: "DISMIS",
                style: .done,
                target: self,
                action: #selector(dismissVC)
        )

        let textField = UITextField()
        textField.backgroundColor = UIColor.red
        textField.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        self.view.addSubview(textField)

        let webview = WKWebView()
        _ = webview.load(URLRequest(url: URL(string: "https://www.toutiao.com/")!))
        webview.backgroundColor = UIColor.blue
        webview.frame = CGRect(x: 0, y: 220, width: 800, height: 800)
        self.view.addSubview(webview)
    }

    @objc
    func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }

    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(
            input: "x",
            modifierFlags: .shift,
            action: #selector(dismissVC),
            discoverabilityTitle: "PKV3")]
    }
    override var canBecomeFirstResponder: Bool {
      return true
    }
}

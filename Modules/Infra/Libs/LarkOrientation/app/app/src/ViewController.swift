//
//  ViewController.swift
//  LarkOrientationDev
//
//  Created by 李晨 on 2020/2/26.
//

import UIKit
import Foundation
import LarkOrientation


class Navi: UINavigationController {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.topViewController?.supportedInterfaceOrientations ?? .all
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VC1"
        self.view.backgroundColor = UIColor.white
        let btn = UIButton(type: .contactAdd)
        btn.frame = CGRect(x: 100, y: 100, width: 100, height: 40)
        self.view.addSubview(btn)
        btn.backgroundColor = UIColor.blue
        btn.addTarget(self, action: #selector(go), for: .touchUpInside)
    }

    @objc
    func go() {
        self.navigationController?.pushViewController(ViewController2(), animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

class ViewController2: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VC2"
        self.view.backgroundColor = UIColor.white
        let btn = UIButton(type: .contactAdd)
        btn.frame = CGRect(x: 100, y: 100, width: 100, height: 40)
        self.view.addSubview(btn)
        btn.backgroundColor = UIColor.blue
        btn.addTarget(self, action: #selector(go), for: .touchUpInside)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.supportOrientations = .landscape
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func go() {
        self.navigationController?.pushViewController(ViewController3(), animated: true)
    }
}

class ViewController3: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VC3"
        self.view.backgroundColor = UIColor.white

        let btn = UIButton(type: .contactAdd)
        btn.frame = CGRect(x: 100, y: 100, width: 100, height: 40)
        self.view.addSubview(btn)
        btn.backgroundColor = UIColor.blue
        btn.addTarget(self, action: #selector(go), for: .touchUpInside)
    }

    @objc
    func go() {
        self.navigationController?.pushViewController(ViewController4(), animated: true)
    }
}

class ViewController4: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VC4"
        self.view.backgroundColor = UIColor.white

        let btn = UIButton(type: .contactAdd)
        btn.frame = CGRect(x: 100, y: 100, width: 100, height: 40)
        self.view.addSubview(btn)
        btn.backgroundColor = UIColor.blue
        btn.addTarget(self, action: #selector(go), for: .touchUpInside)
    }

    @objc
    func go() {
        self.navigationController?.pushViewController(ViewController3(), animated: true)
    }
}

extension UIDeviceOrientation {
    var toInterfaceOrientation: UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .faceUp:
            return .portrait
        case .faceDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}
extension UIInterfaceOrientationMask {
    var anyOrientation: UIDeviceOrientation {
        if self.contains(.portrait) {
            return UIDeviceOrientation.portrait
        }
        else if self.contains(.landscapeLeft) {
            return UIDeviceOrientation.landscapeLeft
        }
        else if self.contains(.landscapeRight) {
            return UIDeviceOrientation.landscapeRight
        }
        return UIDeviceOrientation.portrait
    }
}

//
//  ViewController.swift
//  LarkUIExtensionDev
//
//  Created by 李晨 on 2020/3/11.
//

import Foundation
import UIKit
import LarkUIExtension

class ViewController: UIViewController {

    let swift: SwiftObject = SwiftObject()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.ue.bind(keyPath: \.backgroundColor, value: self.currentBackgroundColor())

        let label = UILabel()
        self.view.addSubview(label)
        label.textAlignment = .center
        label.frame = CGRect(x: 100, y: 100, width: 100, height: 100)

        label.ue.bind(keyPath: \.backgroundColor, value: self.labelBackgroundColor())
        label.ue.bind(keyPath: \.layer.cornerRadius, value: self.labelCornerRadius())

        label.ue.bind(updateQueue: DispatchQueue.main) { (label) in
                if ThemeManager.current == .light {
                    label.text = "light"
                    label.textColor = UIColor.black
                } else {
                    label.text = "dark"
                    label.textColor = UIColor.white
                }
            }
        label.layer.masksToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true

        swift.ue.bind(keyPath: \.value, value: self.currentString())
            .bind { (object) in
                print("called swift bind block")
        }
    }

    @objc
    func click() {
        if ThemeManager.shared.strategy.value == .dark {
            ThemeManager.shared.update(strategy: .light)
        } else {
            ThemeManager.shared.update(strategy: .dark)
        }
    }

    func currentBackgroundColor() -> UIColor {
        if ThemeManager.current == .light {
            return UIColor.red
        } else {
            return UIColor.blue
        }
    }

    func labelBackgroundColor() -> UIColor {
        if ThemeManager.current == .light {
            return UIColor.green
        } else {
            return UIColor.orange
        }
    }

    func labelCornerRadius() -> CGFloat {
        if ThemeManager.current == .light {
            return 20
        } else {
            return 50
        }
    }

    func currentString() -> String {
        if ThemeManager.current == .light {
            return "light"
        } else {
            return "dark"
        }
    }

}

class SwiftObject: LarkUIExtensionCompatible, BindEnableObject {
    private var _value: String = ""
    var value: String {
        set {
            print("------ set swift object value \(newValue)")
            _value = newValue
        }
        get {
            print("------ get swift object value \(_value)")
            return _value
        }
    }
}

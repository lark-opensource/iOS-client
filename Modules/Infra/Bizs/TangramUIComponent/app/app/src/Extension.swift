//
//  Extension.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/4/22.
//

import Foundation
import UIKit

extension UIViewController {
    func createButton(title: String, tapped: @escaping ButtonTapped) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.tapped = tapped
        button.backgroundColor = UIColor.purple.withAlphaComponent(0.7)
        return button
    }

    @objc
    private func buttonTapped(sender: UIButton) {
        sender.tapped?()
    }
}

var tappedKey = "tappedKey"
typealias ButtonTapped = () -> Void
extension UIButton {
    var tapped: ButtonTapped? {
        get {
            return objc_getAssociatedObject(self, &tappedKey) as? ButtonTapped
        }
        set {
            objc_setAssociatedObject(self, &tappedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension String {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length - 1).map { _ in letters.randomElement()! })
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}

extension UIImage {
    static func random(size: CGSize = .init(width: 64, height: 64), color: UIColor = UIColor.random()) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

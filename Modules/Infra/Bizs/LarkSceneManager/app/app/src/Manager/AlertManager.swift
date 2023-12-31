//
//  AlertManager.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/3.
//

import Foundation
import UIKit
import SnapKit

class AlertManager {
    static var shared: AlertManager = AlertManager()

    var dispose: NSObjectProtocol?

    let alertWindow: UIWindow = {
        let window = UIWindow()
        window.windowLevel = .alert
        window.rootViewController = UIViewController()

        let label = UILabel()
        label.text = "Alert Window"
        label.textColor = UIColor.white

        window.addSubview(label)
        label.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }

        return window
    }()

    var open: Bool = false {
        didSet {
            if open {
                alertWindow.isHidden = false
                if #available(iOS 13.0, *) {
                    if let scene = self.find() {
                        alertWindow.windowScene = scene
                    }
                }
                alertWindow.frame = CGRect(x: 0, y: 20, width: 200, height: 100)
            } else {
                alertWindow.isHidden = true
            }
        }
    }

    init() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))
        alertWindow.addGestureRecognizer(tap)
    }

    @objc
    func tap(gesture: UIGestureRecognizer) {
        self.open = false
    }

    func observeScene() {
        if #available(iOS 13.0, *) {
            dispose = NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification, object: nil,
                                                             queue: nil) { [weak self] (noti) in
                guard let self = self else { return }
                if self.open {
                    if let scene = self.find() {
                        self.alertWindow.windowScene = scene
                    }
                }
            }
        }
    }

    @available(iOS 13.0, *)
    func find() -> UIWindowScene? {
        if let windowScene = alertWindow.windowScene,
           windowScene.activationState == .foregroundActive ||
            windowScene.activationState == .foregroundInactive {
            return windowScene
        }

        return UIApplication.shared.connectedScenes.compactMap { (scene) -> UIWindowScene? in
            if let windowScene = scene as? UIWindowScene,
               windowScene.activationState == .foregroundActive ||
                windowScene.activationState == .foregroundInactive {
                return windowScene
               }
            return nil
        }.first
    }
}

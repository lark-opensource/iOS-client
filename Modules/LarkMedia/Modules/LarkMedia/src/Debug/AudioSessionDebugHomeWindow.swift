//
//  AudioSessionDebugHomeWindow.swift
//  AudioSessionScenario
//
//  Created by ford on 2020/6/8.
//

import Foundation

class AudioSessionDebugHomeWindow: UIWindow {
    static let shared = AudioSessionDebugHomeWindow(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))

    var nav: UINavigationController?

    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.windowLevel = .statusBar - 1
        self.backgroundColor = .clear
        self.isHidden = true
#if swift(>=5.1)
        if #available(iOS 13.0, *) {
            for windowScene in UIApplication.shared.connectedScenes {
                if windowScene.activationState == .foregroundActive {
                    self.windowScene = windowScene as? UIWindowScene
                    break
                }
            }
        }
#endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        let vc = AudioSessionDebugViewController()
        setRootVc(vc: vc)
        self.isHidden = false
    }

    func hide() {
        setRootVc(vc: nil)
        self.isHidden = true
    }

    private func setRootVc(vc: UIViewController?) {
        if let vc = vc {
            let nav = UINavigationController(rootViewController: vc)
            self.nav = nav
            self.rootViewController = nav
        } else {
            self.rootViewController = nil
            self.nav = nil
        }
    }
}

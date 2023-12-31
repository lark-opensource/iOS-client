//
//  SetupDebugTask.swift
//  LarkDebug
//
//  Created by KT on 2020/7/2.
//

import Foundation
import BootManager
import AppContainer
import LarkFoundation
import RxSwift
import EENavigator
import UIKit
#if canImport(LarkAssertConfig)
import LarkAssertConfig
#endif

public func appCanDebug() -> Bool {
    #if LARK_NO_DEBUG
    return false
    #endif
    #if DEBUG || ALPHA
    return true
    #else
    let suffix = Utils.appVersion.lf.matchingStrings(regex: "[a-zA-Z]+(\\d+)?").first?.first
    return suffix != nil
    #endif
}

final class SetupDebugTask: FlowBootTask, Identifiable { //Global
    static var identify = "SetupDebugTask"

    override var deamon: Bool { return true }

    private let disposeBag = DisposeBag()

    override func execute(_ context: BootContext) {
        UIStatusBarHookManager.hookTapEvent()
        #if !LARK_NO_DEBUG
        if appCanDebug() {
            self.subscribeShowDebugVC()
        }
        subscribeAssert()
        #endif
    }

    #if !LARK_NO_DEBUG
    private func subscribeShowDebugVC() {
        NotificationCenter.default.rx
            .notification(Notification.statusBarTapped.name)
            .subscribe(onNext: { (notification) in
                let kw = UIApplication.shared.windows.first { $0.isKeyWindow }
                guard let tapCount = notification.userInfo?[Notification.statusBarTappedCount] as? NSNumber,
                      tapCount.intValue == 5, var window = kw ?? Navigator.shared.mainSceneWindow else { //Global
                    return
                }

                if #available(iOS 13.0, *),
                   let tappedScene = notification.userInfo?[Notification.statusBarTappedInScene] as? UIWindowScene,
                   let delegate = tappedScene.delegate as? UIWindowSceneDelegate,
                   let tappedWindow = delegate.window?.map({ $0 }) {
                    window = tappedWindow
                }

                Navigator.shared.present( //Global
                    body: DebugBody(),
                    wrap: UINavigationController.self,
                    from: window,
                    prepare: { $0.modalPresentationStyle = .fullScreen }
                )
            })
            .disposed(by: disposeBag)
    }
    
    private func subscribeAssert() {
        NotificationCenter.default.addObserver(self, selector: #selector(showAssert(_:)), name: Notification.Name("CustomAssertNotification"), object: nil)
    }
    
    @objc
    private func showAssert(_ notification: Foundation.Notification) {
        #if canImport(LarkAssertConfig)
        let file = (notification.userInfo?["file"] as? StaticString) ?? ""
        let message = (notification.userInfo?["message"] as? String) ?? ""
        let line = (notification.userInfo?["line"] as? UInt) ?? 0
        LarkAssertConfig.assertIfNeeded(file: file, message: message, line: line)
        #endif
    }
    #endif
}

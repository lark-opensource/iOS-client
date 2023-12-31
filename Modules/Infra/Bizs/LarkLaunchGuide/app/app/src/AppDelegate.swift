//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkLaunchGuide
import LKLaunchGuide
import Swinject
import RxSwift
import LarkLocalizations
import LarkAppConfig

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let container = Container()
    let disposeBag = DisposeBag()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults(suiteName: "LarkLaunchGuide")?.removeObject(forKey: "LaunchGuideShowKey")

        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        demoStartWithConfig(language: .zh_CN, useLottie: true)
        return true
    }
}

extension AppDelegate {
    func demoStartWithConfig(language: Lang, useLottie: Bool) {
        LanguageManager.setCurrent(language: language, isSystem: false)
        assembly(lottie: useLottie)
        showGuide()
    }

    func assembly(lottie: Bool) {
        if lottie {
            LaunchGuideAssembly().assemble(container: container)
        } else {
            MockImageLaunchGuideAssembly().assemble(container: container)
        }
    }

    func showGuide() {
        let service1 = container.resolve(LaunchGuideService.self)!
        let service2 = container.resolve(LaunchGuideService.self)!

        service1.checkShowGuide(window: window, showGuestGuide: false)
            .subscribe(onNext: { (action) in
                print("checkShowGuide status \(action)")
            }).disposed(by: disposeBag)
        service2.tryScrollToItem(name: GuideItemName.vc)
    }
}

//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import RxSwift
import LarkTraitCollection
import LKLoadable

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LKLoadableManager.run(LoadableState(rawValue: 0))
        LKLoadableManager.run(LoadableState(rawValue: 1))
        LKLoadableManager.run(LoadableState(rawValue: 2))

        self.window = UIWindow()
        self.window?.rootViewController = ViewController()
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        RootTraitCollection.shared.useCustomSizeClass = true

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}

class ViewController: UIViewController {
    let dispose = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .subscribe(onNext: { (change) in
                print("--------- \(change.old.horizontalSizeClass.rawValue) \(change.new.horizontalSizeClass.rawValue)")
            }).disposed(by: self.dispose)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.present(ViewController(), animated: true, completion: nil)
        }

        let textView = UITextView()
        textView.backgroundColor = UIColor.red
        textView.frame = CGRect(x: 100, y: 100, width: 300, height: 40)
        self.view.addSubview(textView)

        let button = UIButton(frame: CGRect(x: 100, y: 300, width: 300, height: 40))
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        self.view.addSubview(button)

    }

    @objc
    func click() {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

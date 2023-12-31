//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import UIKit
import RxCocoa
import SnapKit
import RxSwift
import LarkRVC
import EENavigator
import LarkOPInterface
import LKTracing
import LarkSuspendable
import LarkUIKit

//import LarkSu

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let nav = LkNavigationController(rootViewController: VC())
        self.window?.rootViewController = nav
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        setup()
//        RVCManager.setup()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

    private func setup() {
        let config = OPTraceConfig(prefix: LKTracing.identifier) { (parent) -> String in
            return LKTracing.newSpan(traceId: parent)
        }
        OPTraceService.default().setup(config)
    }

}

class VC: UIViewController {

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Test"

        let btn = UIButton()
        btn.backgroundColor = .blue
        btn.setTitle("present", for: .normal)
        view.addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.width.height.equalTo(100)
        }
        btn.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            let from = WindowTopMostFrom(vc: self)
            Navigator.shared.push(URL(string: "http://106.15.230.144:8080/?token=111#/idle")!, from: from)
//            Navigator.shared.push(URL(string: "http://106.15.230.144:8081/?token=111#/idle")!, from: from)
        }).disposed(by: disposeBag)

        let btn2 = UIButton()
        btn2.backgroundColor = .green
        btn2.setTitle("VC", for: .normal)
        view.addSubview(btn2)
        btn2.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.width.height.equalTo(100)
        }
        btn2.rx.tap.subscribe(onNext: {
            if let _ = SuspendManager.shared.customView(forKey: "VC") {
                SuspendManager.shared.removeCustomView(forKey: "VC")
            } else {
                let v = UIView()
                v.backgroundColor = .red
                SuspendManager.shared.addCustomView(v, size: CGSize(width: 144, height: 80), forKey: "VC")
            }
        }).disposed(by: disposeBag)
    }
}

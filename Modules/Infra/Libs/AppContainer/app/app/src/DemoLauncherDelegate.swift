//
//  DemoLauncherDelegate.swift
//  AppContainerDev
//
//  Created by 李晨 on 2020/1/6.
//

import UIKit
import Foundation
import AppContainer
import Swinject

class DemoAssembly: Assembly {
    func assemble(container: Container) {
        BootLoader.shared.registerApplication(
            delegate: DemoApplicationDelegate.self,
            level: .low
        )
    }

    init() {}
}

class DemoApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "Demo", daemon: true)

    required init(context: AppContext) {
    }
}

class ViewController: UIViewController {

    var value: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 44)
        label.text = "\(self.value)"
        label.frame = CGRect(x: 100, y: 100, width: 100, height: 88)
        self.view.addSubview(label)

        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        self.view.addGestureRecognizer(tap)
    }

    @objc
    func click() {
        let activity = NSUserActivity(activityType: "demo")
        activity.title = "\(self.value + 1)"
        activity.userInfo = ["value": "\(self.value + 1)"]
        if #available(iOS 13.0, *) {
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
        }
    }
}

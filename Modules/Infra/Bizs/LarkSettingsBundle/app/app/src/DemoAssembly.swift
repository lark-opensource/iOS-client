//
//  DemoAssembly.swift
//  LarkSettingsBundleDev
//
//  Created by Miaoqi Wang on 2020/3/29.
//

import UIKit
import Foundation
import Swinject
import AppContainer

class DemoAssembly: Assembly {

    func assemble(container: Container) {
        BootLoader.shared.registerApplication(
            delegate: DemoApplicationDelegate.self,
            level: .default
        )
    }
}

class DemoApplicationDelegate: ApplicationDelegate {
    static var config: Config = Config(name: "DemoApplicationDelegate", daemon: true)

    required init(context: AppContext) {
        context.dispatcher.add(observer: self) { (_, message: DidCreateWindow) in
            message.window.rootViewController = MainViewController(nibName: nil, bundle: nil)
            message.window.rootViewController?.view.backgroundColor = UIColor.white
            message.window.makeKeyAndVisible()
        }
    }
}

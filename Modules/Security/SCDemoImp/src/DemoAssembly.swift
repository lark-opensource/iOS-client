//
//  DemoAssembly.swift
//  Example
//
//  Created by qingchun on 2022/7/5.
//

import Swinject
import LarkContainer
import LarkTab
import LarkUIKit
import EENavigator
import LarkDebug
// import LarkEmotionKeyboard
import LarkAssembler

final public class DemoAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {

    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(plainPattern: DemoTab.tab.urlString, priority: .high) { (_, res) in
            res.end(resource: DemoVC(userResolver: container.getCurrentUserResolver()))
        }
    }

    public func registTabRegistry(container: Container) {
        (DemoTab.tab, { (_: [URLQueryItem]?) -> TabRepresentable in
            DemoTab()
        })
    }

}

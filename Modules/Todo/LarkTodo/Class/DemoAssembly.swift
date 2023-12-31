//
//  DemoAssembly.swift
//  LarkTodo
//
//  Created by wangwanxin on 2021/5/11.
//

import Swinject
import LarkContainer
import LarkTab
import LarkUIKit
import EENavigator
import FLEX
import LarkDebug
import LarkEmotionKeyboard
import LarkAssembler

public class DemoAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) { }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.plain(FakeTab.tab.urlString)
            .priority(.high)
            .handle(compatibleMode: { true }) { r, _, res in
                let vc = FakeViewController(resolver: r)
                if Display.pad {
                    res.end(resource: vc)
                } else {
                    res.end(resource: LkNavigationController(rootViewController: vc))
                }
            }
    }


    public func registTabRegistry(container: Container) {
        (FakeTab.tab, { (_: [URLQueryItem]?) -> TabRepresentable in
            FakeTab()
        })
    }

}

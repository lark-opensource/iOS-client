//
//  LoadDocsTask.swift
//  LarkSpaceKit
//
//  Created by lizechuang on 2020/7/20.
//

import Foundation
import BootManager
import LarkContainer
import LarkAppConfig
import LarkAccountInterface
import AnimatedTabBar
import LarkTab
import SKCommon
import SKFoundation

class LoadDocsTask: UserFirstTabPreloadBootTask, Identifiable {
    static var identify = "LoadDocsTask"

    override class var compatibleMode: Bool { CCMUserScope.compatibleMode }

    override var firstTabURLString: String { return Tab.doc.urlString }

    override func execute(_ context: BootContext) {
        let docsViewControllerFactory = try? userResolver.resolve(assert: DocsViewControllerFactory.self)
        docsViewControllerFactory?.loadFirstPageIfNeeded()
    }
}

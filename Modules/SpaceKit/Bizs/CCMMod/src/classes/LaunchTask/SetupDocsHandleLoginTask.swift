//
//  SetupDocsHandleLoginTask.swift
//  LarkSpaceKit
//
//  Created by LiXiaolin on 2020/9/29.
//  

import Foundation
import BootManager
import LarkContainer
import LarkAppConfig
import LarkAccountInterface
import LarkPerf
import SKCommon
import SKFoundation

class SetupDocsHandleLoginTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupDocsHandleLoginTask"

    override class var compatibleMode: Bool { CCMUserScope.compatibleMode }

    override var scope: Set<BizScope> {
        return [.docs]
    }

    override func execute(_ context: BootContext) {

        let docsViewControllerFactory = try? userResolver.resolve(assert: DocsViewControllerFactory.self)

        // 原afterAccountLoaded
        let isFastLogin = context.isFastLogin
        if isFastLogin { AppStartupMonitor.shared.start(key: .docSDK) }
        docsViewControllerFactory?.accountLoaded(userResolver: userResolver)
        if isFastLogin { AppStartupMonitor.shared.end(key: .docSDK) }

        // 原afterLaunchHome
        docsViewControllerFactory?.larkUserDidLogin(nil, nil) // account参数目前没有使用，所以传入nil
    }
}

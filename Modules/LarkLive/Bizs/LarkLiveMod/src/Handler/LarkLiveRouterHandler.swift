//
//  LarkLiveRouterHandler.swift
//  ByteView
//
//  Created by panzaofeng on 2021/10/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import Swinject
import LarkLiveInterface



/// 处理收到路由系统的事件，组装browser对象，注册extension item
final class LarkLiveRouterHandler: TypedRouterHandler<LarkLiveRouterBody> {

    private let container: Container

    init(container: Container) {
        self.container = container
        super.init()
    }

    override func handle(_ body: LarkLiveRouterBody, req: Request, res: Response) {
        if let service = container.resolve(LarkLiveService.self) {
            service.setupLive(url: body.url)
            service.startLive(url: body.url, context: nil)
        }
    }
}

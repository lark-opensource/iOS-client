//
//  WorkplaceForwardBlockHandler.swift
//  WorkplaceMod
//
//  Created by Shengxy on 2023/5/11.
//

import Foundation
import Swinject
import EENavigator
import LarkContainer
import LarkUIKit
import RxSwift
import LarkNavigator
import LarkWorkplaceModel

#if MessengerMod
import LarkForward
import LarkMessengerInterface

struct WorkplaceForwardBlockBody: PlainBody {
    static var pattern: String = "//client/workplace/forwardBlock"
    typealias ShareTaskGenerator = (_ receivers: [WPMessageReceiver], _ leaveMessage: String?) -> Observable<[String]>?
    let shareTaskGenerator: ShareTaskGenerator

    init(shareTaskGenerator: @escaping ShareTaskGenerator) {
        self.shareTaskGenerator = shareTaskGenerator
    }
}

final class WorkplaceForwardBlockHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    func handle(_ body: WorkplaceForwardBlockBody, req: EENavigator.Request, res: Response) throws {
        let content = WorkplaceForwardBlockContent(body: body)
        let factory = ForwardAlertFactory(userResolver: userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = try userResolver.resolve(assert: ForwardViewControllerRouterProtocol.self)
        let vc = NewForwardViewController(provider: provider, router: router)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
#endif

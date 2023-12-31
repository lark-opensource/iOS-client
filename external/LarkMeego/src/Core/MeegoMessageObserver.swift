//
//  MeegoMessageObserver.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/5/19.
//

import Foundation
#if MessengerMod
import LarkMessageBase
#endif
import LarkContainer
import LarkMeegoInterface
import ThreadSafeDataStructure

#if MessengerMod
class MeegoCellLifeCycleObserver: CellLifeCycleObsever {
    @Provider private var meegoService: LarkMeegoService
    private let flowController = FlowController()

    func willDisplay(metaModel: CellMetaModel, context: PageContext) {
        func handle() {
            guard FeatureGating.get(by: FeatureGating.flutterEnginePreload4MeegoEnable, userResolver: nil) else {
                return
            }

            let matchedUrls = meegoService.matchedMeegoUrls(metaModel.message.getTextPostEnableUrls())
            if matchedUrls.isEmpty {
                return
            }

            (meegoService as? LarkMeegoServiceImpl)?.handleMeegoReachPointExposed(
                message: metaModel.message,
                chat: metaModel.getChat(),
                urls: matchedUrls,
                larkScene: .message
            )
        }

        let id = "\(metaModel.getChat().id)_\(metaModel.message.id)"
        flowController.execute(id: id, executor: handle)
    }
}
#endif

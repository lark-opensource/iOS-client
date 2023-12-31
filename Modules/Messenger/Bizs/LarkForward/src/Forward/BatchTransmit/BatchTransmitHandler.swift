//
//  BatchTransmitHandler.swift
//  LarkForward
//
//  Created by bytedance on 2020/8/19.
//

import Foundation
import UIKit
import LarkContainer
import RxSwift
import LarkUIKit
import LarkCore
import Swinject
import LarkModel
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator
import AppReciableSDK

final class BatchTransmitHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    func handle(_ body: BatchTransmitMessageBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            createForward(body: body, req: req, res: res)
        }
    }

    private func getEnabledConfigs() -> [EntityConfigType] {
        // 置灰话题群和话题帖子
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(chatType: .normal),
            ForwardBotEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
        return includeConfigs
    }

    private func getIncludeConfigs() -> [EntityConfigType] {
        return [ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardBotEntityConfig(),
                ForwardThreadEntityConfig(),
                ForwardMyAiEntityConfig()]
    }

    private func openForwardComponent(body: BatchTransmitMessageBody, req: EENavigator.Request, res: Response) {
        let content = BatchTransmitAlertContent(fromChannelId: body.fromChannelId,
                                                originMergeForwardId: body.originMergeForwardId,
                                                messageIds: body.messageIds,
                                                title: body.title,
                                                traceChatType: body.traceChatType,
                                                containBurnMessage: body.containBurnMessage,
                                                finishCallback: body.finishCallback)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let targetConfig = ForwardTargetConfig(includeConfigs: getIncludeConfigs(),
                                               enabledConfigs: getEnabledConfigs())
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .transmitBatchMessages,
                                               forwardSuccessText: BundleI18n.LarkForward.Lark_Legacy_Success,
                                               forwardResultCallback: { result in
            guard let result = result else { return }
            switch result.forwardResults {
            case .failure(let error):
                //失败埋点
                Tracer.trackForwardError(event: .batchTransmitMessage,
                                         traceChatType: content.traceChatType,
                                         error: error,
                                         chatIds: result.chatIDs ?? [""],
                                         userIds: result.userIDs ?? [""])
            default: break
            }
        })
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
        return
    }

     private func createForward(body: BatchTransmitMessageBody, req: EENavigator.Request, res: Response) {
        // 这里参考MergeForwardHandler & ForwardMessageHandler
        let content = BatchTransmitAlertContent(fromChannelId: body.fromChannelId,
                                                originMergeForwardId: body.originMergeForwardId,
                                                messageIds: body.messageIds,
                                                title: body.title,
                                                traceChatType: body.traceChatType,
                                                containBurnMessage: body.containBurnMessage,
                                                finishCallback: body.finishCallback)

         let factory = ForwardAlertFactory(userResolver: self.userResolver)
         guard let provider = factory.createWithContent(content: content) else { return }
        let canForwardToTopic = false
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider,
                                          router: router,
                                          canForwardToMsgThread: body.supportToMsgThread,
                                          canForwardToTopic: true)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
        return
     }
}

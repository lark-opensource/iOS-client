//
//  MergeForwardHandler.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/6.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import Swinject
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkModel
import LarkOpenFeed
import LarkNavigator
import AppReciableSDK

public final class MergeForwardHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: MergeForwardMessageBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            createForward(body: body, req: req, res: res)
        }
    }

    private func getIncludeConfigs() -> [EntityConfigType] {
        return [ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardBotEntityConfig(),
                ForwardThreadEntityConfig(),
                ForwardMyAiEntityConfig()]
    }

    private func getEnabledConfigs() -> [EntityConfigType] {
        return [ForwardUserEnabledEntityConfig(),
                ForwardGroupChatEnabledEntityConfig(),
                ForwardBotEnabledEntityConfig(),
                ForwardThreadEnabledEntityConfig(),
                ForwardMyAiEnabledEntityConfig()]
    }

    private func openForwardComponent(body: MergeForwardMessageBody, req: EENavigator.Request, res: Response) {
        let content = MergeForwardAlertContent(fromChannelId: body.fromChannelId,
                                               originMergeForwardId: body.originMergeForwardId,
                                               messageIds: body.messageIds,
                                               threadRootMessage: body.threadRootMessage,
                                               title: body.title,
                                               forwardThread: body.forwardThread,
                                               finishCallback: body.finishCallback,
                                               needQuasiMessage: body.needQuasiMessage,
                                               traceChatType: body.traceChatType,
                                               isMsgThread: body.isMsgThread,
                                               containBurnMessage: body.containBurnMessage,
                                               afterForwardBlock: body.afterForwardBlock)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .transmitMergeMessages,
                                               forwardResultCallback: { result in
            guard let result = result else { return }

            switch result.forwardResults {
            case .success(_):
                content.afterForwardBlock?()
            case .failure(let error):
                //失败埋点
                Tracer.trackForwardError(event: .mergeForwardMessage,
                                         traceChatType: content.traceChatType,
                                         error: error,
                                         chatIds: result.chatIDs ?? [""],
                                         userIds: result.userIDs ?? [""])
            }
        })
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: ForwardTargetConfig(includeConfigs: getIncludeConfigs(),
                                                                            enabledConfigs: getEnabledConfigs()))
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private func createForward(body: MergeForwardMessageBody, req: EENavigator.Request, res: Response) {

        let content = MergeForwardAlertContent(fromChannelId: body.fromChannelId,
                                               originMergeForwardId: body.originMergeForwardId,
                                               messageIds: body.messageIds,
                                               threadRootMessage: body.threadRootMessage,
                                               title: body.title,
                                               forwardThread: body.forwardThread,
                                               finishCallback: body.finishCallback,
                                               needQuasiMessage: body.needQuasiMessage,
                                               traceChatType: body.traceChatType,
                                               isMsgThread: body.isMsgThread,
                                               containBurnMessage: body.containBurnMessage,
                                               afterForwardBlock: body.afterForwardBlock)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let canForwardToTopic = true
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider,
                                          router: router,
                                          canForwardToMsgThread: body.supportToMsgThread,
                                          canForwardToTopic: canForwardToTopic)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}

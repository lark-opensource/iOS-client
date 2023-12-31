//
//  ForwardFileHandler.swift
//  LarkForward
//
//  Created by kangkang on 2022/8/16.
//

import Swinject
import LarkUIKit
import Foundation
import EENavigator
import LarkMessengerInterface
import LarkNavigator
import LarkModel

final class ForwardFileHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    func handle(_ body: ForwardFileBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            openForward(body: body, req: req, res: res)
        }
    }
    private func openForward(body: ForwardFileBody, req: Request, res: Response) {
        let content = ForwardFileAlertContent(fileURL: body.fileURL, fileName: body.fileName, fileSize: body.fileSize)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let vc = NewForwardViewController(provider: provider, router: router)
        vc.shareResultsCallBack = body.shareResultsCallBack
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    // 过滤配置
    func getIncludeConfigs(content: ForwardFileAlertContent) -> IncludeConfigs {
        var includeConfigs: IncludeConfigs = [ForwardUserEntityConfig(tenant: content.includeOuter ? .all : .inner),
                                              ForwardGroupChatEntityConfig(tenant: content.includeOuter ? .all : .inner),
                                              ForwardMyAiEntityConfig()]
        if content.includeThread { includeConfigs.append(ForwardThreadEntityConfig()) }
        if content.includeBot { includeConfigs.append(ForwardBotEntityConfig()) }
        return includeConfigs
    }

    // 置灰配置
    func getEnabledConfigs(content: ForwardFileAlertContent) -> IncludeConfigs {
        // 搜索目前暂无法过滤机器人，需要置灰机器人来兜底
        var includeConfigs: IncludeConfigs = [ForwardUserEnabledEntityConfig(),
                                              ForwardGroupChatEnabledEntityConfig(),
                                              ForwardThreadEnabledEntityConfig(),
                                              ForwardMyAiEnabledEntityConfig()]
        if content.includeBot { includeConfigs.append(ForwardBotEnabledEntityConfig()) }
        return includeConfigs
    }

    private func openForwardComponent(body: ForwardFileBody, req: Request, res: Response) {
        let commonConfig = ForwardCommonConfig(enableCreateGroupChat: false,
                                               forwardTrackScene: .sendFile,
                                               forwardResultCallback: { result in
            let forwardRes = result?.forwardResults
            switch forwardRes {
            case .success(let data):
                body.shareResultsCallBack?(data.compactMap { $0 }.map { ($0.chatID, $0.isSuccess) })
            case .failure(_), .none:
                break
            }
        })
        let content = ForwardFileAlertContent(fileURL: body.fileURL,
                                              fileName: body.fileName,
                                              fileSize: body.fileSize)
        let factory = ForwardAlertFactory(userResolver: userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let targetConfig = ForwardTargetConfig(includeConfigs: getIncludeConfigs(content: content),
                                               enabledConfigs: getEnabledConfigs(content: content))
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}

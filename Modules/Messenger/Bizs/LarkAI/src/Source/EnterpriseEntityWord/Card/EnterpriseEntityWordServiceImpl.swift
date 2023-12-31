//
//  EnterpriseEntityWordService.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/1/7.
//

import Foundation
import UIKit
import LarkSDKInterface
import LarkContainer
import RustPB
import RxSwift
import LarkMessengerInterface
import EENavigator
import LarkMenuController
import ServerPB
import LKCommonsLogging
import UniverseDesignToast
import LarkMessageBase
import LarkLocalizations
import LarkStorage
import LarkUIKit
import LarkSearchCore
import LarkRichTextCore
import LarkFoundation
import LarkSecurityAudit
import SwiftProtobuf
import Lynx

#if !DEBUG && !ALPHA
extension ServerPB_Enterprise_entitiy_MGetEntityCardResponse: SwiftProtobuf.MessageJSONLarkExt {}
#endif

private enum EnterpriseEntityWordCardState {
    /// 已经展示
    case shown
    /// 实体词信息请求中
    case inProgress
    /// 未展示
    case hidden
}

final class EnterpriseEntityWordServiceImpl: EnterpriseEntityWordService, UserResolverWrapper {
    private static let logger = Logger.log(EnterpriseEntityWordServiceImpl.self, category: "EnterpriseEntityWord.EnterpriseEntityWordServiceImpl")
    private var abbreviationAPI: EnterpriseEntityWordAPI
    private var showCardState: EnterpriseEntityWordCardState = .hidden
    private var menuVC: MenuViewController?
    private var lynxViewController: FullPageLynxViewController?
    private var enterpriseEntityWordLynxViewModel: TopicLynxViewModel?
    private var showCardStartTime: TimeInterval?
    private let disposeBag = DisposeBag()
    private let vmFactory = LynxViewModelFactory()
    let userResolver: UserResolver
    private var scene: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene?
    private var requestDuration: TimeInterval?
    var sceneDesc: String {
        switch scene {
        case .messenger: return "im"
        case .docs:      return "doc"
        case .search:    return "search"
        default:         return "other"
        }
    }
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.abbreviationAPI = RustEnterpriseEntityWordAPI(resolver: resolver)
    }
    // swiftlint:disable:next function_parameter_count
    func showEnterpriseTopic(abbrId: String,
                             query: String,
                             chatId: String?,
                             sense: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                             targetVC: UIViewController?,
                             completion: ((ShowEnterpriseTopicResult) -> Void)?,
                             clientArgs: String?,
                             analysisParams: String?,
                             passThroughAction: ((String) -> Void)?,
                             didTapApplink: ((URL) -> Void)?) {
        self.showEnterpriseTopicInternal(abbrId: abbrId,
                                         query: query,
                                         chatId: chatId,
                                         msgId: nil,
                                         scene: sense,
                                         targetVC: targetVC,
                                         completion: completion,
                                         clientArgs: clientArgs,
                                         analysisParams: analysisParams,
                                         passThroughAction: passThroughAction,
                                         didTapApplink: didTapApplink)
    }

    func showEnterpriseTopicForIM(abbrId: String,
                                  query: String,
                                  chatId: String?,
                                  msgId: String?,
                                  sense: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                                  targetVC: UIViewController?,
                                  clientArgs: String?,
                                  completion: ((ShowEnterpriseTopicResult) -> Void)?,
                                  passThroughAction: ((String) -> Void)?) {
        self.showEnterpriseTopicInternal(abbrId: abbrId,
                                         query: query,
                                         chatId: chatId,
                                         msgId: msgId,
                                         scene: sense,
                                         targetVC: targetVC,
                                         completion: completion,
                                         clientArgs: clientArgs,
                                         passThroughAction: passThroughAction)
    }

    func showEnterpriseTopicInternal(abbrId: String,
                                     query: String,
                                     chatId: String?,
                                     msgId: String?,
                                     scene: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                                     targetVC: UIViewController?,
                                     completion: ((ShowEnterpriseTopicResult) -> Void)?,
                                     clientArgs: String? = nil,
                                     analysisParams: String? = nil,
                                     passThroughAction: ((String) -> Void)? = nil,
                                     didTapApplink: ((URL) -> Void)? = nil) {
        // 如果实体词后续接入文档了，需要更新一下埋点
        EnterpriseEntityWordServiceImpl.logger.info("In showEnterpriseTopic! abbrId:\(abbrId), scene: \(scene)")
        showCardStartTime = Date().timeIntervalSince1970
        EnterpriseEntityWordTracker.clickMessageEnterpriseEntityWord(chatId: chatId ?? "")
        if LarkAITracker.enablePostTrack() {
            self.scene = scene
            LarkAITracker.trackForStableWatcher(domain: "asl_lingo",
                                                message: "asl_lingo_click",
                                                metricParams: [:],
                                                categoryParams: ["scene": sceneDesc])
        }
        EnterpriseEntityWordServiceImpl.logger.info("Start showEnterpriseTopic request!")
        let manager = ASTemplateManager()
        /// 暂时去除动态下发，使用本地兜底文件
//        manager.initGecko()
        showEnterpriseTopicV2(abbrId: abbrId,
                              query: query,
                              chatId: chatId,
                              msgId: msgId,
                              scene: scene,
                              targetVC: targetVC,
                              completion: completion,
                              clientArgs: clientArgs,
                              analysisParams: analysisParams,
                              passThroughAction: passThroughAction,
                              didTapApplink: didTapApplink)

    }

    private func changeCardState() {
        defer { showCardState = .hidden }
        guard let menuVC = menuVC else { return }
        self.menuVC = nil
    }

    func dismissEnterpriseTopic(animated: Bool, completion: (() -> Void)?) {
        lynxViewController?.dismiss(animated: animated, completion: completion)
        menuVC?.dismiss(animated: animated, completion: completion)
    }

    /// 获取消息气泡中实体词高亮
    func abbreviationHighlightEnabled() -> Bool {
        // 租户功能开关
        guard KVPublic.Setting.enterpriseEntityTenantSwitch.value(forUser: userResolver.userID) else {
            EnterpriseEntityWordServiceImpl.logger.error("abbreviationHighlightEnabled false, tenant has no permission!")
            return false
        }
        // 设置
        return KVPublic.Setting.enterpriseEntityMessage.value(forUser: userResolver.userID)
    }

    private func showTip(with tip: String, on targetVC: UIViewController?) {
        if let hudOn = targetVC?.view {
            UDToast.showTips(with: tip, on: hudOn)
        }
    }

    // swiftlint:disable:next function_parameter_count
    func showEnterpriseTopicV2(abbrId: String,
                               query: String,
                               chatId: String?,
                               msgId: String?,
                               scene: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                               targetVC: UIViewController?,
                               completion: ((ShowEnterpriseTopicResult) -> Void)?,
                               clientArgs: String?,
                               analysisParams: String?,
                               passThroughAction: ((String) -> Void)?,
                               didTapApplink: ((URL) -> Void)?) {
        EnterpriseEntityWordServiceImpl.logger.info("Start showEnterpriseTopic request v2! abbrId:\(abbrId), scene: \(scene)")
        var pair: (biz: String, scene: String) {
            switch scene {
            case .messenger: return ("im", "click")
            case .docs: return ("doc", "hover")
            case .search: return ("search", "connector")
            @unknown default: return ("", "")
            }
        }
        func trackForFail(failReason: Any) {
            guard LarkAITracker.enablePostTrack() else { return }
            LarkAITracker.trackForStableWatcher(domain: "asl_lingo",
                                                message: "asl_lingo_fail",
                                                metricParams: [:],
                                                categoryParams: [
                                                    "fail_reason": failReason,
                                                    "scene": sceneDesc
                                                ])
        }
        abbreviationAPI.getAbbreviationInfomationV2(abbrId: abbrId, query: query, biz: pair.biz, scene: pair.scene)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak targetVC] (response) in
                guard let self = self, let viewController = targetVC else {
                    return
                }
                if response.errCode != 0 {
                    var tipString = response.errMsg
                    completion?(.noResult)
                    self.showTip(with: tipString, on: targetVC)
                    trackForFail(failReason: response.errCode.description)
                    return
                }
                /// TODO: 删除cardId相关逻辑
                guard !response.cards.isEmpty else { return }
                let card = response.cards[0]
                if card.card.isEmpty {
                    completion?(.noResult)
                    self.showTip(with: BundleI18n.LarkAI.Lark_ASL_NoEntryFound, on: targetVC)
                    trackForFail(failReason: BundleI18n.LarkAI.Lark_ASL_NoEntryFound)
                    return
                }
                var cardJson: String = ""
                do {
                    cardJson = try response.jsonString()
                } catch {
                    completion?(.noResult)
                    EnterpriseEntityWordServiceImpl.logger.info("jsonserialization data failed, cardID: \(card.id)")
                    trackForFail(failReason: "jsonserialization data failed, cardID: \(card.id)")
                    return
                }
                self.requestDuration = ceil((Date().timeIntervalSince1970 - (self.showCardStartTime ?? 0)) * 1000)
                EnterpriseEntityWordServiceImpl.logger.info("getAbbreviationInfomationV2 success!, cardID: \(card.id)")
                let vcSize = viewController.view.frame.size
                guard let supportOrientations = targetVC?.supportedInterfaceOrientations else { return }
                let vm = self.vmFactory.createTopicViewModel(userResolver: self.userResolver,
                                                             cardId: card.id,
                                                             json: cardJson,
                                                             templateName: card.templateName,
                                                             vcSize: vcSize,
                                                             scene: scene,
                                                             chatId: chatId,
                                                             msgId: msgId,
                                                             isSharing: analysisParams != nil, // 只有分享时传 analysisParams
                                                             supportOrientations: supportOrientations,
                                                             passThroughAction: passThroughAction,
                                                             clientArgs: clientArgs,
                                                             analysisParams: analysisParams,
                                                             didTapApplink: didTapApplink) { data in
                    guard LarkAITracker.enablePostTrack() else { return }
                    if data != nil {
                        LarkAITracker.trackForStableWatcher(domain: "asl_lingo",
                                                            message: "asl_lingo_success",
                                                            metricParams: [:],
                                                            categoryParams: ["scene": self.sceneDesc])
                    } else {
                        trackForFail(failReason: "lynx render fail")
                    }
                }
                // bugfix: 需要 self 持有一下 vm 否则出了作用域就（比如旋转屏幕）被销毁了，因为 vm 是被弱持有
                self.enterpriseEntityWordLynxViewModel = vm

                let params = TopicLynxDependency(userResolver: self.userResolver, viewModel: vm)
                let lynxViewController = FullPageLynxViewController(viewModel: vm, params: params)
                self.lynxViewController = lynxViewController
                if LarkAITracker.enablePostTrack() {
                    let extraTiming = LynxExtraTiming()
                    extraTiming.openTime = UInt64((self.showCardStartTime ?? 0) * 1000)
                    self.lynxViewController?.setExtraTiming(extraTiming: extraTiming)
                    self.lynxViewController?.updateBlock = { (info, timing) in
                        lynxOnUpdate(info: info, updateTiming: timing)
                    }
                }
                lynxViewController.dismissBlock = { [weak self] in
                    guard let self = self else { return }
                    self.showCardState = .hidden
                }
                lynxViewController.modalPresentationStyle = .overCurrentContext
                lynxViewController.transitioningDelegate = lynxViewController
                if Display.pad {
                    self.userResolver.navigator.present(
                        lynxViewController, wrap: LkNavigationController.self, from: viewController,
                        prepare: {
                            $0.modalPresentationStyle = .formSheet
                        },
                        animated: true)
                } else {
                    self.userResolver.navigator.present(
                        lynxViewController, wrap: LkNavigationController.self, from: viewController,
                        prepare: {
                            $0.transitioningDelegate = lynxViewController
                            $0.modalPresentationStyle = .custom
                        },
                        animated: true)
                }
            }, onError: { [weak self] error in
                EnterpriseEntityWordServiceImpl.logger.info("getAbbreviationInfomationV2 fail, error:\(error), abbrId:\(abbrId), scene: \(scene)")
                guard let self = self else { return }
                self.showTip(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: targetVC)
                trackForFail(failReason: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError)
                completion?(.fail)
            }).disposed(by: disposeBag)
        func lynxOnUpdate(info: [AnyHashable: Any], updateTiming: [AnyHashable: Any]) {
            guard LarkAITracker.enablePostTrack() else { return }
            var drawEnd: TimeInterval = 0
            var openTime: TimeInterval = 0
            var prepareTemplateStart: TimeInterval = 0
            var loadTemplateStart: TimeInterval = 0
            if !info.isEmpty {
                if let timeDic = info["extra_timing"] {
                    openTime = (timeDic as? [AnyHashable: Any])?["open_time"] as? TimeInterval ?? 0
                    prepareTemplateStart = (timeDic as? [AnyHashable: Any])?["prepare_template_start"] as? TimeInterval ?? 0
                }
                if let timeDic = info["setup_timing"] {
                    loadTemplateStart = (timeDic as? [AnyHashable: Any])?["load_template_start"] as? TimeInterval ?? 0
                }
            }
            if !updateTiming.isEmpty {
                if let timeDic = updateTiming["__lynx_timing_actual_fmp"] {
                    drawEnd = (timeDic as? [AnyHashable: Any])?["draw_end"] as? TimeInterval ?? 0
                }
            }
            let metricParams: [String: Any] = [
                "duration": ceil((Date().timeIntervalSince1970 - (self.showCardStartTime ?? 0)) * 1000),
                "request_duration": self.requestDuration ?? 0,
                "total_actualFmp": ceil(drawEnd - openTime),
                "actualFmp": ceil(drawEnd - prepareTemplateStart),
                "lynx_actualFmp": ceil(drawEnd - loadTemplateStart)
            ]
            LarkAITracker.trackForStableWatcher(domain: "asl_lingo",
                                                message: "asl_lingo_duration",
                                                metricParams: metricParams,
                                                categoryParams: ["scene": sceneDesc])
        }
    }
}

//
//  ShareContentAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/4/2.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import UniverseDesignToast
import EENavigator
import RxSwift
import LKCommonsLogging
import LarkAlertController
import LarkSDKInterface
import LarkMessengerInterface

struct ShareContentAlertContent: ForwardAlertContent {
    let title: String //标题
    let content: String //具体的分享内容
    let sourceAppName: String? //分享来源app
    let sourceAppUrl: String? //分享来源app url
    var shouldShowInputViewWhenShareToTopicCircle: Bool //分享到话题圈是否显示输入框
    var getForwardContentCallback: GetForwardContentCallback {
        let param = SendTextForwardParam(textContent: self.content)
        let forwardContent = ForwardContentParam.sendTextMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }

    init(title: String,
         content: String,
         sourceAppName: String? = nil,
         sourceAppUrl: String? = nil,
         shouldShowInputViewWhenShareToTopicCircle: Bool) {

        self.title = title
        self.content = content
        self.sourceAppName = sourceAppName
        self.sourceAppUrl = sourceAppUrl
        self.shouldShowInputViewWhenShareToTopicCircle = shouldShowInputViewWhenShareToTopicCircle
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ShareContentAlertProvider: ForwardAlertProvider {
    static let logger = Logger.log(ShareContentAlertProvider.self, category: "Module.IM.Share")
    let disposeBag = DisposeBag()

    override var isSupportMention: Bool {
        return true
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareContentAlertContent != nil {
            return true
        }
        return false
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        let includeConfigs: IncludeConfigs = [
            // text的转发接口暂不支持转发至帖子，需置灰
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    /// 是否需要展示输入框
    override public func isShowInputView(by items: [ForwardItem]) -> Bool {
        guard let messageContent = content as? ShareContentAlertContent, messageContent.shouldShowInputViewWhenShareToTopicCircle == false else { return true }
        for item in items {
            let isTopicCircl = (item.type == .chat && item.isThread == true) || item.type == .threadMessage
            if isTopicCircl {
                return false
            }
        }
        return true
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareContentAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let topmostFrom = WindowTopMostFrom(vc: from)
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        forwardService
            .forward(content: messageContent.content, to: ids.chatIds, userIds: ids.userIds, extraText: input ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatIds) in
                hud.remove()
                if let sourceAppName = messageContent.sourceAppName, let sourceAppUrl = messageContent.sourceAppUrl {
                    if let sourceAppUrlStr = sourceAppUrl.removingPercentEncoding,
                        let sourceAppUrl = URL(string: sourceAppUrlStr) {
                        self?.showRouterShareFinishConfirmView(sourceAppName: sourceAppName,
                                                               sourceAppUrl: sourceAppUrl,
                                                               chatIds: chatIds,
                                                               subject: secondConfirmSubject,
                                                               from: topmostFrom)
                    } else {
                        ShareContentAlertProvider.logger.error("未提供有效的sourceAppUrl",
                                                               additionalData: [
                                                                "sourceAppName": sourceAppName])
                    }
                } else {
                    secondConfirmSubject.onNext(chatIds)
                    secondConfirmSubject.onCompleted()
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                ShareContentAlertProvider.logger.error("内容分享失败", error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareContentAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let topmostFrom = WindowTopMostFrom(vc: from)
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        forwardService
            .forward(content: messageContent.content, to: ids.chatIds, userIds: ids.userIds, attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatIds) in
                hud.remove()
                if let sourceAppName = messageContent.sourceAppName, let sourceAppUrl = messageContent.sourceAppUrl {
                    if let sourceAppUrlStr = sourceAppUrl.removingPercentEncoding,
                        let sourceAppUrl = URL(string: sourceAppUrlStr) {
                        self?.showRouterShareFinishConfirmView(sourceAppName: sourceAppName,
                                                               sourceAppUrl: sourceAppUrl,
                                                               chatIds: chatIds,
                                                               subject: secondConfirmSubject,
                                                               from: topmostFrom)
                    } else {
                        ShareContentAlertProvider.logger.error("未提供有效的sourceAppUrl",
                                                               additionalData: [
                                                                "sourceAppName": sourceAppName])
                    }
                } else {
                    secondConfirmSubject.onNext(chatIds)
                    secondConfirmSubject.onCompleted()
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                ShareContentAlertProvider.logger.error("内容分享失败", error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    private func showRouterShareFinishConfirmView(sourceAppName: String,
                                                  sourceAppUrl: URL,
                                                  chatIds: [String],
                                                  subject: BehaviorSubject<[String]>,
                                                  from: NavigatorFrom) {
        let alertController = LarkAlertController()
        alertController.setContent(view: ShareFinishView())
        alertController.addSecondaryButton(text: "\(BundleI18n.LarkForward.Lark_Legacy_ShareBack) \(sourceAppName)", dismissCompletion: {
            subject.onNext(chatIds)
            subject.onCompleted()
            UIApplication.shared.open(sourceAppUrl)
        })
        alertController.addSecondaryButton(text: BundleI18n.LarkForward.Lark_Legacy_StayFeishu(), dismissCompletion: {
            subject.onNext(chatIds)
            subject.onCompleted()
        })

        userResolver.navigator.present(alertController, from: from)
    }
}

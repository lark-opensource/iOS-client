//
//  ShareMailMessageProvider.swift
//  LarkForward
//
//  Created by tefeng liu on 2019/12/10.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignToast
import LarkModel
import Kingfisher
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import LKCommonsLogging
import EENavigator
import Homeric
import LKCommonsTracker

struct ShareMailMessageContent: ForwardAlertContent {
    let threadId: String
    let messageIds: [String]
    let title: String
    var statisticsParams: [String: Any] = [:]
    init(threadId: String, messageIds: [String], title: String) {
        self.threadId = threadId
        self.title = title
        self.messageIds = messageIds
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ShareMailMessageProvider: ForwardAlertProvider {
    static let logger = Logger.log(ShareMailMessageProvider.self, category: "Module.IM.Share")
    let disposeBag = DisposeBag()

    // MARK: - override
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareMailMessageContent != nil {
            return true
        }
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    override var isSupportMultiSelectMode: Bool {
        return true
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let content = self.content as? ShareMailMessageContent else { return nil }
        //邮件分享置灰话题
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let content = content as? ShareMailMessageContent else { return nil }

        let container = BaseForwardConfirmFooter()

        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.image = Resources.mail_icon
        container.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(50)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.text = content.title
        container.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }

        return container
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? ShareMailMessageContent else { return .just([]) }
        guard let mailApi = try? self.resolver.resolve(assert: MailAPI.self) else { return .just([]) }
        guard let window = from.view.window else {
            assertionFailure()
            return .just([])
        }

        let ids = self.itemsToIds(items)
        var chatIds: [String] = []
        UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        let chatObservable = self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
        return chatObservable.flatMap { (chats) -> Observable<[String]> in
            chatIds = chats.map { (chat) -> String in
                return chat.id
            }
            let observable = mailApi.mailSendCard(threadId: content.threadId, messageIds: content.messageIds, chatIds: chatIds, note: input ?? "")
            return observable.flatMap { (_) -> Observable<[String]> in
                return .just([])
            }

        }.observeOn(MainScheduler.instance).do(onNext: { (_) in
            UDToast.showSuccess(
                with: BundleI18n.LarkForward.Mail_Share_SharedSuccessfully,
                on: window
            )
            secondConfirmSubject.onNext(chatIds)
            secondConfirmSubject.onCompleted()
            // product statistic
            if let trackerKey = content.statisticsParams["KEY"] as? String {
                var params = content.statisticsParams
                params.removeValue(forKey: "KEY")
                Tracker.post(TeaEvent(trackerKey, params: params))
            }
        }, onError: { (error) in
            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .banned(let message):
                    UDToast.showFailure(with: message, on: window, error: error)
                default:
                    UDToast.showFailure(
                        with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed,
                        on: window,
                        error: error
                    )
                }
            } else {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed,
                    on: window,
                    error: error
                )
            }
            ShareMailMessageProvider.logger.error("内容分享失败", error: error)
        })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? ShareMailMessageContent else { return .just([]) }
        guard let mailApi = try? self.resolver.resolve(assert: MailAPI.self) else { return .just([]) }
        guard let window = from.view.window else {
            assertionFailure()
            return .just([])
        }

        let ids = self.itemsToIds(items)
        var chatIds: [String] = []
        UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        let chatObservable = self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
        return chatObservable.flatMap { (chats) -> Observable<[String]> in
            chatIds = chats.map { (chat) -> String in
                return chat.id
            }
            let observable = mailApi.mailSendCard(threadId: content.threadId, messageIds: content.messageIds, chatIds: chatIds, note: attributeInput?.string ?? "")
            return observable.flatMap { (_) -> Observable<[String]> in
                return .just([])
            }

        }.observeOn(MainScheduler.instance).do(onNext: { (_) in
            UDToast.showSuccess(
                with: BundleI18n.LarkForward.Mail_Share_SharedSuccessfully,
                on: window
            )
            secondConfirmSubject.onNext(chatIds)
            secondConfirmSubject.onCompleted()
            // product statistic
            if let trackerKey = content.statisticsParams["KEY"] as? String {
                var params = content.statisticsParams
                params.removeValue(forKey: "KEY")
                Tracker.post(TeaEvent(trackerKey, params: params))
            }
        }, onError: { (error) in
            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .banned(let message):
                    UDToast.showFailure(with: message, on: window, error: error)
                default:
                    UDToast.showFailure(
                        with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed,
                        on: window,
                        error: error
                    )
                }
            } else {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed,
                    on: window,
                    error: error
                )
            }
            ShareMailMessageProvider.logger.error("内容分享失败", error: error)
        })
    }
}

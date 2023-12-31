//
//  ShareMailAttachmentProvider.swift
//  LarkForward
//
//  Created by Ryan on 2020/9/29.
//

import Foundation
import UIKit
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
import Swinject
import LarkFeatureGating
import LarkAccountInterface
import LarkUIKit

struct ShareMailAttachmentAlertContent: ForwardAlertContent {
    let title: String //标题
    let img: UIImage
    let token: String
    let isLargeAttachment: Bool
    init(title: String, img: UIImage, token: String, isLargeAttachment: Bool) {
        self.title = title
        self.img = img
        self.token = token
        self.isLargeAttachment = isLargeAttachment
    }
}

// nolint: duplicated_code -- 转发v2代码，转发v3全业务GA后可删除
final class ShareMailAttachmentProvider: ForwardAlertProvider {
    static let logger = Logger.log(ShareMailAttachmentProvider.self, category: "Module.Mail.attachment.Share")
    let disposeBag = DisposeBag()

    // MARK: - override
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareMailAttachmentAlertContent != nil {
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
        guard let content = self.content as? ShareMailAttachmentAlertContent else { return nil }
        //邮件分享置灰话题
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let content = content as? ShareMailAttachmentAlertContent else { return nil }

        let container = BaseForwardConfirmFooter()

        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.image = content.img
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
        guard let attachmentAlertContent = content as? ShareMailAttachmentAlertContent,
              let window = from.view.window else { return .just([]) }
        guard let mailApi = try? self.resolver.resolve(assert: MailAPI.self) else { return .just([]) }
        let ids = self.itemsToIds(items)
        var chatIds: [String] = []
        UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        let chatObservable = checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
        return chatObservable.flatMap { (chats) -> Observable<[String]> in
            chatIds = chats.map { (chat) -> String in
                return chat.id
            }
            let observable = mailApi.mailShareAttachment(chatIds: chatIds,
                                                         attachmentToken: attachmentAlertContent.token,
                                                         note: input ?? "",
                                                         isLargeAttachment: attachmentAlertContent.isLargeAttachment)
            return observable.flatMap { (_) -> Observable<[String]> in
                return .just([])
            }
        }.observeOn(MainScheduler.instance).do(onNext: { (_) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "true"]))
            UDToast.showSuccess(
                with: BundleI18n.LarkForward.Mail_Share_SharedSuccessfully,
                on: window
            )
            secondConfirmSubject.onNext(chatIds)
            secondConfirmSubject.onCompleted()
        }, onError: { (error) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "false"]))
            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .banned(let message):
                    UDToast.showFailure(with: message, on: window, error: error)
                default:
                    UDToast.showFailure(
                        with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                        on: window,
                        error: error
                    )
                }
            } else {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                    on: window,
                    error: error
                )
            }
            ShareMailAttachmentProvider.logger.error("内容分享失败", error: error)
        })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let attachmentAlertContent = content as? ShareMailAttachmentAlertContent,
              let window = from.view.window else { return .just([]) }
        guard let mailApi = try? self.resolver.resolve(assert: MailAPI.self) else { return .just([]) }
        let ids = self.itemsToIds(items)
        var chatIds: [String] = []
        UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        let chatObservable = checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
        return chatObservable.flatMap { (chats) -> Observable<[String]> in
            chatIds = chats.map { (chat) -> String in
                return chat.id
            }
            let observable = mailApi.mailShareAttachment(chatIds: chatIds,
                                                         attachmentToken: attachmentAlertContent.token,
                                                         note: attributeInput?.string ?? "",
                                                         isLargeAttachment: attachmentAlertContent.isLargeAttachment)
            return observable.flatMap { (_) -> Observable<[String]> in
                return .just([])
            }
        }.observeOn(MainScheduler.instance).do(onNext: { (_) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "true"]))
            UDToast.showSuccess(
                with: BundleI18n.LarkForward.Mail_Share_SharedSuccessfully,
                on: window
            )
            secondConfirmSubject.onNext(chatIds)
            secondConfirmSubject.onCompleted()
        }, onError: { (error) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "false"]))
            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .banned(let message):
                    UDToast.showFailure(with: message, on: window, error: error)
                default:
                    UDToast.showFailure(
                        with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                        on: window,
                        error: error
                    )
                }
            } else {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                    on: window,
                    error: error
                )
            }
            ShareMailAttachmentProvider.logger.error("内容分享失败", error: error)
        })
    }

    override func shareSureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<ForwardResult> {
        guard let attachmentAlertContent = content as? ShareMailAttachmentAlertContent,
              let window = from.view.window, let mailApi = try? self.resolver.resolve(assert: MailAPI.self) else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        var chatIds: [String] = []
        UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        let chatObservable = checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
        return chatObservable.flatMap { (chats) -> Observable<[Chat]> in
            chatIds = chats.map { (chat) -> String in
                return chat.id
            }
            let observable = mailApi.mailShareAttachment(chatIds: chatIds,
                                                         attachmentToken: attachmentAlertContent.token,
                                                         note: attributeInput?.string ?? "",
                                                         isLargeAttachment: attachmentAlertContent.isLargeAttachment)
            return observable.flatMap { (_) -> Observable<[Chat]> in
                return .just(chats)
            }
        }
        .map { chats in
            var forwardItems: [ForwardItemParam] = []
            chats.forEach {
                var type = ""
                switch $0.type {
                case .p2P: type = "p2P"
                case .group: type = "group"
                case .topicGroup: type = "topicGroup"
                default: type = "unknown"
                }
                var forwardItemParam = ForwardItemParam(isSuccess: true, type: type, name: $0.name, chatID: $0.id, isCrossTenant: $0.isCrossTenant)
                forwardItems.append(forwardItemParam)
            }
            var forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
            return forwardResult
        }
        .observeOn(MainScheduler.instance).do(onNext: { (_) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "true"]))
            UDToast.showSuccess(
                with: BundleI18n.LarkForward.Mail_Share_SharedSuccessfully,
                on: window
            )
            secondConfirmSubject.onNext(chatIds)
            secondConfirmSubject.onCompleted()
        }, onError: { (error) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "false"]))
            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .banned(let message):
                    UDToast.showFailure(with: message, on: window, error: error)
                default:
                    UDToast.showFailure(
                        with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                        on: window,
                        error: error
                    )
                }
            } else {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                    on: window,
                    error: error
                )
            }
            ShareMailAttachmentProvider.logger.error("内容分享失败", error: error)
        })
    }

    override func shareSureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<ForwardResult> {
        guard let attachmentAlertContent = content as? ShareMailAttachmentAlertContent,
              let window = from.view.window, let mailApi = try? self.resolver.resolve(assert: MailAPI.self) else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        var chatIds: [String] = []
        UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        let chatObservable = checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
        return chatObservable.flatMap { (chats) -> Observable<[Chat]> in
            chatIds = chats.map { (chat) -> String in
                return chat.id
            }
            let observable = mailApi.mailShareAttachment(chatIds: chatIds,
                                                         attachmentToken: attachmentAlertContent.token,
                                                         note: input ?? "",
                                                         isLargeAttachment: attachmentAlertContent.isLargeAttachment)
            return observable.map { chats }
        }
        .map { chats in
            var forwardItems: [ForwardItemParam] = []
            chats.forEach {
                var type = ""
                switch $0.type {
                case .p2P: type = "p2P"
                case .group: type = "group"
                case .topicGroup: type = "topicGroup"
                default: type = "unknown"
                }
                var forwardItemParam = ForwardItemParam(isSuccess: true, type: type, name: $0.name, chatID: $0.id, isCrossTenant: $0.isCrossTenant)
                forwardItems.append(forwardItemParam)
            }
            var forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
            return forwardResult
        }
        .observeOn(MainScheduler.instance).do(onNext: { (_) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "true"]))
            UDToast.showSuccess(
                with: BundleI18n.LarkForward.Mail_Share_SharedSuccessfully,
                on: window
            )
            secondConfirmSubject.onNext(chatIds)
            secondConfirmSubject.onCompleted()
        }, onError: { (error) in
            Tracker.post(TeaEvent("email_attachment_share_confirm", params: ["is_success": "false"]))
            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .banned(let message):
                    UDToast.showFailure(with: message, on: window, error: error)
                default:
                    UDToast.showFailure(
                        with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                        on: window,
                        error: error
                    )
                }
            } else {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Mail_Share_FailedToShare,
                    on: window,
                    error: error
                )
            }
            ShareMailAttachmentProvider.logger.error("内容分享失败", error: error)
        })
    }
}

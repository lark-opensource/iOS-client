//
//  RouterProxy.swift
//  MailSDK
//
//  Created by sheyu on 2021/10/19.
//

import Foundation

public typealias MailAttachmentForwardResult = (items: [MailForwardItemParam]?, error: Error?)

public protocol RouterProxy {

    // MARK: - LarkMessengerInterface
    func forwardMailMessageShareBody(threadId: String,
                                     messageIds: [String],
                                     summary: String,
                                     fromVC: UIViewController)

    func forwardShareMailAttachementBody(title: String,
                                         img: UIImage,
                                         token: String,
                                         fromVC: UIViewController,
                                         isLargeAttachment: Bool,
                                         forwardResultsCallBack: @escaping ((MailAttachmentForwardResult) -> Void))

    func pushUserProfile(userId: String, fromVC: UIViewController)
    func openUserProfile(userId: String, fromVC: UIViewController)
    func openNameCard(accountId: String, address: String, name: String, fromVC: UIViewController, callBack: @escaping ((Bool) -> Void))
}

/// 转发完成后返回的一些参数
public struct MailForwardItemParam {
    public var isSuccess: Bool
    public var type: String
    public var name: String
    public var chatID: String
    public var isCrossTenant: Bool
    public init(isSuccess: Bool, type: String, name: String, chatID: String, isCrossTenant: Bool) {
        self.isSuccess = isSuccess
        self.type = type
        self.name = name
        self.chatID = chatID
        self.isCrossTenant = isCrossTenant
    }
}

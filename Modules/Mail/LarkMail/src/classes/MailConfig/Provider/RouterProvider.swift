//
//  RouterProvider.swift
//  LarkMail
//
//  Created by sheyu on 2021/10/19.
//

import EENavigator
import Foundation
import LarkUIKit
import MailSDK
import LarkContainer
#if MessengerMod
import LarkMessengerInterface
#endif

class RouterProvider: RouterProxy {

    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    // MARK: - LarkMessengerInterface
    func forwardMailMessageShareBody(threadId: String,
                                     messageIds: [String],
                                     summary: String,
                                     fromVC: UIViewController) {
#if MessengerMod
        let body = MailMessageShareBody(threadId: threadId, messageIds: messageIds, summary: summary)
        resolver.navigator.present(body: body, from: fromVC, prepare: {
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            $0.modalPresentationStyle = isPad ? .formSheet : .fullScreen
            if #available(iOS 13.0, *), !isPad {
                $0.modalPresentationStyle = .automatic
            }
        })
#endif
    }

    func forwardShareMailAttachementBody(title: String,
                                         img: UIImage,
                                         token: String,
                                         fromVC: UIViewController,
                                         isLargeAttachment: Bool,
                                         forwardResultsCallBack: @escaping ((MailAttachmentForwardResult) -> Void)) {
#if MessengerMod
        let body = ShareMailAttachementBody(title: title,
                                            img: img,
                                            token: token,
                                            isLargeAttachment: isLargeAttachment) { res in
            guard let res = res else {
                let error = LarkMailShareError(message: "no share result")
                forwardResultsCallBack((nil, error))
                return
            }
            switch res {
            case .success(let res):
                let items = res.forwardItems.map {
                    MailForwardItemParam(isSuccess: $0.isSuccess, type: $0.type,
                                         name: $0.name ?? "", chatID: $0.chatID,
                                         isCrossTenant: $0.isCrossTenant ?? false)
                }
                forwardResultsCallBack((items, nil))
            case .failure(let error):
                forwardResultsCallBack((nil, error))
            }

        }
        resolver.navigator.present(body: body, from: fromVC, prepare: {
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            $0.modalPresentationStyle = isPad ? .formSheet : .fullScreen
        })
#endif
    }

    func pushUserProfile(userId: String, fromVC: UIViewController) {
#if MessengerMod
        let body = PersonCardBody(chatterId: userId, source: LarkContactSource.email)
        resolver.navigator.push(body: body, from: fromVC)
#endif
    }

    func openUserProfile(userId: String, fromVC: UIViewController) {
#if MessengerMod
        let body = PersonCardBody(chatterId: userId, source: LarkContactSource.email)
        resolver.navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: fromVC,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
#endif
    }

    func openNameCard(accountId: String, address: String, name: String, fromVC: UIViewController, callBack: @escaping ((Bool) -> Void)) {
#if MessengerMod
        let body = NameCardProfileBody(accountId: accountId, email: address, userName: name, callback: callBack)
        resolver.navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: fromVC,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
#endif
    }
}

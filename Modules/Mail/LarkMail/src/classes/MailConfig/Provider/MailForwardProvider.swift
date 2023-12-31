//
//  MailForwardProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2019/12/10.
//

import Foundation
import MailSDK
import Swinject
import EENavigator
import RxSwift
import LarkContainer
#if MessengerMod
import LarkMessengerInterface
import LarkCore
#endif

final class MailForwardProvider: MailForwardProxy {
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func forwardImage(
        _ image: UIImage,
        needFilterExternal: Bool,
        from: NavigatorFrom,
        shouldDismissFromVC: Bool,
        cancelCallBack: (() -> Void)?,
        forwardResultCallBack: @escaping ((MailAttachmentForwardResult?) -> Void)
    ) {
#if MessengerMod
        var body = ShareImageBody(image: image,
                                  type: .forward,
                                  needFilterExternal: needFilterExternal,
                                  cancelCallBack: cancelCallBack)
        body.forwardResultsCallBack = { res in
            guard let res = res else {
                let error = LarkMailShareError(message: "no share result")
                forwardResultCallBack((nil, error))
                return
            }
            switch res {
            case .success(let res):
                let items = res.forwardItems.map {
                    MailForwardItemParam(isSuccess: $0.isSuccess, type: $0.type,
                                         name: $0.name ?? "", chatID: $0.chatID,
                                         isCrossTenant: $0.isCrossTenant ?? false)
                }
                forwardResultCallBack((items, nil))
            case .failure(let error):
                forwardResultCallBack((nil, error))
            }
        }
        if shouldDismissFromVC {
            /// 从编辑器 present 需要特殊处理
            let resource = resolver.navigator.response(for: body).resource
            guard let shareVC = (resource as? UINavigationController)?.viewControllers[0] else { return }
            resolver.navigator.push(shareVC, from: from, animated: true, completion: nil)
        } else {
            resolver.navigator.present(body: body, from: from, animated: true)
        }
#endif
    }
}

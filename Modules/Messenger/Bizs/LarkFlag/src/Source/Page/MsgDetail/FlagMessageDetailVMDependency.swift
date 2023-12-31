//
//  FlagMessageDetailVMDependency.swift
//  LarkChat
//
//  Created by 袁平 on 2021/6/22.
//

import Foundation
import LarkContainer
import TangramService
import RxSwift
import RustPB
import LarkModel
import LarkCore
import LarkMessengerInterface

final class FlagMessageDetailVMDependency: UserResolverWrapper {

    var userResolver: UserResolver
    var urlPreviewAPI: URLPreviewAPI?
    var chatSecurityControlService: ChatSecurityControlService?

    func getMessagePreviews(messagePreviewMap: [String: Im_V1_GetMessagePreviewsRequest.PreviewPair]) -> Observable<
        (InlinePreviewEntityPair?, URLPreviewEntityPair?, [String: MessageLink])
    > {
        return urlPreviewAPI?.getMessagePreviews(messagePreviewMap: messagePreviewMap, syncDataStrategy: .tryLocal).map { inlinePair, urlPreviewPair, messageLinkPB in
            var messageLinks: [String: MessageLink] = [:]
            messageLinkPB.forEach { (previewID, messageLink) in
                messageLinks[previewID] = MessageLink.transform(previewID: previewID, messageLink: messageLink)
            }
            return (inlinePair, urlPreviewPair, messageLinks)
        } ?? Observable.just((nil, nil, [:]))
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.urlPreviewAPI = try? userResolver.resolve(assert: URLPreviewAPI.self)
        self.chatSecurityControlService = try? userResolver.resolve(assert: ChatSecurityControlService.self)
    }
}

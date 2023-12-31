//
//  ChatTranslationDetailHandler.swift
//  LarkMessageCore
//
//  Created by bytedance on 3/31/22.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import Swinject
import LarkNavigator

public final class ChatTranslationDetailHandler: UserTypedRouterHandler {
    public func handle(_ body: ChatTranslationDetailBody, req: Request, res: Response) throws {
        let vm = ChatTranslationDetailViewModel(chat: body.chat,
                                                title: body.title,
                                                content: body.content,
                                                attributes: body.attributes,
                                                imageAttachments: body.imageAttachments,
                                                videoAttachments: body.videoAttachments,
                                                useTranslationCallBack: body.useTranslationCallBack,
                                                userResolver: self.userResolver)
        let vc = ChatTranslationDetailViewController(viewModel: vm)
        res.end(resource: vc)
    }
}

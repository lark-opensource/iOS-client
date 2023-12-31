//
//  ForwardConfirmFooterGenerator.swift
//  LarkForward
//
//  Created by ByteDance on 2023/2/17.
//

import Foundation
import LarkModel
import LarkUIKit
import Swinject
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkSetting
import LarkContainer

/// 用来生成相应的ForwardConfirmFooter，后续Footer生成逻辑往这里收
public final class ForwardConfirmFooterGenerator {

    private let userResolver: UserResolver

    public init(userResolver: UserResolver) { self.userResolver = userResolver }

    public func generatorThreadDetailConfirmFooter(message: Message?) -> BaseTapForwardConfirmFooter {
        let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
        let mergeForwardContentService = try? userResolver.resolve(assert: MergeForwardContentService.self)
        let chatType = chatAPI?.getLocalChat(by: message?.channel.id ?? "")?.type
        let posterName = mergeForwardContentService?.getPosterNameFromMessage(message, chatType) ?? ""
        let previewFg = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core_forward_content_preview"))
        return ForwardThreadDetailConfirmFooter(posterName: posterName, previewFg: previewFg)
    }
}

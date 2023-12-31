//
//  ChatContainerViewModel.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/7/15.
//

import UIKit
import Foundation
import LarkContainer
import LarkAppLinkSDK
import LarkWaterMark
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import LarkModel
import LarkCore

final class ChatContainerViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    @ScopedInjectedLazy var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy var byteViewService: ChatByteViewDependency?
    @ScopedInjectedLazy var userRelationService: UserRelationService?
    @ScopedInjectedLazy var waterMarkService: WaterMarkService?
    lazy var currentAccountChatterId = userResolver.userID

    func getWaterMarkImage() -> Observable<UIView?> {
        guard let waterMarkService = waterMarkService else { return .just(nil) }
        // 如果是 AI 会话，在没有开启全局水印的情况下，强制开启水印
        if chat.isP2PAi, userResolver.fg.dynamicFeatureGatingValue(with: "admin_security_myai_watermark") {
            return waterMarkService.globalWaterMarkIsShow.flatMap({ isShown -> Observable<UIView?> in
                isShown ? .just(nil) : waterMarkService.defaultObviousWaterMarkView.map { view in view }
            })
        }
        // 如果是跨租户会话，在没有开启全局水印的情况下，强制开启水印
        // TODO: 判断逻辑应该从 LarkWaterMark 基础组件里移出，放在此处
        return waterMarkService.getWaterMarkImageByChatId(self.chat.id, fillColor: nil)
    }

    var chat: Chat {
        return self.chatWrapper.chat.value
    }
    let chatWrapper: ChatPushWrapper

    fileprivate let disposeBag = DisposeBag()

    init(userResolver: UserResolver, chatWrapper: ChatPushWrapper) {
        self.userResolver = userResolver
        self.chatWrapper = chatWrapper
    }

    deinit {
        print("NewChat: ChatContainerViewModel deinit")
    }
}

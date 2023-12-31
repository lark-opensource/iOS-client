//
//  ExportChatMembersAbility.swift
//  LarkCore
//
//  Created by ByteDance on 2023/9/25.
//

import Foundation
import LarkModel
import LarkSDKInterface
import RxSwift
import LarkSetting
import RustPB

public protocol ExportChatMembersAbility {
    var chat: Chat { get }
    var chatAPI: ChatAPI { get }
    var currentUserId: String { get }
    func fetchExportMembersPermission(fg: FeatureGatingService) -> Observable<Bool>
    func exportMembers(delay: Double, showLoadingIn: UIView?, loadingText: String?) -> Observable<Void>
}

public extension ExportChatMembersAbility {
    func fetchExportMembersPermission(fg: FeatureGatingService) -> Observable<Bool> {
        guard fg.dynamicFeatureGatingValue(with: "im.chat.group_member_export.client") else {
            return .empty()
        }
        guard (self.chat.ownerId == currentUserId || self.chat.isGroupAdmin), !self.chat.isCrypto else {
            return .empty()
        }
        return self.chatAPI.getChatSwitch(chatId: self.chat.id,
                                          actionTypes: [.exportChatChatterBitable],
                                          formServer: true)
        .map { result in
            return result[Im_V1_ChatSwitchRequest.ActionType.exportChatChatterBitable.rawValue] ?? false
        }
    }

    func exportMembers(delay: Double, showLoadingIn: UIView?, loadingText: String?) -> Observable<Void> {
        return DelayLoadingObservableWraper.wraper(observable: self.chatAPI.exportChatMemebers(chatId: self.chat.id),
                                            delay: delay,
                                            showLoadingIn: showLoadingIn,
                                            loadingText: loadingText)
    }
}

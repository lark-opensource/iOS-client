//
//  ChatService.swift
//  LarkSDKInterface
//
//  Created by zc09v on 2018/6/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public protocol ChatService {
    func createP2PChat(userId: String, isCrypto: Bool, chatSource: CreateChatSource?) -> Observable<Chat>
    func createP2PChat(userId: String, isCrypto: Bool, isPrivateMode: Bool, chatSource: CreateChatSource?) -> Observable<Chat>
    // swiftlint:disable function_parameter_count
    func createGroupChat(name: String,
                         desc: String,
                         chatIds: [String],
                         departmentIds: [String],
                         userIds: [String],
                         fromChatId: String,
                         messageIds: [String],
                         messageId2Permissions: [String: RustPB.Im_V1_CreateChatRequest.DocPermissions],
                         linkPageURL: String?,
                         isCrypto: Bool,
                         isPublic: Bool,
                         isPrivateMode: Bool,
                         chatMode: Chat.ChatMode) -> Observable<CreateChatResult>
    // swiftlint:enable function_parameter_count
    func createDepartmentGroupChat(departmentId: String) -> Observable<Chat>

    func getCustomerServiceChat() -> Observable<Chat?>

    func disbandGroup(chatId: String) -> Observable<Chat>
}

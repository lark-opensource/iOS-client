//
//  UserViewModelContext.swift
//  ByteViewMessenger
//
//  Created by kiri on 2023/6/30.
//

import Foundation
import LarkMessageBase
import LarkContainer
import ByteViewNetwork
import LarkSDKInterface
import ByteViewSetting

protocol UserViewModelContext: ViewModelContext {
    var userResolver: UserResolver { get }
}

extension UserViewModelContext {
    var userId: String {
        userResolver.userID
    }

    var account: AccountInfo? {
        try? userResolver.resolve(assert: AccountInfo.self)
    }

    var chatterAPI: ChatterAPI? {
        try? userResolver.resolve(assert: ChatterAPI.self)
    }

    func isMe(_ chatterId: String) -> Bool {
        self.userId == chatterId
    }

    var setting: UserSettingManager? {
        try? userResolver.resolve(assert: UserSettingManager.self)
    }

    var httpClient: HttpClient? {
        try? userResolver.resolve(assert: HttpClient.self)
    }

    var dependency: ByteViewMessengerDependency? {
        try? userResolver.resolve(assert: ByteViewMessengerDependency.self)
    }

    func isMe(chatterId: String, deviceId: String?) -> Bool {
        if self.userId == chatterId {
            if let deviceId = deviceId {
                return account?.deviceId == deviceId
            } else {
                return true
            }
        } else {
            return false
        }
    }
}

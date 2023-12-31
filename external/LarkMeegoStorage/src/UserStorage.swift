//
//  UserStorage.swift
//  LarkMeegoStorage
//
//  Created by shizhengyu on 2023/3/15.
//

import Foundation
import meego_rust_ios
import LarkFoundation

open class UserStorage {
    public var userDb: ThreadSafeLazy<MeegoDb?>

    public let userId: String

    public init(associatedUserId: String) {
        userId = associatedUserId
        userDb = ThreadSafeLazy<MeegoDb?>(value: {
            return try? rustGetMeegoDb(scope: .user(associatedUserId))
        })
    }
}

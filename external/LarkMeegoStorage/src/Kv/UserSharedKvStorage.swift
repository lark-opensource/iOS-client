//
//  UserSharedKvStorage.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/2/23.
//

import Foundation
import RxSwift
import meego_rust_ios
import LarkAccountInterface
import LarkFoundation

/// [用户态] 读写操作关联 rust kv table，domain 为 'rust_kv'
/// Note：会有 file io，但内部复用连接池
open class UserSharedKvStorage: UserStorage, SharedKvStorage {
    open var database: meego_rust_ios.MeegoDb? {
        return userDb.wrappedValue
    }

    open var keyProcessor: KeyProcessor? {
        return { $0 }
    }

    open var domain: String {
        return "rust_kv"
    }
}

/// [用户态] 读写操作关联 rust kv table，domain 为 'rust_sp'
/// Note：
/// 1. 基于性能考虑，目前 userSp 仍然会读取 global db，在 key 拼接上 userid 作为 prefix
/// 2. 首次加载会 load to memory，后续读写不直接触发 file io，定时同步到磁盘，类似 UserDefault
open class UserSharedSpStorage: SharedKvStorage {
    public let associatedUserId: String
    public var globalDb: ThreadSafeLazy<MeegoDb?>

    public init(associatedUserId: String) {
        self.associatedUserId = associatedUserId
        globalDb = ThreadSafeLazy<MeegoDb?>(value: {
            return try? rustGetMeegoDb(scope: .global)
        })
    }

    open var database: meego_rust_ios.MeegoDb? {
        return globalDb.wrappedValue
    }

    open var keyProcessor: KeyProcessor? {
        return { "\(self.associatedUserId)|\($0)" }
    }

    open var domain: String {
        return "rust_sp"
    }
}

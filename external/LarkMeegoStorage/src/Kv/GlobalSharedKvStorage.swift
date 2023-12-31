//
//  GlobalSharedStorage.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/2/25.
//

import Foundation
import meego_rust_ios
import LarkFoundation

/// [全局态] 读写操作关联 rust kv table，domain 为 'rust_kv'
/// Note：会有 file io，但内部复用连接池
open class GlobalSharedKvStorage: SharedKvStorage {
    public static let shared = GlobalSharedKvStorage()

    public var globalDb: ThreadSafeLazy<MeegoDb?>

    public init() {
        globalDb = ThreadSafeLazy<MeegoDb?>(value: {
            return try? rustGetMeegoDb(scope: .global)
        })
    }

    open var domain: String {
        return "rust_kv"
    }

    open var database: meego_rust_ios.MeegoDb? {
        return globalDb.wrappedValue
    }

    open var keyProcessor: KeyProcessor? {
        return { $0 }
    }
}

/// [全局态] 读写操作关联 rust kv table，domain 为 'rust_sp'
/// Note：首次加载会 load to memory，后续读写不直接触发 file io，类似 userDefault
/// TODO：目前简单实现，除 domain 不同外，其他功能与 UserSharedKvStorage 一致
open class GlobalSharedSpStorage: SharedKvStorage {
    public static let shared = GlobalSharedSpStorage()

    public var globalDb: ThreadSafeLazy<MeegoDb?>

    public init() {
        globalDb = ThreadSafeLazy<MeegoDb?>(value: {
            return try? rustGetMeegoDb(scope: .global)
        })
    }

    open var domain: String {
        return "rust_sp"
    }

    open var database: meego_rust_ios.MeegoDb? {
        return globalDb.wrappedValue
    }

    open var keyProcessor: KeyProcessor? {
        return { "global|\($0)" }
    }
}

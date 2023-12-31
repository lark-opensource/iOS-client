//
//  DemoCache.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/11.
//

import Foundation
import SwiftProtobuf
import RustPB
import LarkStorage

typealias Chatter = Basic_V1_Chatter

class DemoCache {
    static let shared = DemoCache()
    private let accountIdKey = "ByteViewDemo.account"
    private let chattersKey = "ByteViewDemo.chatters"
    let storage = KVStores.udkv(space: .global, domain: Domain.biz.byteView.child("Demo"), mode: .normal)

    private init() {
        accountId = storage.string(forKey: accountIdKey) ?? ""
        if let datas: [Data] = storage.value(forKey: chattersKey) {
            var options = BinaryDecodingOptions()
            options.discardUnknownFields = true
            chatters = datas.compactMap { try? Chatter(serializedData: $0, options: options) }
        } else {
            chatters = []
        }
    }

    func bool(forKey key: String) -> Bool {
        return storage.bool(forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        storage.set(value, forKey: key)
    }

    func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    var accountId: String? {
        didSet {
            if accountId != oldValue {
                if let id = accountId, !id.isEmpty {
                    storage.set(id, forKey: accountIdKey)
                } else {
                    storage.removeValue(forKey: accountIdKey)
                }
            }
        }
    }

    var chatters: [Chatter] = [] {
        didSet {
            if oldValue != chatters {
                let datas = chatters.compactMap({ try? $0.serializedData() })
                storage.set(datas, forKey: chattersKey)
            }
        }
    }
}

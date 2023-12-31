//
//  KVStore.swift
//  LarkFinance
//
//  Created by 李晨 on 2020/10/28.
//

import Foundation
import LarkStorage
import LarkAccountInterface

struct KVStore {
    private static let financeDomain = Domain.biz.messenger.child("Finance")

    static func userStore(userID: String) -> LarkStorage.KVStore {
        return KVStores.udkv(space: .user(id: userID), domain: financeDomain)
    }
}

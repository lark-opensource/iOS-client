//
//  MomentsKeyValueStorage.swift
//  Moment
//
//  Created by liluobin on 2023/9/20.
//

import UIKit
import LarkStorage
import LarkContainer

protocol MomentsKeyValueStorageService {
    var userStore: KVStore { get }
}

class MomentsKeyValueStorageIMP: MomentsKeyValueStorageService, UserResolverWrapper {

    let userStore: KVStore

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        userStore = KVStores.udkv(
            space: .user(id: userResolver.userID),
            domain: Domain.biz.messenger.child("moments")
        )
    }
}

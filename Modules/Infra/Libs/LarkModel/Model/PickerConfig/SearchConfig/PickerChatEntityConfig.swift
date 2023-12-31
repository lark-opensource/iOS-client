//
//  PickerChatEntityConfig.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/29.
//

import Foundation

public extension PickerConfig {
    struct ChatEntityConfig: GroupChatEntityConfigType, OwnerConfigurable, TenantConfigurable,
                             ChatJoinConfigurable, ShieldConfigurable, FrozenConfigurable,
                             PickerChatFieldConfigurable, Codable {
        public var type: SearchEntityType = .chat
        public var tenant: TenantCondition = .inner
        public var join: JoinCondition = .joined
        public var owner: OwnerCondition = .all
        public var publicType: PublicTypeCondition = .all
        public var shield: ShieldCondition = .noShield
        public var frozen: FrozenCondition = .noFrozened
        public var crypto: CryptoCondition = .normal
        public var searchByUser: ChatSearchByUserCondition = .all
        public var field: PickerConfig.ChatField?

        public init(tenant: TenantCondition = .inner,
                    join: JoinCondition = .joined,
                    owner: OwnerCondition = .all,
                    publicType: PublicTypeCondition = .all,
                    shield: ShieldCondition = .noShield,
                    frozen: FrozenCondition = .noFrozened,
                    crypto: CryptoCondition = .normal,
                    searchByUser: ChatSearchByUserCondition = .all,
                    field: PickerConfig.ChatField? = nil) {
            self.tenant = tenant
            self.join = join
            self.owner = owner
            self.publicType = publicType
            self.shield = shield
            self.frozen = frozen
            self.crypto = crypto
            self.searchByUser = searchByUser
            self.field = field
        }
    }
}

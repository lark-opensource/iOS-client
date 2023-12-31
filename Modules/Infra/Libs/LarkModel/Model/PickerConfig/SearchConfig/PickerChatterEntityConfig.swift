//
//  PickerChatterEntityConfig.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/29.
//

import Foundation

public extension PickerConfig {
    struct ChatterEntityConfig: ChatterEntityConfigType,
                                TenantConfigurable,
                                TalkConfigurable,
                                ResignConfigurable,
                                PickerChatterFieldConfigurable,
                                Codable {

        public var type: SearchEntityType = .chatter
        public var tenant: TenantCondition = .inner
        public var talk: TalkCondition = .talked
        public var resign: ResignCondition = .unresigned
        public var externalFriend: ExternalFriendCondition = .all
        public var existsEnterpriseEmail: ExistsEnterpriseEmailCondition = .all
        public var field: PickerConfig.ChatterField?

        public init(tenant: TenantCondition = .inner,
                    talk: TalkCondition = .talked,
                    resign: ResignCondition = .unresigned,
                    externalFriend: ExternalFriendCondition = .all,
                    existsEnterpriseEmail: ExistsEnterpriseEmailCondition = .all,
                    field: PickerConfig.ChatterField? = nil) {
            self.tenant = tenant
            self.talk = talk
            self.resign = resign
            self.externalFriend = externalFriend
            self.existsEnterpriseEmail = existsEnterpriseEmail
            self.field = field
        }
    }
}

//
//  LarkModelExtension.swift
//  LarkCore
//
//  Created by zc09v on 2018/7/31.
//

import Foundation
import LarkModel
import LarkUIKit
import LarkSDKInterface

public extension Chatter {
    var sortIndexName: String {
        let language = BundleI18n.currentLanguage
        let isChinese = (language == .zh_CN || language == .zh_HK || language == .zh_TW)
        return isChinese ? self.namePinyin : self.localizedName
    }
}

public func isCustomer(tenantId: String) -> Bool {
    return tenantId == "0"
}

public extension Chat {
    var displayName: String {
        if let user = self.chatter {
            return user.displayName
        }
        if self.isMeeting && self.name.isEmpty {
            return BundleI18n.LarkCore.Lark_Legacy_EventNoTitle
        }
        return self.name
    }

    var displayWithAnotherName: String {
        if let user = self.chatter {
            return user.displayWithAnotherName
        }
        if self.isMeeting && self.name.isEmpty {
            return BundleI18n.LarkCore.Lark_Legacy_EventNoTitle
        }
        return self.name
    }

    var localizedName: String {
        if let user = self.chatter {
            return user.localizedName
        }
        if self.isMeeting && self.name.isEmpty {
            return BundleI18n.LarkCore.Lark_Legacy_EventNoTitle
        }
        return self.name
    }

    var displayAvatar: Image {
        if let user = self.chatter {
            return user.avatar.thumbnail
        }
        return avatar
    }
}

extension LarkSDKInterface.MobileCode {
    public var displayName: String {
        return BundleI18n.currentLanguage == .zh_CN ? self.name : (!self.enName.isEmpty ? self.enName : self.name)
    }
}

extension ContactSummary {
    public var displayName: String {
        return self.localName.isEmpty ? self.userName : self.localName
    }
}

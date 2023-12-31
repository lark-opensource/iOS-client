//
//  SearchFilterType.swift
//  LarkSearchFilter
//
//  Created by SuPeng on 9/12/19.
//

import Foundation
import LarkModel
import LarkSDKInterface
import RustPB

public extension ChatFilterType {
    var name: String {
        switch self {
        case .outer:
            return BundleI18n.LarkSearchFilter.Lark_Search_GroupTypeExternalGroup
        case .private:
            return BundleI18n.LarkSearchFilter.Lark_Search_GroupTypePrivateGroup
        case .publicAbsent:
            return BundleI18n.LarkSearchFilter.Lark_Search_GroupTypeUnjoinedPublicGroup
        case .publicJoin:
            return BundleI18n.LarkSearchFilter.Lark_Search_GroupTypeJoinedPublicGroup
        case .unknowntab:
            return ""
        @unknown default:
            assert(false, "new value")
            return ""
        }
    }
}

public extension MessageFilterType {
    var name: String {
        switch self {
        case .all:
            return BundleI18n.LarkSearchFilter.Lark_Legacy_MessageFragmentTitle
        case .file:
            return BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
        case .link:
            return BundleI18n.LarkSearchFilter.Lark_Search_Link
        @unknown default:
            assert(false, "new value")
            return ""
        }
    }
}

public extension MessageAttachmentFilterType {
    var name: String {
        switch self {
        case .unknownAttachmentType:
            return BundleI18n.LarkSearchFilter.Lark_MessageSearch_TypeOfMessage
        case .attachmentLink:
            return BundleI18n.LarkSearchFilter.Lark_Search_Link
        case .attachmentFile:
            return BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
        case .attachmentImage:
            return BundleI18n.LarkSearchFilter.Lark_Search_Image
        case .attachmentVideo:
            return BundleI18n.LarkSearchFilter.Lark_Search_Video
        @unknown default:
            assert(false, "new value")
            return ""
        }
    }
}

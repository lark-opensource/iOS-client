//
//  PickerItemMeta.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/15.
//

import Foundation
import RustPB

extension PickerItem {
    public enum Meta {
        case chatter(PickerChatterMeta)
        case chat(PickerChatMeta)
        case userGroup(PickerUserGroupMeta)
        case doc(PickerDocMeta)
        case wiki(PickerWikiMeta)
        case wikiSpace(PickerWikiSpaceMeta)
        case mailUser(PickerMailUserMeta)
        case unknown

        public var type: MetaType {
            switch self {
            case .chatter(_):
                return .chatter
            case .chat(_):
                return .chat
            case .userGroup(_):
                return .userGroup
            case .doc(_):
                return .doc
            case .wiki(_):
                return .wiki
            case .wikiSpace(_):
                return .wikiSpace
            case .mailUser(_):
                return .mailUser
            default:
                return .unknown
            }
        }
    }

    public enum MetaType: String, Codable {
        case chatter
        case chat
        case userGroup
        case doc
        case wiki
        case wikiSpace
        case mailUser
        case unknown
    }
}

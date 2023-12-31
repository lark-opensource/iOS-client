//
//  SearchedGroup.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/6.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

struct SearchedGroup: Equatable {
    let id: String
    let name: String
    let numberOfMembers: Int
    let avatarInfo: AvatarInfo
    let isCrossTenant: Bool
    let description: String
    let relationTagWhenRing: CollaborationRelationTag?
}

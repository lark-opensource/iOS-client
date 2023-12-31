//
//  Group.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/8/14.
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

    init(id: String,
         name: String,
         numberOfMembers: Int,
         avatarInfo: AvatarInfo,
         description: String,
         isCrossTenant: Bool,
         relationTagWhenRing: CollaborationRelationTag?) {
        self.id = id
        self.name = name
        self.numberOfMembers = numberOfMembers
        self.avatarInfo = avatarInfo
        self.isCrossTenant = isCrossTenant
        self.description = description
        self.relationTagWhenRing = relationTagWhenRing
    }
}

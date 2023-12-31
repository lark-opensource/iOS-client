//
//  MentionItemNode.swift
//  Pods
//
//  Created by Yuri on 2023/1/5.
//

import Foundation
import UIKit
import RustPB

struct MentionItemNode {
    enum Avatar {
        case remote(String, String)
        case local(UIImage)
        case none
    }
    
    var id: String
    /// 是否打开选中
    var isMultiSelected: Bool = false
    var isSkeleton: Bool = false
    var isSelected: Bool = false
    var avatar: Avatar
    
    var name: NSAttributedString?
    var subTitle: NSAttributedString?
    var desc: NSAttributedString?
    var focusStatus: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?
    
    var tags: [PickerOptionTagType]?
    var tagData: Basic_V1_TagData?
    
    init(item: IMMentionOptionType, isMultiSelected: Bool = false, isSkeleton: Bool = false) {
        id = item.id ?? ""
        name = item.name
        subTitle = item.subTitle
        desc = item.desc
        self.focusStatus = item.focusStatus
        self.tags = item.tags
        self.tagData = item.tagData
        
        self.isMultiSelected = isMultiSelected
        self.isSelected = item.isMultipleSelected
        self.isSkeleton = isSkeleton
        
        if item.id == IMPickerOption.allId {
            self.avatar = .local(UIImage(named: "atAll", in: BundleConfig.LarkIMMentionBundle, compatibleWith: nil) ?? UIImage())
        } else if case .wiki(let meta) = item.meta {
            avatar = .local(meta.image)
        } else if case .doc(let meta) = item.meta {
            avatar = .local(meta.image)
        } else if let id = item.avatarID, let key = item.avatarKey {
            avatar = .remote(id, key)
        } else {
            avatar = .none
        }
    }
}

//
//  MailGroupInfoBase.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/19.
//

import UIKit
import Foundation
import LarkUIKit
import RustPB
import LarkTag

typealias MailGroupInfoAvatarEditHandler = () -> Void
typealias MailGroupInfoTapHandler = (_ cell: UITableViewCell) -> Void

enum GroupInfoItemType {
    case name
    case member
    case whoCanSend
    case remark
}

protocol GroupInfoCellItem {
    var type: GroupInfoItemType { get }
}

struct GroupInfoSectionModel {
    var title: String?
    var items: [GroupInfoCellItem]

    @inline(__always)
    var numberOfRows: Int { items.count }

    @inline(__always)
    func item(at row: Int) -> GroupInfoCellItem? {
        _fastPath(row < numberOfRows) ? items[row] : nil
    }
}

protocol GroupInfoMemberItem {
    var itemId: String { get }
    var itemAvatarKey: String { get }
    var itemName: String { get }
    var avatarImage: UIImage? { get }
    var itemTags: [Tag]? { get }
}

extension GroupInfoMemberItem {
    var itemTags: [Tag]? { nil }
}

// type Cell mapper
extension GroupInfoCellItem {
    var cellIdentifier: String {
        var id = ""
        switch type {
        case .name: id = MailGroupInfoNameCell.lu.reuseIdentifier
        case .member: id = MailGroupInfoMemberCell.lu.reuseIdentifier
        case .whoCanSend, .remark: id = MailGroupInfoCommonCell.lu.reuseIdentifier
        }
        return id
    }
}

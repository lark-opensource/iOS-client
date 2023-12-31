//
//  OrganizableTasklistViewData.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/23.
//

import Foundation
import UniverseDesignFont
import LarkDocsIcon
import LarkContainer

struct OrganizableTasklistItemData {
    // 清单iconbuidler
    var leadingIconBuilder: LarkDocsIcon.IconBuilder?

    var userResolver: LarkContainer.UserResolver?

    var title: String?

    var userInfo: OrganizableTasklistUserData?

    var sectionInfos: OrganizableTasklistSectionData?

    var tailingIcon: UIImage?

    var identifier: String = ""

    struct Config {
        static let userIconSize = CGSize(width: 20.0, height: 20.0)
        static let itemSpace = 8.0
        static let dividingLineWidth = 1.0
        static let iconSize = CGSize(width: 24.0, height: 24.0)
        static let iconContentSpace = 12.0
        static let padding = 16.0
        static let collectionViewPadding = 12.0
        static let cornerRadius = 8.0
        static let tailingIconSize = CGSize(width: 20.0, height: 20.0)
        static let userFont = UDFont.systemFont(ofSize: 14.0)
        static let userIconTextSpace = 4.0
        static let userPadding = 2.0
    }

}

struct OrganizableTasklistUserData {

    var avatar: AvatarSeed?

    var name: String?

    // 最大为内容的宽度的一半
    var preferredMaxLayoutWidth: CGFloat = 0

}

struct OrganizableTasklistSectionData {

    var names: [String]?

    var preferredMaxLayoutWidth: CGFloat = 0

    var isValid: Bool {
        guard let names = names, !names.isEmpty else {
            return false
        }
        return true
    }
}

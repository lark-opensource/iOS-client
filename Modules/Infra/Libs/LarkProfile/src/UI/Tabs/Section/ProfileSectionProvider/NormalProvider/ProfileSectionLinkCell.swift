//
//  ProfileSectionLinkCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2022/1/5.
//

import Foundation
import UIKit
import UniverseDesignColor

public struct ProfileSectionLinkCellItem: ProfileSectionCellItem {
    public var title: String = ""
    public var subTitle: String = ""
    public var content: String = ""
    public var showPushIcon: Bool = false
    public var pushLink: String = ""

    public init(title: String = "",
                subTitle: String = "",
                content: String = "",
                pushLink: String = "") {
        self.title = title
        self.subTitle = subTitle
        self.content = content
        self.pushLink = pushLink
    }
}

public final class ProfileSectionLinkCell: ProfileSectionNormalCell {
    override func layoutView() {
        guard let item = item else {
            return
        }

        super.layoutView()
        self.contentLabel.textColor = item.pushLink.isEmpty ? UIColor.ud.textPlaceholder : UIColor.ud.textLinkNormal
    }
}

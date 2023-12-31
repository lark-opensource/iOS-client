//
//  ProfileSectionTitleCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2022/1/5.
//

import Foundation
import UIKit
import UniverseDesignColor
import EENavigator

public struct ProfileSectionTitleCellItem: ProfileSectionCellItem {
    public var title: String = ""
    public var subTitle: String = ""
    public var content: String = ""
    public var showPushIcon: Bool = false
    public var pushLink: String = ""

    public init(title: String = "",
                content: String = "",
                showPushIcon: Bool = false,
                pushLink: String = "") {
        self.title = title
        self.content = content
        self.showPushIcon = showPushIcon
        self.pushLink = pushLink
    }
}

public final class ProfileSectionTitleCell: ProfileSectionNormalCell {
    public weak var fromVC: UIViewController?

    override func commonInit() {
        super.commonInit()
        self.contentWrapperView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapContent)))
    }

    override func layoutView() {
        super.layoutView()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        self.contentLabel.numberOfLines = 1

        self.updateSeparatorLine()
    }

    public override func didTap(_ fromVC: UIViewController) {}

    @objc
    private func tapContent() {
        guard let item = item, let url = try? URL.forceCreateURL(string: item.pushLink), let fromVC = fromVC else {
            return
        }

        self.navigator?.push(url, from: fromVC)
    }
}

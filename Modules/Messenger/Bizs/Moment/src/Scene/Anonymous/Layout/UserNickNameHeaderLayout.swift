//
//  UserNickNameHeaderLayout.swift
//  Moment
//
//  Created by liluobin on 2021/5/24.
//

import Foundation
import UIKit

final class UserNickNameHeaderLayout {
    static let iconHeight: CGFloat = 72
    static let iconTopSpace: CGFloat = 40
    static let titleTopSpace: CGFloat = 12
    static let lineViewTopSpace: CGFloat = 38
    static let lineViewHeight: CGFloat = 8
    static let tipLabelTopSpace: CGFloat = 16
    static let tipLabelBottomSpace: CGFloat = 16
    static let titleFont = UIFont.systemFont(ofSize: 17, weight: .medium)
    static let tipFont = UIFont.systemFont(ofSize: 14)
    let tipStr: String = BundleI18n.Moment.Lark_Community_NicknameOnceAYearDesc
    var titleHeight: CGFloat = 0
    var tipHeight: CGFloat = 0
    let maxWidth: CGFloat
    let defaultTitle = BundleI18n.Moment.Lark_Community_SelectNicknameDesc
    var title: String? {
        didSet {
            if title != oldValue {
                titleHeight = MomentsDataConverter.heightForString(title ?? defaultTitle, onWidth: maxWidth, font: Self.titleFont)
            }
        }
    }
    init(maxWidth: CGFloat) {
        self.maxWidth = maxWidth
        titleHeight = MomentsDataConverter.heightForString(title ?? defaultTitle, onWidth: maxWidth, font: Self.titleFont)
        tipHeight = MomentsDataConverter.heightForString(tipStr, onWidth: maxWidth, font: Self.tipFont)
    }
    var suggestHeight: CGFloat {
        return Self.iconHeight + Self.iconTopSpace + Self.titleTopSpace + titleHeight + Self.lineViewTopSpace + Self.lineViewHeight + Self.tipLabelTopSpace + tipHeight + Self.tipLabelBottomSpace
    }
}

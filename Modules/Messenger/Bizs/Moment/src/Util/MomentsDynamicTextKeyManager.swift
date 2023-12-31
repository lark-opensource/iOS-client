//
//  MomentsDynamicTextKeyManager.swift
//  Moment
//
//  Created by liluobin on 2023/4/17.
//

import UIKit

enum TextKeyType {
  case removedFromHomepage
  case onlyAuthorCanView
  case onlyAuthorCanViewDesc
  case onlyTheAuthorIsVisible
}

class MomentsDynamicTextKeyManager {

    static func textForKeyType(_ type: TextKeyType, isRecommend: Bool) -> String {
        switch type {
        case .removedFromHomepage:
            return BundleI18n.Moment.Lark_Moments_RemovedFromHomepageForYou_Toast(Self.montageText(isRecommend: isRecommend))
        case .onlyAuthorCanView:
            return BundleI18n.Moment.Lark_Community_OnlyAuthorCanView_HomepageForYou_Title(Self.montageText(isRecommend: isRecommend))
        case .onlyAuthorCanViewDesc:
            return BundleI18n.Moment.Lark_Moments_OnlyAuthorCanView_HomepageForYou_Desc(Self.montageText(isRecommend: isRecommend))
        case .onlyTheAuthorIsVisible:
            return BundleI18n.Moment.Lark_Community_OnlyTheAuthorIsVisible_HomepageForYou_DropdownList(Self.montageText(isRecommend: isRecommend))
        }
    }

    private static func montageText(isRecommend: Bool) -> String {
        return isRecommend ? BundleI18n.Moment.Lark_Moments_ForYou : BundleI18n.Moment.Lark_Moments_Homepage
    }
}

//  SearchRecommandCellPrensentable.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/12.
//

import UIKit
import Foundation
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import LarkAppLinkSDK
import LarkSearchCore
import RustPB
import RxSwift
import LarkAlertController
import LarkMessengerInterface
import LarkFeatureGating

protocol SearchCellPresentable: AnyObject {}

protocol UniversalRecommendCellPresentable: SearchCellPresentable {}

protocol UniversalRecommendListCellPresentable: SearchCellViewModel {}

enum UniversalRecommendChipItemContent {
    case history(UniversalRecommendSearchHistory)
    case hotword(UniversalRecommendHotword)
}

protocol UniversalRecommendChipItem {
    var title: String { get }
    var iconStyle: UniversalRecommend.IconStyle { get }
    var content: UniversalRecommendChipItemContent { get }
}

protocol UniversalRecommendChipCellPresentable: UniversalRecommendCellPresentable {
    var items: [UniversalRecommendChipItem] { get }
    var foldType: UniversalRecommendChipCell.FoldType { get }
    var didSelectItem: ((Int) -> Void)? { get set }// (index)
    var didSelectFold: ((Bool) -> Void)? { get set } // (currentIsFold)
    var sectionWidth: (() -> CGFloat?)? { get set }
}

protocol UniversalRecommendCardItem {
    var avatarId: String { get }
    var avatarKey: String { get }
    var title: String { get }
}

protocol UniversalRecommendCardCellPresentable: UniversalRecommendCellPresentable {
    var items: [UniversalRecommendResult] { get }
    var totalItems: Int { get }
    var iconStyle: UniversalRecommend.IconStyle { get }
    var didSelectItem: ((Int) -> Void)? { get set } // (index)
}

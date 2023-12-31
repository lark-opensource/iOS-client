//
//  MomentsMenuManager.swift
//  Moment
//
//  Created by liluobin on 2021/1/12.
//

import Foundation
import UIKit
import UniverseDesignIcon
import LarkUIKit

enum MomentsPopOverMenuActionType {
    /// 删除
    case delete
    /// 举报
    case report
    /// 仅作者可见
    case setVisible(isRecommend: Bool)
    /// 置顶
    case boardcast(boardcasting: Bool)
    /// 编辑置顶
    case editBoardcast
    /// 拷贝帖子link
    case copyLink
    /// 翻译
    case translate
    /// 隐藏翻译
    case hideTranslation
    /// 显示原文（点击效果和隐藏翻译一样，icon和title不一样）
    case showSourceText
    /// 修改翻译语言
    case changeTranslationLanguage

}

final class MomentsPopOverMenuManager {

    static func showMenuVCWith(presentVC: UIViewController,
                               pointView: UIView,
                               itemTypes: [MomentsPopOverMenuActionType],
                               itemSelectedCallBack: ((MomentsPopOverMenuActionType) -> Void)?) {
        if itemTypes.isEmpty {
            return
        }
        let items = menuItemsWithActionTypes(types: itemTypes,
                                             callBack: itemSelectedCallBack)
        let vc = FloatMenuOperationController(pointView: pointView,
                                              bgMaskColor: UIColor.ud.bgMask,
                                              menuShadowType: nil,
                                              items: items)
        vc.modalPresentationStyle = .overFullScreen
        presentVC.present(vc, animated: false, completion: nil)
    }

    static func menuItemsWithActionTypes(types: [MomentsPopOverMenuActionType],
                                         callBack: ((MomentsPopOverMenuActionType) -> Void)?) -> [FloatMenuItemInfo] {
        var items: [FloatMenuItemInfo] = []
        for type in types {
            switch type {
            case .translate:
                items.append(
                    FloatMenuItemInfo(icon: UDIcon.translateOutlined,
                                      title: BundleI18n.Moment.Moments_Translate_Button_Mobile,
                                      acionFunc: {
                                        callBack?(type)
                                     }
                    )
                )
            case .hideTranslation:
                items.append(
                    FloatMenuItemInfo(icon: UDIcon.visibleLockOutlined,
                                     title: BundleI18n.Moment.Moments_HideTranslatedText_Button_Mobile,
                                     acionFunc: {
                                        callBack?(type)
                                     }
                    )
                )
            case .showSourceText:
                items.append(
                    FloatMenuItemInfo(icon: UDIcon.translateOutlined,
                                     title: BundleI18n.Moment.Moments_ShowSourceText_Button_Mobile,
                                     acionFunc: {
                                        callBack?(type)
                                     }
                    )
                )
            case .changeTranslationLanguage:
                items.append(
                    FloatMenuItemInfo(icon: UDIcon.transSwitchOutlined,
                                     title: BundleI18n.Moment.Moments_SwitchLanguages_Button_Mobile,
                                     acionFunc: {
                                        callBack?(type)
                                     }
                    )
                )
            case .delete:
                items.append(
                    FloatMenuItemInfo(
                        icon: Resources.popOverMenuDeleteTrash,
                        title: BundleI18n.Moment.Lark_Community_Delete,
                        acionFunc: {
                            callBack?(.delete)
                        }
                    )
                )
            case .report:
                let icon = Resources.popOverMenuAlarm
                items.append(
                    FloatMenuItemInfo(
                        icon: icon,
                        title: BundleI18n.Moment.Lark_Community_Report,
                        acionFunc: {
                            callBack?(type)
                        }
                    )
                )
            case .setVisible(isRecommend: let isRecommend):
                items.append(
                    FloatMenuItemInfo(
                        icon: Resources.postJustAutherSee,
                        title: MomentsDynamicTextKeyManager.textForKeyType(.onlyTheAuthorIsVisible, isRecommend: isRecommend),
                        acionFunc: {
                            callBack?(type)
                        }
                    )
                )
            case .boardcast(boardcasting: let boardcasting):
                let image = boardcasting ? Resources.cancelBoardcast : Resources.boardcast
                let title = boardcasting ? BundleI18n.Moment.Lark_Moments_RemoveFromTrending_Option : BundleI18n.Moment.Lark_Moments_PinToTrending_Option
                items.append(
                    FloatMenuItemInfo(icon: image,
                                 title: title,
                                 acionFunc: {
                                    callBack?(type)
                                 }
                    )
                )
            case .editBoardcast:
                items.append(
                    FloatMenuItemInfo(icon: Resources.editBoardcast,
                                 title: BundleI18n.Moment.Lark_Moments__EditTrendingPost_Option,
                                 acionFunc: {
                                    callBack?(type)
                                 }
                    )
                )
            case .copyLink:
                items.append(
                    FloatMenuItemInfo(icon: Resources.momentsSharePostLink,
                                 title: BundleI18n.Moment.Lark_Community_CopyLink,
                                 acionFunc: {
                                    callBack?(type)
                                 }
                    )
                )
            }
        }
        return items
    }

}

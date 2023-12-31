//
//  MessageBurnKeyboard.swift
//  LarkKeyboardView
//
//  Created by ByteDance on 2023/2/28.
//

import UIKit
import LarkModel
import LarkActionSheet
import EENavigator
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignActionPanel
import LarkKeyboardView

extension LarkKeyboard {
    public static func buildBurnTime(tintColor: UIColor,
                                     targetViewController: UIViewController?,
                                     canChangeTime:  @escaping () -> Bool,
                                     currenBurnLife: @escaping () -> Int64,
                                     willShowBurnTimeSelectSheet: @escaping () -> UIView?,
                                     selectedNewBurnLife: @escaping (Int64) -> Void) -> InputKeyboardItem {
        let (burnNormal, burnHighlight) = BurnTimeProps.getBurnTimeIcon(currenBurnLife(),
                                                                        tintColor: tintColor)
        let item = InputKeyboardItem(key: KeyboardItemKey.burnTime.rawValue, keyboardViewBlock: { () -> UIView in
            return UIView()
        }, keyboardHeightBlock: { 0 }, keyboardIcon: (burnNormal, burnHighlight, nil)) { [weak targetViewController] in
            let currenBurnLife = currenBurnLife()
            guard canChangeTime() else {
                let timeString = BurnTimeProps.getTimeDescrption(currenBurnLife)
                UDToast.showTips(with: BundleI18n.LarkBaseKeyboard.Lark_IM_NewMessagesWillSelfDestructInAPeriod_Server_Text(period: timeString), on: targetViewController?.view ?? UIView())
                return false
            }
            let sourceView = willShowBurnTimeSelectSheet()
            guard let sourceView = sourceView, let targetViewController = targetViewController else {
                return false
            }
            let popSource = UDActionSheetSource(sourceView: sourceView,
                                                sourceRect: sourceView.bounds)
            let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: popSource))

            actionSheet.setTitle(BundleI18n.LarkBaseKeyboard.Lark_IM_SelfDestructTimer_Hover)

            for props in BurnTimeProps.createBurnTimeSource(currenBurnLife, tintColor: tintColor) {
                actionSheet.addItem(UDActionSheetItem(title: props.title, titleColor: props.isSelected ? UIColor.ud.textLinkHover : UIColor.ud.textTitle, action: {
                    selectedNewBurnLife(props.time)
                }))
            }
            /// cancel
            actionSheet.setCancelItem(text: BundleI18n.LarkBaseKeyboard.Lark_Legacy_Cancel)
            Navigator.shared.present(actionSheet, from: targetViewController)
            return false
        }
        return item
    }
}

public struct BurnTimeProps {
    var time: Int64
    var title: String
    var icon: (UIImage?, UIImage?)
    var isSelected: Bool

    public static func createBurnTimeSource(_ burnLife: Int64, tintColor: UIColor?) -> [BurnTimeProps] {
        let burnLife = Int64(burnLife)
        let icon = Self.getBurnTimeIcon(burnLife, tintColor: tintColor ?? UIColor.ud.N500)
        let sources: [BurnTimeProps] = [
            /// 1m
            BurnTimeProps(
                time: RestrictedModeMessageBurnTime.minutes_1,
                title: Self.getTimeDescrption(RestrictedModeMessageBurnTime.minutes_1),
                icon: icon,
                isSelected: (RestrictedModeMessageBurnTime.minutes_1 == burnLife)
            ),
            /// 1h
            BurnTimeProps(
                time: RestrictedModeMessageBurnTime.hours_1,
                title: Self.getTimeDescrption(RestrictedModeMessageBurnTime.hours_1),
                icon: icon,
                isSelected: (RestrictedModeMessageBurnTime.hours_1 == burnLife)
            ),
            /// 1d
            BurnTimeProps(
                time: RestrictedModeMessageBurnTime.day_1,
                title: Self.getTimeDescrption(RestrictedModeMessageBurnTime.day_1),
                icon: icon,
                isSelected: (RestrictedModeMessageBurnTime.day_1 == burnLife)
            ),
            /// 1w
            BurnTimeProps(
                time: RestrictedModeMessageBurnTime.week_1,
                title: Self.getTimeDescrption(RestrictedModeMessageBurnTime.week_1),
                icon: icon,
                isSelected: (RestrictedModeMessageBurnTime.week_1 == burnLife)
            ),
            BurnTimeProps(
                time: RestrictedModeMessageBurnTime.month_1,
                title: Self.getTimeDescrption(RestrictedModeMessageBurnTime.month_1),
                icon: icon,
                isSelected: (RestrictedModeMessageBurnTime.month_1 == burnLife)
            )
        ]
        return sources
    }

    public static func getBurnTimeIcon(_ burnLife: Int64, tintColor: UIColor) -> (UIImage?, UIImage?) {
        let burnLife = Int64(burnLife)
        var normal: UIImage?
        var select: UIImage?

        if burnLife == RestrictedModeMessageBurnTime.minutes_1 {
            normal = UDIcon.burnlifeMinuteOutlined
            select = UDIcon.burnlifeMinuteOutlined
        } else if burnLife == RestrictedModeMessageBurnTime.hours_1 {
            normal = UDIcon.burnlifeHourOutlined
            select = UDIcon.burnlifeHourOutlined
        } else if burnLife == RestrictedModeMessageBurnTime.day_1 {
            normal = UDIcon.burnlifeDayOutlined
            select = UDIcon.burnlifeDayOutlined
        } else if burnLife == RestrictedModeMessageBurnTime.week_1 {
            normal = UDIcon.burnlifeWeekOutlined
            select = UDIcon.burnlifeWeekOutlined
        } else if burnLife == RestrictedModeMessageBurnTime.month_1 {
            normal = UDIcon.burnlifeMonthOutlined
            select = UDIcon.burnlifeMonthOutlined
        } else {
            return (nil, nil)
        }
        return (normal?.ud.withTintColor(tintColor), select?.ud.withTintColor(UIColor.ud.colorfulBlue))
    }

    public static func getTimeDescrption(_ burnLife: Int64) -> String {
        if burnLife == RestrictedModeMessageBurnTime.minutes_1 {
            return BundleI18n.LarkBaseKeyboard.Lark_IM_MessageSelfDestruct_1min_Option
        } else if burnLife == RestrictedModeMessageBurnTime.hours_1 {
            return BundleI18n.LarkBaseKeyboard.Lark_IM_MessageSelfDestruct_1hour_Option
        } else if burnLife == RestrictedModeMessageBurnTime.day_1 {
            return BundleI18n.LarkBaseKeyboard.Lark_IM_MessageSelfDestruct_1day_Option
        } else if burnLife == RestrictedModeMessageBurnTime.week_1 {
            return BundleI18n.LarkBaseKeyboard.Lark_IM_MessageSelfDestruct_1week_Option
        } else if burnLife == RestrictedModeMessageBurnTime.month_1 {
            return BundleI18n.LarkBaseKeyboard.Lark_IM_MessageSelfDestruct_1month_Option
        }
        return ""
    }
}

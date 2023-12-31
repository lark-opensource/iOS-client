//
//  SkinColorHelper.swift
//  Calendar
//
//  Created by zhouyuan on 2019/1/28.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

// 颜色组 属性根据业务场景区分，calendar 共 12 组
struct ColorGroup {
    let background: (accept: UIColor, tentative: UIColor)
    let text: (accept: UIColor, needAction: UIColor)
    /// 特指前景色，背景统一为 bgBody
    let foreBar: (accept: UIColor, tentative: UIColor)
    let stripe: UIColor
    let border: UIColor

    init(background: (accept: UIColor, tentative: UIColor),
         text: (accept: UIColor, needAction: UIColor),
         foreBar: (accept: UIColor, tentative: UIColor),
         stripe: UIColor, border: UIColor) {
        self.background = background
        self.text = text
        self.stripe = stripe
        self.foreBar = foreBar
        self.border = border
    }
}

struct InstanceInfo {
    let selfStatus: CalendarEventAttendee.Status
    let eventColorIndex: ColorIndex
    let calColorIndex: ColorIndex

    init(selfStatus: CalendarEventAttendee.Status, eventColorIndex: ColorIndex, calColorIndex: ColorIndex) {
        self.selfStatus = selfStatus
        self.eventColorIndex = eventColorIndex
        self.calColorIndex = calColorIndex
    }

    init(from ins: CalendarEventInstanceEntity) {
        selfStatus = ins.selfAttendeeStatus
        let isThirdPartyType = ins.isGoogleEvent() || ins.isExchangeEvent()
        let isUseCalColorIndex = Self.isUseCalColorIndex(accessRole: ins.calAccessRole, isThirdPartyType: isThirdPartyType)
        eventColorIndex = isUseCalColorIndex ? ins.calColor : ins.eventColor
        calColorIndex = ins.calColor
    }

    init(from ins: Instance) {
        selfStatus = ins.selfAttendeeStatus
        let isUseCalColorIndex = Self.isUseCalColorIndex(accessRole: ins.calAccessRole, isThirdPartyType: ins.isThirdPartyType)
        eventColorIndex = isUseCalColorIndex ? ins.calColor : ins.eventColor
        calColorIndex = ins.calColor
    }
    
    init(from model: TimeBlockModel) {
        selfStatus = .accept
        eventColorIndex = model.colorIndex ?? .green
        calColorIndex = model.colorIndex ?? .green
    }

    static private func isUseCalColorIndex(accessRole: AccessRole, isThirdPartyType: Bool) -> Bool {
        let isLimitAceessRole = accessRole == .freeBusyReader || accessRole == .unknownAccessRole
        return isLimitAceessRole || isThirdPartyType
    }
}

struct SkinColorHelper {
    private static let DeclineColorGroup = (background: UIColor.ud.N100, indicator: UIColor.ud.N400, text: UIColor.ud.textPlaceholder)

    let skinType: CalendarSkinType
    let insInfo: InstanceInfo

    var maskOpacity: Float {
        return skinType == .light ? 0.55 : 0.5
    }

    static func pickerColor(of index: Int) -> UIColor {
        guard let color = Self.colorsForPicker[safeIndex: index] else { return .ud.udtokenColorpickerCarmine }
        return color
    }
}

// MARK: - 大搜关键词高亮
extension SkinColorHelper {
    var highLightColor: UIColor { eventTextColor.withAlphaComponent(0.25) }
}

// MARK: - 列表视图「dot」& 月视图「block」
extension SkinColorHelper {
    var dotColor: UIColor { Self.pickerColor(of: insInfo.eventColorIndex.rawValue) }
}

// MARK: - 日程块背景颜色
extension SkinColorHelper {
    var backgroundColor: UIColor {
        switch insInfo.selfStatus {
        case .accept:
            return eventColorGroup.background.accept
        case .decline:
            return Self.DeclineColorGroup.background
        case .tentative:
            return eventColorGroup.background.tentative
        case .needsAction:
            // needAction 应取 stripe 字段，这里的值不应该被应用
            return eventColorGroup.stripe
        default:
            return eventColorGroup.background.accept
        }
    }
}

// MARK: 三方日程类型 icon 颜色
extension SkinColorHelper {
    private static let cornerFlagAlpha: CGFloat = 0.2
    var typeIconTintColor: UIColor {
        if insInfo.selfStatus == .decline {
            return Self.DeclineColorGroup.text.withAlphaComponent(Self.cornerFlagAlpha)
        }
        return eventTextColor.withAlphaComponent(Self.cornerFlagAlpha)
    }
}

// MARK: - 字体颜色
extension SkinColorHelper {
    var eventTextColor: UIColor {
        switch insInfo.selfStatus {
        case .accept, .tentative:
            return eventColorGroup.text.accept
        case .needsAction:
            return eventColorGroup.text.needAction
        case .decline:
            return Self.DeclineColorGroup.text
        default:
            assertionFailureLog()
            return eventColorGroup.text.accept
        }
    }
}

// MARK: 描边颜色 & 小竖线颜色
extension SkinColorHelper {
    var dashedBorderColor: UIColor? {
        guard insInfo.selfStatus == .needsAction else { return nil }
        return eventColorGroup.border
    }

    var indicatorInfo: (color: UIColor, isStripe: Bool)? {
        switch insInfo.selfStatus {
        case .accept:
            return (calColorGroup.foreBar.accept, false)
        case .decline:
            return (Self.DeclineColorGroup.indicator, false)
        case .tentative:
            return (calColorGroup.foreBar.tentative, true)
        default:
            return nil
        }
    }
}

// MARK: - 斜条纹相关
extension SkinColorHelper {
    typealias StripeColors = (foreground: UIColor, background: UIColor)

    var stripeColor: StripeColors? {
        guard insInfo.selfStatus == .needsAction else { return nil }
        // 条纹背景色与各场景背景色一致，直接在 view 层指定了，这里后续可以下掉 bgColor（borderColor 也一样）
        return (eventColorGroup.stripe, .ud.calEventViewBg)
    }
}

extension SkinColorHelper {
    private var calColorGroup: ColorGroup {
        if skinType == .light {
            if let colors = Self.colorsGroupModern[insInfo.calColorIndex] {
                return colors
            } else {
                let modernDefault = ColorGroup(
                    background: (.ud.LightBgBlue, .ud.LightBgPendingBlue),
                    text: (.ud.LightTextBlue, .ud.LightTextUnansweredBlue),
                    foreBar: (.ud.LightBgBarBlue, .ud.LightBgBarBlue),
                    stripe: .ud.StripeBlue, border: .ud.BorderUnansweredBlue
                )
                return modernDefault
            }
        } else {
            if let colors = Self.colorsGroupClasic[insInfo.calColorIndex] {
                return colors
            } else {
                let classicDefault = ColorGroup(
                    background: (.ud.DarkBgBlue, .ud.DarkBgPendingBlue),
                    text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredBlue),
                    foreBar: (.ud.DarkBgBarBlue, .ud.DarkPendingBarBlue),
                    stripe: .ud.StripeBlue, border: .ud.BorderUnansweredBlue
                )
                return classicDefault
            }
        }
    }

    private var eventColorGroup: ColorGroup {
        if skinType == .light {
            if let colors = Self.colorsGroupModern[insInfo.eventColorIndex] {
                return colors
            } else {
                let modernDefault = ColorGroup(
                    background: (.ud.LightBgBlue, .ud.LightBgPendingBlue),
                    text: (.ud.LightTextBlue, .ud.LightTextUnansweredBlue),
                    foreBar: (.ud.LightBgBarBlue, .ud.LightBgBarBlue),
                    stripe: .ud.StripeBlue, border: .ud.BorderUnansweredBlue
                )
                return modernDefault
            }
        } else {
            if let colors = Self.colorsGroupClasic[insInfo.eventColorIndex] {
                return colors
            } else {
                let classicDefault = ColorGroup(
                    background: (.ud.DarkBgBlue, .ud.DarkBgPendingBlue),
                    text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredBlue),
                    foreBar: (.ud.DarkBgBarBlue, .ud.DarkPendingBarBlue),
                    stripe: .ud.StripeBlue, border: .ud.BorderUnansweredBlue
                )
                return classicDefault
            }
        }
    }
}

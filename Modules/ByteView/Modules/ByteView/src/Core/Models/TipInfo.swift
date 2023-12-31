//
//  TipInfo.swift
//  ByteView
//
//  Created by kiri on 2021/4/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork
import UIKit
import UniverseDesignNotice

/// - NOTE: 利用引用类型记录是否被用户关闭
class TipInfo: Equatable {
    typealias LinkTapAction = () -> Void
    typealias Alignment = UniverseDesignNotice.UDNoticeAlignment

    enum IconType {
        case info
        case warning
        case error
        case phone
    }

    var content: String
    let iconType: IconType
    var canClosedManually: Bool = true
    var hasBeenClosedManually: Bool = false
    let highLightRange: NSRange?
    let scheme: String?
    let linkTapAction: LinkTapAction?
    let alignment: Alignment?
    let type: VideoChatNotice.NoticeType
    let isFromNotice: Bool
    let timeout: TimeInterval // 展示timeout时长后才能被下发的dismissInfo关闭，单位秒；手动关闭、更新、覆盖不受影响
    var presentedTime: TimeInterval = 0 // 展示的时刻
    var digitRange: NSRange? // 数字采用特殊字体，保证等宽
    var noticeInfo: VideoChatNotice?
    var updateInfo: VideoChatNoticeUpdate?
    var canCover: Bool = true //能否被其他notice覆盖
    var key: String? // 区分tip info
    var operationButtonAction: (() -> Void)?
    var closeButtonAction: (() -> Void)?
    var autoDismissTime: TimeInterval {
        TimeInterval(noticeInfo?.tipsConfig.autoDismissTime ?? 0) / 1000
    }

    init(content: String,
         iconType: IconType = .info,
         type: VideoChatNotice.NoticeType = .other,
         isFromNotice: Bool,
         canCover: Bool = true,
         canClosedManually: Bool = true,
         highLightRange: NSRange? = nil,
         scheme: String? = nil,
         linkTapAction: LinkTapAction? = nil,
         alignment: Alignment? = nil,
         timeout: TimeInterval = 0,
         digitRange: NSRange? = nil,
         noticeInfo: VideoChatNotice? = nil,
         updateInfo: VideoChatNoticeUpdate? = nil,
         key: String? = nil) {
        self.content = content
        self.iconType = iconType
        self.type = type
        self.isFromNotice = isFromNotice
        self.canCover = canCover
        self.canClosedManually = canClosedManually
        self.highLightRange = highLightRange
        self.scheme = scheme
        self.linkTapAction = linkTapAction
        self.alignment = alignment
        self.timeout = timeout
        self.digitRange = digitRange
        self.noticeInfo = noticeInfo
        self.updateInfo = updateInfo
        self.key = key
    }

    static func == (lhs: TipInfo, rhs: TipInfo) -> Bool {
        if lhs.content == rhs.content {
            return true
        } else if lhs.type != .other, lhs.type == rhs.type {
            return true
        } else if lhs.key != nil, rhs.key != nil, lhs.key == rhs.key {
            return true
        }
        return false
    }

    var isDismissInfo: Bool {
        if let updateInfo = self.updateInfo {
            return updateInfo.action == .dismiss
        }
        return false
    }

    func isDismissInfo(of tipInfo: TipInfo?) -> Bool {
        guard let tipInfo = tipInfo else { return false }
        if let updateInfo = self.updateInfo,
           let noticeInfo = tipInfo.noticeInfo,
           updateInfo.key == noticeInfo.msgI18NKey?.newKey {
            return updateInfo.action == .dismiss
        }
        return false
    }

    // 目前仅会议超时tips有直接更新逻辑
    func isUpdateInfo(of tipInfo: TipInfo?) -> Bool {
        return type == .maxDurationLimit && type == tipInfo?.type
    }

    var icon: UIImage? {
        switch iconType {
        case .info:
            return Self.infoImg
        case .warning:
            return Self.warningImg
        case .error:
            return Self.errorImg
        case .phone:
            return Self.phoneImg
        }
    }

    static var infoImg = UDIcon.getIconByKey(.infoColorful, size: CGSize(width: 16, height: 16))
    static var warningImg = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 16, height: 16))
    static var errorImg = UDIcon.getIconByKey(.errorColorful, size: CGSize(width: 16, height: 16))
    static var phoneImg = UDIcon.getIconByKey(.callFilled, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 16, height: 16))

    var backgroundColor: UIColor? {
        // 超声波提示需求后统一修改为01色号
        switch iconType {
        case .info:
            return UIColor.ud.functionInfoFillSolid01
        case .warning:
            return UIColor.ud.functionWarningFillSolid01
        case .error:
            return UIColor.ud.functionDangerFillSolid01
        case .phone:
            return UIColor.ud.functionInfoFillSolid01
        }
    }

    func trackDisplayIfNeeded(isSuperAdministrator: Bool, isFirstPresent: Bool) {
        switch type {
        case .maxParticipantLimit:
            BillingTracks.trackDisplayParticipantLimitTip(isSuperAdministrator: isSuperAdministrator)
        case .maxDurationLimit:
            if isFirstPresent {
                BillingTracks.trackDisplayDurationLimitTip(type: "ten_minutes", isSuperAdministrator: isSuperAdministrator)
            }
        case .subtitleSettingJump:
            /// 字幕口说语言不一致的Tips提示
            SubtitleTracks.trackMismatchLanguageTip()
        default:
            break
        }
    }

    func trackClickIfNeeded(isSuperAdministrator: Bool) {
        switch type {
        case .maxParticipantLimit:
            BillingTracks.trackClickParticipantLimitTip(isSuperAdministrator: isSuperAdministrator)
        case .maxDurationLimit:
            BillingTracks.trackClickDurationLimitTip(isSuperAdministrator: isSuperAdministrator)
        default:
            break
        }
    }
}

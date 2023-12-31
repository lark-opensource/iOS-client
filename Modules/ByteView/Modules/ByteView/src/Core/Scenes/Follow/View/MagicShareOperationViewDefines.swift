//
//  MagicShareOperationViewDefines.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/9/21.
//

import Foundation

enum MoreSheetAction: Int {
    case refresh // = 0
    case copyLink
    case passOnSharing
    case takeControl
}

enum MSDisplayStyle: Int {
    case iPadRegular // = 0
    case iPadCompact
    case iPhonePortrait
    case iPhoneLandscape
}

enum MSShareStatus: Int {
    case sharing // = 0
    case following
    case free
    case shareScreenToFollow
}

struct MSOperationViewDisplayStyleParams: Equatable {

    let displayStyle: MSDisplayStyle
    let shareStatus: MSShareStatus

    /// 平铺/堆叠/沉浸状态
    let meetingLayoutStyle: MeetingLayoutStyle

    let hasMoreThanOneFile: Bool
    let isRemoteEqualLocal: Bool
    let canShowPassOnSharing: Bool
    let isGuest: Bool

    /// 是否在显示投屏转妙享“文档变化”提示
    let isContentChangeHintDisplaying: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.displayStyle == rhs.displayStyle
        && lhs.shareStatus == rhs.shareStatus
        && lhs.meetingLayoutStyle == rhs.meetingLayoutStyle
        && lhs.hasMoreThanOneFile == rhs.hasMoreThanOneFile
        && lhs.isRemoteEqualLocal == rhs.isRemoteEqualLocal
        && lhs.canShowPassOnSharing == rhs.canShowPassOnSharing
        && lhs.isGuest == rhs.isGuest
        && lhs.isContentChangeHintDisplaying == rhs.isContentChangeHintDisplaying
    }

    static let `default`: MSOperationViewDisplayStyleParams = .init(
        displayStyle: .iPhonePortrait,
        shareStatus: .sharing,
        meetingLayoutStyle: .fullscreen,
        hasMoreThanOneFile: false,
        isRemoteEqualLocal: true,
        canShowPassOnSharing: true,
        isGuest: true,
        isContentChangeHintDisplaying: false
    )
}

extension MagicShareOperationView {

    /// 当前视图的高度
    // disable-lint: magic number
    var operationViewHeight: CGFloat {
        let isSteepStyle: Bool = meetingLayoutStyle == .fullscreen
        let isPhone: Bool = Display.phone
        let isPortrait: Bool = isPhonePortrait
        switch (isSteepStyle, isPhone, isPortrait) {
        case (false, true, true): // iPhone非沉浸态竖屏
            return 40.0
        case (true, true, true): // iPhone沉浸态竖屏
            return (Display.phone && !Display.iPhoneXSeries) ? 32.0 : 52.0 // 非刘海屏手机特化显示
        case (false, true, false): // iPhone非沉浸态横屏
            return (Display.phone && !Display.iPhoneXSeries) ? 36.0 : 53.0
        case (true, true, false): // iPhone沉浸态横屏
            return 43.0
        case (false, false, _): // iPad非沉浸态
            return 32.0
        case (true, false, _): // iPad沉浸态
            return 34.0
        }
    }

    /// 文件名到视图顶部的距离
    var labelToTopOffset: CGFloat {
        let isSteepStyle: Bool = meetingLayoutStyle == .fullscreen
        let isPhone: Bool = Display.phone
        let isPortrait: Bool = isPhonePortrait
        switch (isSteepStyle, isPhone, isPortrait) {
        case (false, true, true): // iPhone非沉浸态竖屏
            return 11.0
        case (true, true, true): // iPhone沉浸态竖屏
            return (Display.phone && !Display.iPhoneXSeries) ? 7.0 : 10.0 // 非刘海屏手机特化显示
        case (false, true, false): // iPhone非沉浸态横屏
            return 9.0
        case (true, true, false): // iPhone沉浸态横屏
            return 4.0
        case (false, false, _): // iPad非沉浸态
            return 7.0
        case (true, false, _): // iPad沉浸态
            return 8.0
        }
    }
    // enable-lint: magic number

}

extension MSOperationViewDisplayStyleParams {
    /// 是否遵守沉浸模式布局
    var isSteepMode: Bool {
        switch meetingLayoutStyle {
        case .fullscreen:
            return true
        case .overlay, .tiled:
            return false
        }
    }
    var isSharing: Bool {
        return shareStatus == .sharing
    }
    var isFollowing: Bool {
        return shareStatus == .following
    }

    var showBackToLastFileButton: Bool {
        return !meetingLayoutStyle.onlyShowTitle && hasMoreThanOneFile
    }
    var showFreeToBrowseLabel: Bool {
        return !meetingLayoutStyle.onlyShowTitle && ((shareStatus == .free) || (shareStatus == .shareScreenToFollow && !isContentChangeHintDisplaying))
    }
    var showFileNameLabel: Bool {
        return !(shareStatus == .shareScreenToFollow && isContentChangeHintDisplaying)
    }
    var showPresenterChangedShareContentLabel: Bool {
        return shareStatus == .shareScreenToFollow && isContentChangeHintDisplaying
    }
    var showShareContentChangeHintBackgroundView: Bool {
        return shareStatus == .shareScreenToFollow && isContentChangeHintDisplaying
    }
    var showCopyAndRefreshButton: Bool {
        return !meetingLayoutStyle.onlyShowTitle && displayStyle == .iPadRegular
    }
    var showPlaceholderView: Bool {
        return !showCopyAndRefreshButton && displayStyle != .iPadCompact
    }
    var showMoreButton: Bool {
        return !meetingLayoutStyle.onlyShowTitle && displayStyle != .iPadRegular
    }
    var configShareControlButtonText: String {
        if shareStatus == .sharing {
            return I18n.View_VM_PassOnSharing
        } else {
            return I18n.View_VM_TakeOverSharingButton
        }
    }
    var showConfigShareControlButton: Bool {
        if meetingLayoutStyle.onlyShowTitle || shareStatus == .shareScreenToFollow {
            return false
        } else if [.iPadRegular, .iPhoneLandscape].contains(displayStyle) {
            if shareStatus == .sharing {
                return canShowPassOnSharing
            } else {
                return !isGuest
            }
        } else {
            return false
        }
    }
    var backToPresenterButtonText: String {
        if shareStatus == .shareScreenToFollow {
            return I18n.View_G_BackScreenShare_Button
        } else {
            return I18n.View_VM_FollowPersonSharing
        }
    }
    var showBackToPresenterButton: Bool {
        return !meetingLayoutStyle.onlyShowTitle && [.free, .shareScreenToFollow].contains(shareStatus)
    }
    var showSaperateLineView: Bool {
        return !meetingLayoutStyle.onlyShowTitle && shareStatus == .sharing && (showConfigShareControlButton || showMoreButton) && Display.pad
    }
    var showStopSharingButton: Bool {
        return !meetingLayoutStyle.onlyShowTitle && shareStatus == .sharing
    }
    var isCentralizedLayout: Bool {
        return [.iPadRegular, .iPadCompact, .iPhoneLandscape].contains(displayStyle)
    }

    // MARK: - StackView Spacing
    // disable-lint: magic number
    var spacingAfterBackToLastFileButton: CGFloat {
        switch (displayStyle, shareStatus == .shareScreenToFollow && isContentChangeHintDisplaying) {
        case (.iPadRegular, false), (.iPadCompact, true), (.iPhoneLandscape, true): return 12.0
        case (.iPadRegular, true): return 20.0
        default: return 8.0
        }
    }
    var spacingAfterFileNameLabel: CGFloat {
        switch displayStyle {
        case .iPadCompact: return 12.0
        case .iPadRegular: return 20.0
        default: return 0
        }
    }
    var spacingAfterSharerChangedContentLabel: CGFloat {
        switch displayStyle {
        case .iPadCompact: return 12.0
        case .iPadRegular: return 20.0
        default: return 0
        }
    }
    var spacingAfterCopyButton: CGFloat {
        switch displayStyle {
        case .iPadRegular: return 16.0
        default: return 0
        }
    }
    var spacingAfterRefreshButton: CGFloat {
        switch displayStyle {
        case .iPadRegular: return 20.0
        default: return 0
        }
    }
    // enable-lint: magic number
}

extension MeetingLayoutStyle {
    /// 是否只显示标题
    var onlyShowTitle: Bool {
        switch self {
        case .fullscreen:
            return true
        case .overlay, .tiled:
            return false
        }
    }
}

//
//  InMeetUserInfoDefines.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/9/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

// disable-lint: magic number
import Foundation

struct UserInfoComponents: OptionSet {
    let rawValue: Int
    static let identity = UserInfoComponents(rawValue: 1 << 0)
    static let mic = UserInfoComponents(rawValue: 1 << 1)
    static let sharing = UserInfoComponents(rawValue: 1 << 2)
    static let focus = UserInfoComponents(rawValue: 1 << 3)
    static let name = UserInfoComponents(rawValue: 1 << 4)
    // (me), (guest), (calling)
    static let nameDesc = UserInfoComponents(rawValue: 1 << 5)
    static let weakNetwork = UserInfoComponents(rawValue: 1 << 6)
    static let localRecord = UserInfoComponents(rawValue: 1 << 7)

    static let all: UserInfoComponents = [.identity, .mic, .sharing, .focus, .name, .nameDesc, .weakNetwork, .localRecord]
    static let allButIdentity: UserInfoComponents = [.mic, .sharing, .focus, .name, .nameDesc, .weakNetwork, .localRecord]
    static let nameAndMic: UserInfoComponents = [.mic, .name]
    static let floatingComponents: UserInfoComponents = [.mic, .sharing, .focus, .name, .weakNetwork, .localRecord]
}

struct UserInfoDisplayStyleParams: Equatable {
    /// 背景高度
    var fullHeight: CGFloat
    /// 文字高度
    var textHeight: CGFloat
    /// 字体大小
    var fontSize: CGFloat
    /// 身份左侧边距
    var identityLeftOffset: CGFloat
    /// 身份右侧边距
    var identityRightOffset: CGFloat
    /// 身份标签的最大宽度
    var identityMaxWidth: CGFloat
    /// 用户信息左边距
    var userInfoLeftOffset: CGFloat
    /// 用户信息右边距
    var userInfoRightOffset: CGFloat
    /// 图标边长
    var iconSideLength: CGFloat
    /// 一般圆角
    var cornerRadius: CGFloat
    /// 特殊处理圆角
    var specializedCornerRadius: CGFloat

    var layoutStyle: InMeetUserInfoView.LayoutStyle
    var isFillScreen = false

    // 是否 mobile 横屏模式且会中单人，不特化圆角
    var isMobileLandscapeSingle: Bool = false

    var components = UserInfoComponents.all

    var params: Self {
        self
    }
}

extension UserInfoDisplayStyleParams {
    /// 非共享宫格流
    static let inMeetingGrid = UserInfoDisplayStyleParams(
        fullHeight: 20.0,
        textHeight: 18.0,
        fontSize: 12.0,
        identityLeftOffset: 5.0,
        identityRightOffset: 4.0,
        identityMaxWidth: 25.0,
        userInfoLeftOffset: 4.0,
        userInfoRightOffset: 5.0,
        iconSideLength: 16.0,
        cornerRadius: 6.0,
        specializedCornerRadius: 6.0,
        layoutStyle: .left,
        components: UserInfoComponents.allButIdentity
    )
    /// iPhone小窗 / iPad-C视图
    static let floating: UserInfoDisplayStyleParams = {
        var params = UserInfoDisplayStyleParams(
            fullHeight: 16.0,
            textHeight: 13.0,
            fontSize: 10.0,
            identityLeftOffset: 0.0,
            identityRightOffset: 0.0,
            identityMaxWidth: 21.0,
            userInfoLeftOffset: 4.0,
            userInfoRightOffset: 4.0,
            iconSideLength: 14.0,
            cornerRadius: 6.0,
            specializedCornerRadius: 6.0,
            layoutStyle: .left,
            components: .floatingComponents
        )
        params.components = [.name, .weakNetwork, .mic]
        return params
    }()
    /// iPad-R视图 / iPad全屏
    static let floatingLarge: UserInfoDisplayStyleParams = {
        var params = UserInfoDisplayStyleParams(
            fullHeight: 20.0,
            textHeight: 18.0,
            fontSize: 12.0,
            identityLeftOffset: 5.0,
            identityRightOffset: 4.0,
            identityMaxWidth: 25.0,
            userInfoLeftOffset: 4.0,
            userInfoRightOffset: 5.0,
            iconSideLength: 16.0,
            cornerRadius: 6.0,
            specializedCornerRadius: 6.0,
            layoutStyle: .left,
            components: .floatingComponents
        )
        return params
    }()

    static let speechFloatingLarge: UserInfoDisplayStyleParams = {
        var params = floatingLarge
        params.components = .allButIdentity
        return params
    }()

    /// 共享宫格流
    static let singleRow = UserInfoDisplayStyleParams(
        fullHeight: 16.0,
        textHeight: 13.0,
        fontSize: 10.0,
        identityLeftOffset: 4.0,
        identityRightOffset: 3.0,
        identityMaxWidth: 21.0,
        userInfoLeftOffset: 4.0,
        userInfoRightOffset: 4.0,
        iconSideLength: 14.0,
        cornerRadius: Display.phone ? 5.0 : 6.0,
        specializedCornerRadius: Display.phone ? 7.0 : 6.0,
        layoutStyle: .left,
        components: UserInfoComponents.allButIdentity
    )
    /// 全屏（单流放大）
    static let fillScreen: UserInfoDisplayStyleParams = {
        var params = UserInfoDisplayStyleParams(fullHeight: 20.0,
                                                textHeight: 18.0,
                                                fontSize: 12.0,
                                                identityLeftOffset: 5.0,
                                                identityRightOffset: 4.0,
                                                identityMaxWidth: 25.0,
                                                userInfoLeftOffset: 4.0,
                                                userInfoRightOffset: 5.0,
                                                iconSideLength: 16.0,
                                                cornerRadius: 6.0,
                                                specializedCornerRadius: 6.0,
                                                layoutStyle: .center,
                                                components: UserInfoComponents.allButIdentity)
        params.isFillScreen = true
        return params
    }()
}

extension InMeetUserInfoView {

    typealias UserInfoDisplayStyle = UserInfoDisplayStyleParams
    /*
    enum UserInfoDisplayStyle {
        /// 会中非共享宫格流
        case inMeetingGrid
        /// iPhone小窗 / iPad-C视图
        case floating
        /// iPad-R视图 / iPad全屏
        case floatingLarge
        /// 会中共享宫格流
        case singleRow
        /// 全屏（单流放大）
        case fillScreen

        var params: UserInfoDisplayStyleParams {
            switch self {
            case .inMeetingGrid:
                return UserInfoDisplayStyleParams.inMeetingGrid
            case .floating:
                return UserInfoDisplayStyleParams.floating
            case .floatingLarge:
                return UserInfoDisplayStyleParams.floatingLarge
            case .singleRow:
                return UserInfoDisplayStyleParams.singleRow
            case .fillScreen:
                return UserInfoDisplayStyleParams.fillScreen
            }
        }

        var layoutStyle: LayoutStyle {
            switch self {
            case .fillScreen:
                return .center
            default:
                return .left
            }
        }

        var isSingleRow: Bool {
            return self == .singleRow
        }

        var isFillScreen: Bool {
            return self == .fillScreen
        }
    }
     */

    enum LayoutStyle: Equatable {
        case left
        case center
    }

    enum BgStyle: Equatable {
        case identity
        case userInfo
    }

}

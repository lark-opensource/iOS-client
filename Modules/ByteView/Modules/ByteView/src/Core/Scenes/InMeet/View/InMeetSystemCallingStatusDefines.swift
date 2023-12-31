//
//  InMeetSystemCallingStatusDefines.swift
//  ByteView
//
//  Created by ShuaiZipei on 2022/11/7.
//

import Foundation

struct SystemCallingStatusDisplayStyleParams {
    /// 字体大小
    let fontSize: CGFloat
    /// 图标边长
    let iconSideLength: CGFloat
    /// 图标与文字间距
    let gap: CGFloat
    /// 外框长
    let contentHeight: CGFloat
    /// 外框宽
    let contentWidth: CGFloat
}

// disable-lint: magic number
extension SystemCallingStatusDisplayStyleParams {
    /// .fillGrid .fillSquareGrid .halfGrid, .newHalfGrid .singleVideo
    static let systemCallingBigPhone = SystemCallingStatusDisplayStyleParams(
        fontSize: 16.0,
        iconSideLength: 38.0,
        gap: 4.0,
        contentHeight: 64,
        contentWidth: 128
    )
    /// .quaterGrid .thirdGrid, .sixthGrid
    static let systemCallingMidPhone = SystemCallingStatusDisplayStyleParams(
        fontSize: 14.0,
        iconSideLength: 24.0,
        gap: 4.0,
        contentHeight: 52,
        contentWidth: 112
    )
    /// .floating, .floatingLandscape,.singleRow, .singleRowSquare
    static let systemCallingSmallPhone = SystemCallingStatusDisplayStyleParams(
        fontSize: 0,
        iconSideLength: 24.0,
        gap: 0,
        contentHeight: 24,
        contentWidth: 24
    )
    /// .fillGrid .fillSquareGrid .halfGrid, .newHalfGrid .singleVideo
    static let systemCallingBigPad = SystemCallingStatusDisplayStyleParams(
        fontSize: 20.0,
        iconSideLength: 52.0,
        gap: 8.0,
        contentHeight: 88,
        contentWidth: 320
    )
    /// .quaterGrid .thirdGrid, .sixthGrid
    static let systemCallingMidPad = SystemCallingStatusDisplayStyleParams(
        fontSize: 17.0,
        iconSideLength: 38.0,
        gap: 8.0,
        contentHeight: 70,
        contentWidth: 250
    )
    /// .floatingSpeech,
    static let systemCallingSmallPad = SystemCallingStatusDisplayStyleParams(
        fontSize: 16,
        iconSideLength: 36.0,
        gap: 8,
        contentHeight: 88,
        contentWidth: 180
    )
    /// .singleRow, .singleRowSquare ,floatingLarge
    static let systemCallingSinglePad = SystemCallingStatusDisplayStyleParams(
        fontSize: 0,
        iconSideLength: 36.0,
        gap: 0,
        contentHeight: 36,
        contentWidth: 36
    )
}

extension InMeetSystemCallingStatusView {
    enum InMeetSystemCallingStatusDisplayStyle {
        /// 手机大图标
        case systemCallingBigPhone
        /// 手机中图标
        case systemCallingMidPhone
        /// 手机小图标
        case systemCallingSmallPhone
        /// pad大图标
        case systemCallingBigPad
        /// pad中图标
        case systemCallingMidPad
        /// pad小图标
        case systemCallingSmallPad
        /// padSingleVideo图标
        case systemCallingSinglePad

        var params: SystemCallingStatusDisplayStyleParams {
            switch self {
            case .systemCallingBigPhone:
                return SystemCallingStatusDisplayStyleParams.systemCallingBigPhone
            case .systemCallingMidPhone:
                return SystemCallingStatusDisplayStyleParams.systemCallingMidPhone
            case .systemCallingSmallPhone:
                return SystemCallingStatusDisplayStyleParams.systemCallingSmallPhone
            case .systemCallingBigPad:
                return SystemCallingStatusDisplayStyleParams.systemCallingBigPad
            case .systemCallingMidPad:
                return SystemCallingStatusDisplayStyleParams.systemCallingMidPad
            case .systemCallingSmallPad:
                return SystemCallingStatusDisplayStyleParams.systemCallingSmallPad
            case .systemCallingSinglePad:
                return SystemCallingStatusDisplayStyleParams.systemCallingSinglePad
            }
        }
    }
}

//
// Created by liujianlong on 2022/8/5.
//

import UIKit
import ByteViewSetting
import ByteViewRtcBridge

private typealias MultiResSubscribeResolutionInSetting = ByteViewSetting.MultiResSubscribeResolution
extension InMeetingCollectionViewSquareGridFlowLayout {
    static func makeMultiResSubConfig(cfgs: MultiResolutionConfig, viewCount: Int) -> MultiResSubscribeConfig {
        let viewSizeScale = cfgs.viewSizeScale
        let cfgs = cfgs.phone.subscribe
        var normalCfg: MultiResSubscribeResolutionInSetting
        var sipOrRoomCfg: MultiResSubscribeResolutionInSetting?
        var priority: MultiResSubscribeConfig.Priority
        var sipOrRoomPriority: MultiResSubscribeConfig.Priority?
        if viewCount <= 1 {
            normalCfg = cfgs.newGridFull
            priority = .high
        } else if viewCount <= 2 {
            normalCfg = cfgs.newGridHalf
            sipOrRoomCfg = cfgs.newGridHalfSip
            priority = .medium
        } else {
            normalCfg = cfgs.newGrid6
            sipOrRoomCfg = cfgs.newGrid6Sip
            priority = .low
            sipOrRoomPriority = .medium
        }
        return MultiResSubscribeConfig(normal: normalCfg.toRtc(),
                                       priority: priority,
                                       sipOrRoom: sipOrRoomCfg?.toRtc(),
                                       sipOrRoomPriority: sipOrRoomPriority,
                                       viewSizeScale: viewSizeScale)
    }
}


extension InMeetingLandscapeCollectionLayout {
    static func makeMultiResSubConfig(cfgs: MultiResolutionConfig, viewCount: Int) -> MultiResSubscribeConfig {
        let viewSizeScale = cfgs.viewSizeScale
        let cfgs = cfgs.phone.subscribe
        var normalCfg: MultiResSubscribeResolutionInSetting
        var sipOrRoomCfg: MultiResSubscribeResolutionInSetting?
        var priority: MultiResSubscribeConfig.Priority
        var sipOrRoomPriority: MultiResSubscribeConfig.Priority?

        if viewCount <= 1 {
            normalCfg = cfgs.gridFull
            priority = .high
        } else if viewCount <= 2 {
            normalCfg = cfgs.gridHalf
            sipOrRoomCfg = cfgs.gridHalfSip
            priority = .medium
        } else /* if viewCount <= 4 */ {
            normalCfg = cfgs.gridQuarter
            sipOrRoomCfg = cfgs.gridQuarterSip
            priority = .low
            sipOrRoomPriority = .medium
        }

        return MultiResSubscribeConfig(normal: normalCfg.toRtc(),
                                       priority: priority,
                                       sipOrRoom: sipOrRoomCfg?.toRtc(),
                                       sipOrRoomPriority: sipOrRoomPriority,
                                       viewSizeScale: viewSizeScale)
    }
}

extension InMeetingCollectionViewSingleRowLayout {
    static func makeMultiResSubConfig(cfgs: MultiResolutionConfig) -> MultiResSubscribeConfig {
        let viewSizeScale = cfgs.viewSizeScale
        var normalCfg: MultiResSubscribeResolutionInSetting
        var sipOrRoomCfg: MultiResSubscribeResolutionInSetting?
        var priority: MultiResSubscribeConfig.Priority
        var sipOrRoomPriority: MultiResSubscribeConfig.Priority?
        if Display.pad {
            let cfgs = cfgs.pad.subscribe
            normalCfg = cfgs.gridShareRow
            sipOrRoomCfg = cfgs.gridShareRowSip
        } else {
            let cfgs = cfgs.phone.subscribe
            normalCfg = cfgs.gridShareRow
            sipOrRoomCfg = cfgs.gridShareRowSip
        }
        priority = .low
        sipOrRoomPriority = .medium

        return MultiResSubscribeConfig(normal: normalCfg.toRtc(),
                                       priority: priority,
                                       sipOrRoom: sipOrRoomCfg?.toRtc(),
                                       sipOrRoomPriority: sipOrRoomPriority,
                                       viewSizeScale: viewSizeScale)
    }
}

extension InMeetingPadGridLayout {
    static func makeMultiResSubConfig(cfgs: MultiResolutionConfig, viewCount: Int) -> MultiResSubscribeConfig {
        // 具体规则见: https://bytedance.feishu.cn/docx/doxcnv3clUhI863PiBpQBoMYClb
        return matchGalleryRules(rules: cfgs.pad.subscribe.gallery, viewSizeScale: cfgs.viewSizeScale, viewCount: viewCount)
    }
}

func matchGalleryRules(rules: [MultiResPadGallerySubscribeRule], viewSizeScale: Float, viewCount: Int) -> MultiResSubscribeConfig {
    var normalCfg: MultiResSubscribeResolutionInSetting
    var sipOrRoomCfg: MultiResSubscribeResolutionInSetting?
    var priority: MultiResSubscribeConfig.Priority
    var sipOrRoomPriority: MultiResSubscribeConfig.Priority?

    let normalRule = rules.first(where: { $0.max >= viewCount && $0.roomOrSip == 0 })
    let sipOrRoomRule = rules.first(where: { $0.max >= viewCount && $0.roomOrSip != 0 })
    // nolint-next-line: magic number
    normalCfg = normalRule?.conf ?? rules.last { rule in rule.roomOrSip == 0 }?.conf ?? MultiResSubscribeResolution(res: 90, fps: 15, goodRes: 90, goodFps: 15, badRes: 90, badFps: 15)
    if let sipOrRoomRule = sipOrRoomRule {
        if let normalRule = normalRule,
           sipOrRoomRule.max <= normalRule.max {
            sipOrRoomCfg = sipOrRoomRule.conf
        } else if normalRule == nil {
            sipOrRoomCfg = sipOrRoomRule.conf
        }
    }
    priority = .low
    sipOrRoomPriority = .medium
    return MultiResSubscribeConfig(normal: normalCfg.toRtc(),
                                   priority: priority,
                                   sipOrRoom: sipOrRoomCfg?.toRtc(),
                                   sipOrRoomPriority: sipOrRoomPriority,
                                   viewSizeScale: viewSizeScale)
}

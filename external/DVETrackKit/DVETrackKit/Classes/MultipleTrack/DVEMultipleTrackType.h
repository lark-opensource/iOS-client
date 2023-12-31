//
//  DVEMultipleTrackType.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/13.
//

#ifndef DVEMultipleTrackType_h
#define DVEMultipleTrackType_h


typedef NS_ENUM(NSUInteger, DVEMultipleTrackType) {
    DVEMultipleTrackTypeNone,
    DVEMultipleTrackTypeAudio,
    DVEMultipleTrackTypeGlobalFilter,
    DVEMultipleTrackTypeEffect,
    DVEMultipleTrackTypeSticker,
    DVEMultipleTrackTypeTextSticker,
    DVEMultipleTrackTypeBlend,
    DVEMultipleTrackTypeAudioAndBlend,   // 音频和画中画
    DVEMultipleTrackTypeGlobalAdjust,
    DVEMultipleTrackTypeMain,///主轨道
};

#endif /* DVEMultipleTrackType_h */

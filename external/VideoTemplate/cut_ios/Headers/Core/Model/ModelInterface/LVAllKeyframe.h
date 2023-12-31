//
//  LVAllKeyframe.h
//  VideoTemplate
//
//  Created by iRo on 2020/6/9.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN
@class LVVEDataCache, IESMMALLKeyFrames;

@interface LVAllKeyframe : NSObject

@property (nonatomic, assign, readonly) CMTime time;

- (instancetype)initWithDraft:(LVMediaDraft *)draft
                        cache:(LVVEDataCache *)cache
                  allkeyFrame:(IESMMALLKeyFrames *)allkeyFrames
                          pts:(NSUInteger)pts;
@end

@interface LVAllKeyframe (VideoInterface)

/// 获取视频裁剪信息
- (LVSegmentClipInfo * _Nullable)videoClipInfoWithSegmentID:(NSString *)segmentID;

/// 获取视频蒙版信息
- (LVVideoMaskConfig * _Nullable)maskConfigWithSegmentID:(NSString *)segmentID;

/// 获取视频色度抠图信息
- (LVDraftChromaPayload * _Nullable)chromaWithSegmentID:(NSString *)segmentID;

/// 获取视频滤镜，调节强度
- (NSNumber * _Nullable)videoEffectValueWithSegmentID:(NSString *)segmentID
                                                 type:(LVPayloadRealType)type;

@end

@interface LVAllKeyframe (GlobalEffectInterface)
/// 获取全局滤镜，调节强度
- (NSNumber * _Nullable)globalEffectValueWithSegmentID:(NSString *)segmentID
                                                 type:(LVPayloadRealType)type;
@end

@interface LVAllKeyframe (InfoStickerInterface)
/// 获取信息化贴纸信息
- (LVTextKeyframe * _Nullable)infoStickerWithSegmentID:(NSString *)segmentID;

/// 获取输入框的size
- (NSValue * _Nullable)infoStickerSizeWithSegmentID:(NSString *)segmentID;

@end

NS_ASSUME_NONNULL_END

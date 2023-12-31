//
//  NLECover+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2021/7/1.
//

#import "NLETimeSpaceNode+iOS.h"
#import "NLETrack+iOS.h"
#import "NLEStyCanvas+iOS.h"
#import "NLEResourceNode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEVideoFrameModel_OC : NLETimeSpaceNode_OC

///封面编辑快照，一张图片；
@property (nonatomic, strong) NLEResourceNode_OC *snapshot;
///被编辑的基底，可以是：纯色 / 渐变色 / 图片 / 视频帧
@property (nonatomic, strong) NLEStyCanvas_OC *coverMaterial;
///当 NLEStyCanvasType == NLECanvasTypeVideoFrame 时，此字段才会生效，指定视频帧的时间戳
@property (nonatomic, assign) int64_t videoFrameTime;
///画布比例 默认 16:9（桌面端编辑器横屏的情况）；screen width / screen height；宽高比；
@property (nonatomic, assign) float canvasRatio;

- (NSArray<NLETrack_OC *> *)tracks;

- (void)addTrack:(NLETrack_OC *)track;

- (void)removeTrack:(NLETrack_OC *)track;

@end

NS_ASSUME_NONNULL_END

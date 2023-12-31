//
//  NLESegmentVideo+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/8.
//

#import "NLESegmentTransition+iOS.h"
#import "NLEStyCrop+iOS.h"
#import "NLEStyCanvas+iOS.h"
#import "NLEResourceAV+iOS.h"
#import "NLESegmentAudio+iOS.h"
#import "NLEStyClip+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentVideo_OC : NLESegmentAudio_OC

//视频裁剪后四个角的坐标
@property (nonatomic, strong) NLEStyCrop_OC *crop;

//视频裁剪后四个角坐标，crop不使用
@property (nonatomic, strong) NLEStyClip_OC *clip;

/// 画布参数
@property (nonatomic, strong, nullable) NLEStyCanvas_OC *canvasStyle;

/// 视频或图片资源
@property (nonatomic, strong) NLEResourceAV_OC *videoFile;

/// 混合模式资源，resourceFile为资源文件的绝对路径
@property (nonatomic, strong, nullable) NLEResourceNode_OC *blendFile;

/// 视频的不透明度，取值为0～1
@property (nonatomic, assign) CGFloat alpha;

- (bool)hasEnableAudio;

- (void)setEnableAudio:(bool)enableAudio;

/// 是否支持增量，属于后续计划的内容，暂时注释掉
//- (BOOL)isSupportIncrement:(NLESegmentVideo_OC *)other;

- (NLEResourceType)getType;

- (NLEResourceNode_OC *)getResNode;

@end


NS_ASSUME_NONNULL_END

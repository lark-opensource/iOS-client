//
//  NLEResourceAV+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/10.
//

#import "NLEResourceNode+iOS.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEResourceAV_OC : NLEResourceNode_OC
///时长
@property (nonatomic, assign) CMTime duration;
///宽度
@property (nonatomic, assign) uint32_t width;
///高度
@property (nonatomic, assign) uint32_t height;
///是否带音频

@property (nonatomic, copy  ) NSString *fileInfo;
///是否带音频
@property (nonatomic, assign) BOOL hasAudio;

@end

NS_ASSUME_NONNULL_END

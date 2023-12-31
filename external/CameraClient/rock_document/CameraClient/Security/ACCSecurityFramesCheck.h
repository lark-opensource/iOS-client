//
//  ACCSecurityFramesCheck.h
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/4/12.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCSecurityFramesCheck : NSObject

// 视频/图片的抽帧校验
+ (void)checkAssetFrames:(NSArray *)frames publishModel:(AWEVideoPublishViewModel *)publishModel;

// 绿幕道具抽帧校验
+ (void)checkPropsFrames:(NSArray *)frames publishModel:(AWEVideoPublishViewModel *)publishModel;

// 自定义贴纸抽帧校验
+ (void)checkCustomStickerFrames:(NSArray *)frames publishModel:(AWEVideoPublishViewModel *)publishModel;

// 走兜底逻辑校验
+ (void)checkExceptionForFallback:(BOOL)isFallback;

@end

NS_ASSUME_NONNULL_END

//
//  ACCCommonStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/8/3.
//

#import <CreativeKitSticker/ACCStickerConfig.h>
#import "ACCStickerBizDefines.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCommonStickerConfig : ACCStickerConfig

/*
 * @brief deafult is ACCStickerContainerFeatureReserved
 */
@property (nonatomic, assign) ACCStickerContainerFeature preferredContainerFeature;

@property (nonatomic, assign) ACCStickerGestureType supportedGestureType; //not fully support, only used in sharing a video as story.

@property (nonatomic, strong) NSValue *gestureInvalidFrameValue;

@property (nonatomic, copy) void (^isInDeleteStateCallback)(void);

@property (nonatomic, strong) NSNumber *editable; // default is NO;
@property (nonatomic, strong) NSNumber *deleteable; // default is YES;

@property (nonatomic, copy) void (^deleteAction)(void);
- (ACCStickerBubbleConfig *)deleteConfig;

- (BOOL)hasDeleteFeature;

@end

@interface ACCBaseStickerView (CommonStickerConfig)

- (ACCCommonStickerConfig *)bizStickerConfig;

@end

NS_ASSUME_NONNULL_END

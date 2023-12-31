//
//  ACCVideoEditStickerComponent.h
//  CameraClient
//
//  Created by liuqing on 2020/6/12.
//

#import <CreativeKit/ACCFeatureComponent.h>
#import "ACCEditStickerBizModule.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCStickerServiceImpl;
@interface ACCVideoEditStickerComponent : ACCFeatureComponent

#pragma mark - SubComponent Visible

- (void)clearAllEffectsAndStickers;
- (void)willEnterPublish;
@property (nonatomic, strong, readonly) ACCStickerServiceImpl *stickerService;
@property (nonatomic, strong, readonly) ACCEditStickerBizModule *stickerBizModule;

@end

NS_ASSUME_NONNULL_END

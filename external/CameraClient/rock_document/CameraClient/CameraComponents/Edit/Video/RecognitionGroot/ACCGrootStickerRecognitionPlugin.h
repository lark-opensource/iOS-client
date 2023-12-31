//
//  ACCGrootStickerRecognitionPlugin.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import <CreativeKit/ACCFeatureComponent.h>
#import <CreativeKit/ACCFeatureComponentPlugin.h>
#import <CreativeKit/ACCServiceBindable.h>

@class ACCGrootStickerHandler;
@class ACCGrootStickerView;
@class ACCGrootDetailsStickerModel;
@class ACCGrootStickerModel;
@class AWEInteractionStickerLocationModel;
@protocol ACCStickerPlayerApplying;
@class ACCGrootStickerViewModel;
@class ACCGrootStickerModel;

@protocol ACCGrootStickerInputDelegate <NSObject>

- (void)didMountGrootComponent:(nonnull ACCGrootStickerHandler *)stickerHandler viewModel:(nonnull ACCGrootStickerViewModel *)viewModel;

- (void)didUpdateStickerView:(nullable ACCGrootDetailsStickerModel *)stickerModel;

- (void)restoreStickerViewIfNeed:(nonnull ACCGrootStickerHandler *)stickerHandler stickerModel:(nullable ACCGrootStickerModel *)model;

- (nullable ACCGrootStickerView *)createRecognitionGrootStickerView:(nullable ACCGrootStickerModel *)model handler:(nullable ACCGrootStickerHandler *)handler;

- (void)confirm:(nullable ACCGrootStickerHandler *)handler;

@end

@interface ACCGrootStickerRecognitionPlugin : NSObject <ACCFeatureComponentPlugin, ACCServiceBindable>

+ (BOOL)serviceEnabled;

@end

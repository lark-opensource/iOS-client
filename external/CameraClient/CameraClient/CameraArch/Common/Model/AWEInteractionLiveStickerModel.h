//
//  AWEInteractionLiveStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/20.
//

#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCLiveStickerViewStatus) {
    ACCLiveStickerViewStatusDefault = 0, // Normal Status, >3d
    ACCLiveStickerViewStatusNearby = 1,  // Nearby, 15min - 3d
    ACCLiveStickerViewStatusLiving = 2,  // 15min - end
    ACCLiveStickerViewStatusEnd = 3,
    ACCLiveStickerViewStatusTimeout = 4
};

typedef NS_ENUM(NSInteger, ACCLiveStickerViewStyle) {
    ACCLiveStickerViewStyleDefault = 0,
    ACCLiveStickerViewStyleModern = 1,
    ACCLiveStickerViewStyleModernColorful = 2
};

@interface AWEInteractionLiveStickerInfoModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSTimeInterval targetTime;
@property (nonatomic, assign) ACCLiveStickerViewStatus status;
@property (nonatomic, assign) BOOL btnClicked;
@property (nonatomic, copy) NSNumber *roomID;

- (BOOL)liveTimeValid;
- (BOOL)showToSee;
- (NSString *)liveStatusStr;

@end

@interface AWEInteractionLiveStickerModel : AWEInteractionStickerModel

@property (nonatomic, strong) AWEInteractionLiveStickerInfoModel *liveInfo;

@property (nonatomic, assign) ACCLiveStickerViewStyle style;

@end

NS_ASSUME_NONNULL_END

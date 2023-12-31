//
//  ACCStickerMigrationProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2020/12/18.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPublishRepository;

typedef NS_ENUM(NSUInteger, ACCCrossPlatformStickerType);

typedef NS_ENUM(NSUInteger, ACCCrossPlatformAlignment) {
    ACCCrossPlatformAlignmentLeft = 0,
    ACCCrossPlatformAlignmentCenter,
    ACCCrossPlatformAlignmentRight,
    ACCCrossPlatformAlignmentTop,
    ACCCrossPlatformAlignmentBottom,
};

@class NLESegmentSticker_OC, NLETrackSlot_OC;

@protocol ACCCrossPlatformMigrateContext <NSObject>

@property (nonatomic, copy) NSString *resourcePath;

@property (nonatomic, assign) CGFloat transformX;
@property (nonatomic, assign) CGFloat transformY;

@property (nonatomic, copy) NSString *textParams;

@property (nonatomic, assign) BOOL isLyricSticker; // Lyrics stickers

@end

@protocol ACCStickerMigrationProtocol <NSObject>

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(nonnull id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker;

+ (void)updateUserInfo:(NSDictionary * __autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END

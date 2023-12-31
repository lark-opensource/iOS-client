//
//  ACCModelConverter.h
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/8.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCStickerMigrationProtocol.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <NLEPlatform/HTSVideoData+Converter.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kNLEExtraKey;
FOUNDATION_EXTERN NSString * const kStickerTypeKey;


@interface ACCStickerMigrateUtil : NSObject <ACCStickerMigrationProtocol>

+ (NLESegmentSticker_OC *)crossPlatformStickerFor:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(nonnull id<ACCCrossPlatformMigrateContext>)context;

+ (VEInfoStickerType)veStickerTypeFrom:(NLESegmentSticker_OC *)sticker;

@end

@interface ACCStickerMigrateContext : NSObject <ACCCrossPlatformMigrateContext>

@property (nonatomic, copy) NSString *stickerID;
@property (nonatomic, copy) NSString *resourcePath;

@property (nonatomic, assign) CGFloat transformX;
@property (nonatomic, assign) CGFloat transformY;

@property (nonatomic, copy) NSString *textParams;

@property (nonatomic, assign) BOOL isLyricSticker; // 歌词贴纸

@end

NS_ASSUME_NONNULL_END

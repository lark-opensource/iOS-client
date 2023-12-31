//
//  ACCModelConverter.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/8.
//

#import "ACCStickerMigrateUtil.h"

#import <objc/runtime.h>
#import <NLEPlatform/NLEEditor+iOS.h>
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import <NLEPlatform/HTSVideoData+Converter.h>
#import <IESInject/IESInject.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCStickerMigrationProtocol.h>

#import "ACCStickerMigrantsProtocol.h"
#import <CameraClientModel/ACCCrossPlatformStickerType.h>

NSString * const kNLEExtraKey = @"douyin";
NSString * const kStickerTypeKey = @"type";

@implementation ACCStickerMigrateContext

@end


@implementation ACCStickerMigrateUtil

+ (NLESegmentSticker_OC *)crossPlatformStickerFor:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(nonnull id<ACCCrossPlatformMigrateContext>)context
{
    NLESegmentSticker_OC *nleSticker = nil;
    [self fillCrossPlatformStickerByUserInfo:userInfo repository:sessionModel context:context sticker:&nleSticker];
    
    if (nleSticker == nil) {
        nleSticker = [[NLESegmentInfoSticker_OC alloc] init];
        nleSticker.stickerType = ACCCrossPlatformStickerTypeInfo;
        nleSticker.stickerAnimation = [[NLEStyStickerAnimation_OC alloc] init];
    }
    
    return nleSticker;
}

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    __block NLESegmentSticker_OC *temp_sticker = nil;
    __block BOOL fillRst = NO;
    [[self stickerMigrantsClassList] enumerateObjectsUsingBlock:^(Class<ACCStickerMigrationProtocol>  _Nonnull migrant, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([migrant respondsToSelector:@selector(fillCrossPlatformStickerByUserInfo:repository:context:sticker:)]) {
            fillRst = [migrant fillCrossPlatformStickerByUserInfo:userInfo repository:sessionModel context:context sticker:&temp_sticker];
            if (fillRst) {
                *stop = YES;
            }
        }
    }];
    *sticker = temp_sticker;
    return fillRst;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    __block NSDictionary *temp_userInfo = nil;
    [[self stickerMigrantsClassList] enumerateObjectsUsingBlock:^(Class<ACCStickerMigrationProtocol>  _Nonnull handlerClass, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([handlerClass respondsToSelector:@selector(updateUserInfo:repoModel:byCrossPlatformSlot:)]) {
            [handlerClass updateUserInfo:&temp_userInfo repoModel:sessionModel byCrossPlatformSlot:slot];
        }
    }];
    *userInfo = temp_userInfo;
}

#pragma mark - Tool Methods
+ (NSArray<Class<ACCStickerMigrationProtocol>> *)stickerMigrantsClassList
{
    return [[IESAutoInline(ACCBaseServiceProvider(), ACCStickerMigrantsProtocol) class] stickerMigrants];
}

+ (VEInfoStickerType)veStickerTypeFrom:(NLESegmentSticker_OC *)sticker
{
    VEInfoStickerType veStickerType = VEInfoStickerType_Unknown;
    switch (sticker.stickerType) {
        case ACCCrossPlatformStickerTypeInfo:
            veStickerType = VEInfoStickerType_InfoSticker;
            break;
        case ACCCrossPlatformStickerTypeCustom:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeDaily:
            veStickerType = VEInfoStickerType_Daily;
            break;
        case ACCCrossPlatformStickerTypeMagnifier:
            veStickerType = VEInfoStickerType_Magnifer;
            break;
        case ACCCrossPlatformStickerTypeLyric:
            veStickerType = VEInfoStickerType_Lyric;
            break;
        case ACCCrossPlatformStickerTypeSubTitle:
            veStickerType = VEInfoStickerType_Subtitle;
            break;
        case ACCCrossPlatformStickerTypeText:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypePOI:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeEffectPOI:
            veStickerType = VEInfoStickerType_EffectPOI;
            break;
        case ACCCrossPlatformStickerTypeMention:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeHashtag:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeNearbyHashtag:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeVideoComment:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeVote:
            // Nothing To DO.
            break;
        case ACCCrossPlatformStickerTypeLiveNotice:
            // Nothing To DO.
            break;
        case ACCCrossPlatformStickerTypeVideoShare:
            // Nothing To DO.
        case ACCCrossPlatformStickerTypeGroot:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeVideoReplyVideo:
            veStickerType = VEInfoStickerType_Custom;
            break;
        case ACCCrossPlatformStickerTypeWish:
            veStickerType = VEInfoStickerType_Custom;
            break;
    }
    return veStickerType;
}

@end

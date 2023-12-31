//
//  IESInfoSticker+ACCAdditions.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/5/18.
//

#import "IESInfoSticker+ACCAdditions.h"
#import <CreativeKit/NSDictionary+ACCAdditions.h>

static NSString * const kACCSocialStickerKey = @"kIsSocialStickerKey";
static NSString * const kACCPOIStickerKey = @"kACCPOIStickerKey";
static NSString * const kIsACCVideoCommentStickerKey = @"kIsACCVideoCommentStickerKey";
static NSString * const kACCTextStickerKey = @"kIsTextStickerKey";
static NSString * const kACCMagnifierStickerKey = @"kIsMagnifierStickerKey";
static NSString * const kIsACCNearbyHashtagStickerKey = @"kIsACCNearbyHashtagStickerKey";
static NSString * const ACCDailyStickerKey = @"kIsDailyStickerKey";
static NSString * const kACCLyricStickerKey = @"kIsLyricStickerKey";
static NSString * const kACCIsNotNormalInfoStickerKey = @"kACCIsNotNormalInfoStickerKey";
static NSString * const kACCIsCustomStickerKey = @"isCustomSticker";
static NSString * const kACCKaraokeStickerKey = @"kACCKaraokeStickerKey";
static NSString * const kACCKaraokeLyricStickerTypeKey = @"kACCKaraokeLyricStickerTypeKey";
static NSString * const kACCGrootStickerKey = @"kIsGrootStickerKey";
static NSString * const kACCIsWishStickerKey = @"kACCIsWishStickerKey";

@implementation IESInfoSticker(ACCAddtions)

+ (NSDictionary<NSNumber *, NSString *> *)acc_stickerKeyMapping
{
    return @{
        @(ACCEditEmbeddedStickerTypeSocial) : kACCSocialStickerKey,
        @(ACCEditEmbeddedStickerTypeText) : kACCTextStickerKey,
        @(ACCEditEmbeddedStickerTypeModrenPOI) : kACCPOIStickerKey,
        @(ACCEditEmbeddedStickerTypeVideoComment) : kIsACCVideoCommentStickerKey,
        @(ACCEditEmbeddedStickerTypeMagnifier) : kACCMagnifierStickerKey,
        @(ACCEditEmbeddedStickerTypeNearbyHashtag) : kIsACCNearbyHashtagStickerKey,
        @(ACCEditEmbeddedStickerTypeDaily) : ACCDailyStickerKey,
        @(ACCEditEmbeddedStickerTypeLyrics) : kACCLyricStickerKey,
        @(ACCEditEmbeddedStickerTypeKaraoke) : kACCKaraokeStickerKey,
        @(ACCEditEmbeddedStickerTypeGroot) : kACCGrootStickerKey,
        @(ACCEditEmbeddedStickerTypeCustom) : kACCIsCustomStickerKey,
        @(ACCEditEmbeddedStickerTypeWish) : kACCIsWishStickerKey
    };
}

+ (ACCEditEmbeddedStickerType)acc_stickerTypeWithUserInfo:(NSDictionary *)userInfo
{
    NSArray *keyValuePair = [[IESInfoSticker acc_stickerKeyMapping] acc_match:^BOOL(NSNumber * _Nonnull key, NSString * _Nonnull value) {
        return [userInfo[value] boolValue];
    }];
    
    if (keyValuePair) {
        return (ACCEditEmbeddedStickerType)[keyValuePair.firstObject integerValue];
    }
    
    return ACCEditEmbeddedStickerTypeInfo;
}

+ (BOOL)acc_isImageStickerWithStickerType:(ACCEditEmbeddedStickerType)stickerType
                              karaokeType:(ACCKaraokeStickerType)karaokeType
{
    switch (stickerType) {
        case ACCEditEmbeddedStickerTypeText:
        case ACCEditEmbeddedStickerTypeNearbyHashtag:
        case ACCEditEmbeddedStickerTypeSocial:
        case ACCEditEmbeddedStickerTypeCustom:
        case ACCEditEmbeddedStickerTypeVideoComment:
        case ACCEditEmbeddedStickerTypeGroot:
        case ACCEditEmbeddedStickerTypeWish:
            return YES;
        case ACCEditEmbeddedStickerTypeInfo:
        case ACCEditEmbeddedStickerTypeLyrics:
        case ACCEditEmbeddedStickerTypeMagnifier:
        case ACCEditEmbeddedStickerTypeDaily:
        case ACCEditEmbeddedStickerTypeModrenPOI:
        case ACCEditEmbeddedStickerTypeCaption:
        case ACCEditEmbeddedStickerTypeUIImage:
        case ACCEditEmbeddedStickerTypeKaraoke:
            return NO;
    }
}

- (ACCEditEmbeddedStickerType)acc_stickerType
{
    if (self.userinfo.acc_stickerType != ACCEditEmbeddedStickerTypeInfo) {
        return self.userinfo.acc_stickerType;
    }
    
    if (self.isSrtInfoSticker) {
        return ACCEditEmbeddedStickerTypeLyrics;
    }
    
    if (self.resourcePath == nil) {
        return ACCEditEmbeddedStickerTypeUIImage;
    }
    
    // 字幕不存储草稿，忽略
    if (self.isNeedRemove) {
        return ACCEditEmbeddedStickerTypeCaption;
    }
    
    return ACCEditEmbeddedStickerTypeInfo;
}

- (BOOL)acc_isNotNormalInfoSticker
{
    return [self.userinfo acc_isNotNormalInfoSticker];
}

- (BOOL)acc_isImageSticker
{
    return [IESInfoSticker acc_isImageStickerWithStickerType:self.acc_stickerType karaokeType:self.acc_karaokeType];
}

- (BOOL)acc_isBizInfoSticker
{
    return self.acc_stickerType != ACCEditEmbeddedStickerTypeLyrics &&
        [self.userinfo acc_isBizInfoSticker];
}

// K 歌子类型
- (ACCKaraokeStickerType)acc_karaokeType
{
    return self.userinfo.acc_karaokeType;
}

@end

@implementation NSDictionary(ACCSticker)

- (BOOL)acc_isBizInfoSticker
{
    return !self.acc_isNotNormalInfoSticker &&
        self.acc_stickerType != ACCEditEmbeddedStickerTypeText &&
        self.acc_stickerType != ACCEditEmbeddedStickerTypeSocial &&
        self.acc_stickerType != ACCEditEmbeddedStickerTypeLyrics &&
        self.acc_stickerType != ACCEditEmbeddedStickerTypeKaraoke &&
        self.acc_stickerType != ACCEditEmbeddedStickerTypeWish;
}

- (ACCEditEmbeddedStickerType)acc_stickerType
{
    return [IESInfoSticker acc_stickerTypeWithUserInfo:self];
}

- (BOOL)acc_isNotNormalInfoSticker
{
    return [self[kACCIsNotNormalInfoStickerKey] boolValue];
}

- (BOOL)acc_isImageSticker
{
    return [IESInfoSticker acc_isImageStickerWithStickerType:self.acc_stickerType karaokeType:self.acc_karaokeType];
}

// K 歌子类型
- (ACCKaraokeStickerType)acc_karaokeType
{
    return [self[kACCKaraokeLyricStickerTypeKey] integerValue];
}

@end

@implementation NSMutableDictionary(ACCSticker)

- (void)setAcc_isNotNormalInfoSticker:(BOOL)acc_isNotNormalInfoSticker
{
    self[kACCIsNotNormalInfoStickerKey] = @(acc_isNotNormalInfoSticker);
}

- (void)setAcc_stickerType:(ACCEditEmbeddedStickerType)stickerType
{
    if (stickerType == ACCEditEmbeddedStickerTypeVideoComment ||
        stickerType == ACCEditEmbeddedStickerTypeSocial ||
        stickerType == ACCEditEmbeddedStickerTypeModrenPOI ||
        stickerType == ACCEditEmbeddedStickerTypeKaraoke ||
        stickerType == ACCEditEmbeddedStickerTypeGroot) {
        self.acc_isNotNormalInfoSticker = YES;
    }
    
    
    NSString *userInfoKey = [IESInfoSticker acc_stickerKeyMapping][@(stickerType)];
    if (userInfoKey) {
        self[userInfoKey] = @(YES);
    }
}

- (void)setAcc_karaokeType:(ACCKaraokeStickerType)acc_karaokeType
{
    self[kACCKaraokeLyricStickerTypeKey] = @(acc_karaokeType);
}

@end

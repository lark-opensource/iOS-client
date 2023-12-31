//
//  AWEAssetModel.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/3/20.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEAssetModel.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <objc/runtime.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "ACCConfigKeyDefines.h"
#import "AWEVideoFragmentInfo.h"
#import <TTVideoEditor/AVAsset+Utils.h>

@interface AWEAssetModel ()

@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSString *> *musicRelatedReadableClipTimeString; // 卡点音乐，每一首对应的时长字符串
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSValue *>  *musicRelatedClipTimeRange; // 卡点音乐，每一首对应的clip time range
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSNumber *> *musicRelatedCollectionOffsetXChangedByUser;
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSNumber *> *musicRelatedClipTimeRangeChangedByUser;
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSNumber *> *musicRelatedCollectionOffsetX; // 卡点音乐，每一首对应的collectionOffsetX
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSNumber *> *musicRelatedActualLeftPosition;
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSNumber *> *musicRelatedActualRightPosition;

@end

@implementation AWEAssetModel
@dynamic videoUploadMaxSeconds;

+ (NSValue *)clipRangeFromDictionary:(NSDictionary *)dic
{
    if (!dic) {
        return nil;
    }
    
    int64_t start = [dic acc_integerValueForKey:@"start"];
    int64_t duration = [dic acc_integerValueForKey:@"end"] - start;
    return [NSValue valueWithCMTimeRange:CMTimeRangeMake(CMTimeMake(start, 1000), CMTimeMake(duration, 1000))];
}

+ (NSDictionary *)dictionaryFromClipRange:(NSValue *)clipRange
{
    if (!clipRange) {
        return nil;
    }
    
    CMTimeRange range = clipRange.CMTimeRangeValue;
    NSInteger start = CMTimeGetSeconds(range.start) * 1000;
    NSInteger duration = CMTimeGetSeconds(range.duration) * 1000;
    return @{@"start" : @(start),
             @"duration" : @(duration),
             @"end" : @(start + duration)
    };
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"mediaType" : @"mediaType",
        @"speed" : @"speed",
        @"rotateType" : @"rotateType",
        @"clipTimeRange" : @"clipTimeRange",//最终视频真实的裁剪信息
        @"aiClipTimeRange" : @"aiClipTimeRange", //ai卡点裁剪信息
        @"assetClipTimeRange" : @"assetClipTimeRange", //用户选择的裁剪信息，可能会再裁剪以满足时长限制
        @"UUIDString" : @"UUIDString",
        @"localIdentifier" : @"localIdentifier",
    };
}

+ (NSValueTransformer *)clipTimeRangeJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSDictionary *cmTimeRangeDic, BOOL *success, NSError *__autoreleasing *error) {
        NSInteger start = [cmTimeRangeDic[@"start"] integerValue];
        NSInteger duration = [cmTimeRangeDic[@"duration"] integerValue];
        CMTime startTime = CMTimeMake(start * 1000, 1000000);
        CMTime durationTime = CMTimeMake(duration * 1000, 1000000);
        return [NSValue valueWithCMTimeRange:CMTimeRangeMake(startTime, durationTime)];
    } reverseBlock:^id(NSValue *cmTimeRangeValue, BOOL *success, NSError *__autoreleasing *error) {
        CMTimeRange range = cmTimeRangeValue.CMTimeRangeValue;
        NSInteger start = CMTimeGetSeconds(range.start) * 1000;
        NSInteger duration = CMTimeGetSeconds(range.duration) * 1000;
        return @{
                 @"start" : @(start),
                 @"duration" : @(duration)
                 };
    }];
}


+ (NSValueTransformer *)aiClipTimeRangeJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSDictionary *cmTimeRangeDic, BOOL *success, NSError *__autoreleasing *error) {
        NSInteger start = [cmTimeRangeDic[@"start"] integerValue];
        NSInteger duration = [cmTimeRangeDic[@"duration"] integerValue];
        CMTime startTime = CMTimeMake(start * 1000, 1000000);
        CMTime durationTime = CMTimeMake(duration * 1000, 1000000);
        return [NSValue valueWithCMTimeRange:CMTimeRangeMake(startTime, durationTime)];
    } reverseBlock:^id(NSValue *cmTimeRangeValue, BOOL *success, NSError *__autoreleasing *error) {
        CMTimeRange range = cmTimeRangeValue.CMTimeRangeValue;
        NSInteger start = CMTimeGetSeconds(range.start) * 1000;
        NSInteger duration = CMTimeGetSeconds(range.duration) * 1000;
        return @{
                 @"start" : @(start),
                 @"duration" : @(duration)
                 };
    }];
}

+ (NSValueTransformer *)assetClipTimeRangeJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSDictionary *cmTimeRangeDic, BOOL *success, NSError *__autoreleasing *error) {
        NSInteger start = [cmTimeRangeDic[@"start"] integerValue];
        NSInteger duration = [cmTimeRangeDic[@"duration"] integerValue];
        CMTime startTime = CMTimeMake(start * 1000, 1000000);
        CMTime durationTime = CMTimeMake(duration * 1000, 1000000);
        return [NSValue valueWithCMTimeRange:CMTimeRangeMake(startTime, durationTime)];
    } reverseBlock:^id(NSValue *cmTimeRangeValue, BOOL *success, NSError *__autoreleasing *error) {
        CMTimeRange range = cmTimeRangeValue.CMTimeRangeValue;
        NSInteger start = CMTimeGetSeconds(range.start) * 1000;
        NSInteger duration = CMTimeGetSeconds(range.duration) * 1000;
        return @{
                 @"start" : @(start),
                 @"duration" : @(duration)
                 };
    }];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.speed = HTSVideoSpeedNormal;
        self.imageDict = [NSMutableDictionary dictionary];
        self.musicRelatedReadableClipTimeString = [NSMutableDictionary dictionary];
        self.musicRelatedClipTimeRange = [NSMutableDictionary dictionary];
        self.musicRelatedCollectionOffsetX = [NSMutableDictionary dictionary];
        self.musicRelatedCollectionOffsetXChangedByUser = [NSMutableDictionary dictionary];
        self.musicRelatedClipTimeRangeChangedByUser = [NSMutableDictionary dictionary];
        self.musicRelatedActualLeftPosition = [NSMutableDictionary dictionary];
        self.musicRelatedActualRightPosition = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDate *)creationDate
{
    return self.asset.creationDate;
}

- (NSDate *)modificationDate
{
    return self.asset.modificationDate;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[AWEAssetModel class]]) {
        return NO;
    }
    
    return [self isEqualToAssetModel:(AWEAssetModel *)object identity:YES];
}

- (BOOL)isEqualToAssetModel:(AWEAssetModel *)object identity:(BOOL)identity
{
    if (!object) {
        return NO;
    }

    if (identity) {
        if (self.UUIDString.length > 0 && ![self.UUIDString isEqualToString:object.UUIDString]) {
            return NO;
        }
    }
    BOOL hasEqualLoalIdentifier = (object.asset != nil && !self.asset.localIdentifier && !object.asset.localIdentifier) ||
    (object.asset != nil && [self.asset.localIdentifier isEqualToString:object.asset.localIdentifier]);

    if (hasEqualLoalIdentifier) {
        return YES;
    }
    if (self.avAsset &&
        object.avAsset &&
        [self.avAsset isKindOfClass:[AVURLAsset class]] &&
        [object.avAsset isKindOfClass:[AVURLAsset class]])
    {
        NSURL *URLInSelf = [(AVURLAsset *)self.avAsset URL];
        NSURL *URLInObject = [(AVURLAsset *)object.avAsset URL];
        return [URLInSelf.absoluteString isEqualToString:URLInObject.absoluteString];
    }

    // 占位视频
    if ([self.avAsset isBlankVideo]) {
        return [self.avAsset.frameImageURL.path isEqualToString:object.avAsset.frameImageURL.path];
    }
    
    return NO;
}

- (void)generateUUIDStringIfNeeded
{
    if (self.UUIDString.length == 0) {
        self.UUIDString = [[NSUUID UUID] UUIDString];
    }
}

- (NSString *)UUIDString
{
    if (!_UUIDString) {
        _UUIDString = [[NSUUID UUID] UUIDString];
    }
    return _UUIDString;
}

- (NSUInteger)hash
{
    return [self.asset.localIdentifier hash];
}

- (NSValue *)originSizeOfVideo
{
    if (!_originSizeOfVideo) {
        AVAsset *asset = self.avAsset;
        NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if ([tracks count] <= 0) {
            _originSizeOfVideo = nil;
        } else {
            AVAssetTrack *firstTrack = [tracks firstObject];
            CGSize dimensions = CGSizeApplyAffineTransform(firstTrack.naturalSize, firstTrack.preferredTransform);
            _originSizeOfVideo = @(CGSizeMake(fabs(dimensions.width), fabs(dimensions.height)));
            if (CGSizeEqualToSize([_originSizeOfVideo CGSizeValue], CGSizeZero)) {
                _originSizeOfVideo = nil;
            }
        }
    }
    return _originSizeOfVideo;
}

- (NSTimeInterval)duration
{
    if (!_duration) {
        _duration = 0;
        if (!self.avAsset.isSceneDoNotNeedLimitDuration && self.avAsset.frameImageURL) {
            _duration = 3.0f;
        } else {
            if (CMTIME_IS_VALID(self.avAsset.duration)) {
                _duration = CMTimeGetSeconds(self.avAsset.duration);
            }
        }
    }
    return _duration;
}

- (NSTimeInterval)clipDuration
{
    CMTime duration = [self.clipTimeRange CMTimeRangeValue].duration;
    return CMTimeGetSeconds(duration);
}

- (NSValue *)cmTimeDuration
{
    if (!_cmTimeDuration) {
        if (!self.avAsset.isSceneDoNotNeedLimitDuration && self.avAsset.frameImageURL) {
            _cmTimeDuration = [NSValue valueWithCMTime:CMTimeMakeWithSeconds(3.0f, NSEC_PER_SEC)];
        } else {
            _cmTimeDuration = [NSValue valueWithCMTime:self.avAsset.duration];
        }
    }
    return _cmTimeDuration;
}

- (CGSize)videoSizeWithRotateType:(AWEVideoCompositionRotateType)rotateType
{
    if (self.originSizeOfVideo) {
        CGSize size = [self.originSizeOfVideo CGSizeValue];
        switch (rotateType) {
            case AWEVideoCompositionRotateTypeNone:
            case AWEVideoCompositionRotateTypeDown:
                break;
            case AWEVideoCompositionRotateTypeRight:
            case AWEVideoCompositionRotateTypeLeft:
                size = CGSizeMake(size.height, size.width);
                break;
        }
        return size;
    }
    return CGSizeZero;
}

- (CGSize)videoSizeWithCurrentRotateType
{
    return [self videoSizeWithRotateType:self.rotateType];
}

- (void)setImageArrayForSpeed:(HTSVideoSpeed)speed imageArray:(NSArray *)imageArray
{
    NSUInteger index = HTSIndexForSpeed(speed);
    if (imageArray) {
        self.imageDict[@(index)] = imageArray;
    }
}

- (void)setImageArrayForIndex:(NSInteger)index imageArray:(NSArray *)imageArray
{
    if (imageArray) {
        self.imageDict[@(index)] = imageArray;
    }
}

- (NSArray<UIImage *> *)getImageArrayForSpeed:(HTSVideoSpeed)speed
{
    NSUInteger index = HTSIndexForSpeed(speed);
    return self.imageDict[@(index)];
}

- (CMTimeRange)currentAssetClippedRange
{
    if (self.isBeClipped) {
        return [self.assetClipTimeRange CMTimeRangeValue];
    } else {
        return [self.initialTimeRange CMTimeRangeValue];
    }
}

#pragma mark - Music related

- (void)setReadableClipTimeString:(NSString *)timeString
                       forMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return;
    }
    self.musicRelatedReadableClipTimeString[musicID] = timeString;
}

- (void)setClipTimeRange:(NSValue *)clipTimeRange forMusicID:(id<NSCopying>)musicID changeByUser:(BOOL)changeByUser
{
    if (!musicID) {
        return;
    }
    self.musicRelatedClipTimeRange[musicID] = clipTimeRange;
    self.musicRelatedClipTimeRangeChangedByUser[musicID] = @(changeByUser);
}

- (void)setCollectionOffsetX:(NSNumber *)collectionOffsetX forMusicID:(id<NSCopying>)musicID changeByUser:(BOOL)changeByUser
{
    if (!musicID) {
        return;
    }
    self.musicRelatedCollectionOffsetX[musicID] = collectionOffsetX;
    self.musicRelatedCollectionOffsetXChangedByUser[musicID] = @(changeByUser);
}

- (void)setActualLeftPosition:(NSNumber *)actualLeftPosition forMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return;
    }
    self.musicRelatedActualLeftPosition[musicID] = actualLeftPosition;
}

- (void)setActualRightPosition:(NSNumber *)actualRightPosition forMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return;
    }
    self.musicRelatedActualRightPosition[musicID] = actualRightPosition;
}

- (NSString *)readableClipTimeStringForMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return nil;
    }
    return self.musicRelatedReadableClipTimeString[musicID];
}

- (NSValue *)clipTimeRangeForMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return nil;
    }
    return self.musicRelatedClipTimeRange[musicID];
}

- (NSNumber *)collectionOffsetXForMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return nil;
    }
    return self.musicRelatedCollectionOffsetX[musicID];
}

- (BOOL)isClipTimeRangeChangedByUserForMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return NO;
    }
    return [self.musicRelatedClipTimeRangeChangedByUser[musicID] boolValue];
}

- (BOOL)isCollectionOffsetXChangedByUserForMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return NO;
    }
    return [self.musicRelatedCollectionOffsetXChangedByUser[musicID] boolValue];
}

- (NSNumber *)actualLeftPositionForMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return nil;
    }
    return self.musicRelatedActualLeftPosition[musicID];
}

- (NSNumber *)actualRightPositionForMusicID:(id<NSCopying>)musicID
{
    if (!musicID) {
        return nil;
    }
    return self.musicRelatedActualRightPosition[musicID];
}

- (NSValue *)initialTimeRange
{
    if (!_initialTimeRange) {
        NSInteger videoMaxDuration = self.isFromLv ? [self.class videoFromLvUploadMaxSeconds] : [self.class videoUploadMaxSeconds];
        NSAssert(videoMaxDuration > 0, @"illegal video length config");
        
        CMTime durationTime = self.avAsset.duration;
        
        if (!self.avAsset.isSceneDoNotNeedLimitDuration && self.avAsset.frameImageURL) {
            durationTime = CMTimeMakeWithSeconds(3.0, durationTime.timescale);
        }
        
        let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
        CGFloat initialMaxSeconds = self.isFromLv ? config.videoFromLvUploadMaxSeconds : config.clipVideoInitialMaxSeconds;
        if (videoMaxDuration > initialMaxSeconds) {
            videoMaxDuration = initialMaxSeconds;
        }
        
        if (CMTimeGetSeconds(durationTime) > videoMaxDuration) {
            durationTime = CMTimeMakeWithSeconds(videoMaxDuration, durationTime.timescale);
        }
        
        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, durationTime);
        _initialTimeRange = [NSValue valueWithCMTimeRange:range];
    }
    
    return _initialTimeRange;
}

- (NSValue *)assetClipTimeRange
{
    if (!_assetClipTimeRange) {
        NSInteger videoMaxDuration = self.isFromLv ? [self.class videoFromLvUploadMaxSeconds] : [self.class videoUploadMaxSeconds];
        NSAssert(videoMaxDuration > 0, @"illegal video length config");
        CMTime durationTime = self.avAsset ? self.avAsset.duration : kCMTimeZero;

        if (!self.avAsset.isSceneDoNotNeedLimitDuration && self.avAsset.frameImageURL) {
            durationTime = CMTimeMakeWithSeconds(3.0, durationTime.timescale);
        }
        
        if (CMTimeGetSeconds(durationTime) > videoMaxDuration && !ACCConfigBool(kConfigBool_enable_new_clips)) {
            durationTime = CMTimeMakeWithSeconds(videoMaxDuration, durationTime.timescale);
        }

        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, durationTime);
        _assetClipTimeRange = [NSValue valueWithCMTimeRange:range];
    }

    return _assetClipTimeRange;
}

- (id)copyWithZone:(NSZone *)zone
{
    AWEAssetModel *assetModel = [[AWEAssetModel alloc] init];
    assetModel.asset = [self.asset copy];
    assetModel.videoDuration = [self.videoDuration copy];
    assetModel.mediaType = self.mediaType;
    assetModel.mediaSubType = self.mediaSubType;
    assetModel.selectedNum = [self.selectedNum copy];
    assetModel.coverImage = self.coverImage;
    assetModel.dateFormatStr = [self.dateFormatStr copy];
    assetModel.dateFormatBriefStr = [self.dateFormatBriefStr copy];
    assetModel.avAsset = [self.avAsset copy];
    assetModel.speed = self.speed;
    assetModel.rotateType = self.rotateType;
    assetModel.originSizeOfVideo = self.originSizeOfVideo;
    assetModel.collectionOffsetX = self.collectionOffsetX;
    assetModel.albumId = [self.albumId copy];
    assetModel.originalResolution = [self.originalResolution copy];
    
    // 兼容之前的bug
    if (ACCConfigBool(kConfigBool_enable_new_clips)) {
        assetModel.clipTimeRange = [self.clipTimeRange copy];
        assetModel.aiClipTimeRange = [self.aiClipTimeRange copy];
        assetModel.initialTimeRange = [self.initialTimeRange copy];
        assetModel.aiClipTimeRange = [self.aiClipTimeRange copy];
        assetModel.assetClipTimeRange = [self.assetClipTimeRange copy];;
        assetModel.assetBackupClipTimeRange = [self.assetBackupClipTimeRange copy];
        assetModel.fragmentInfo = [self.fragmentInfo copy];
    }

    assetModel.UUIDString = [self.UUIDString copy];

    assetModel.musicRelatedReadableClipTimeString = [self.musicRelatedReadableClipTimeString mutableCopy];
    assetModel.musicRelatedClipTimeRange = [self.musicRelatedClipTimeRange mutableCopy];
    assetModel.musicRelatedCollectionOffsetXChangedByUser = [self.musicRelatedCollectionOffsetXChangedByUser mutableCopy];
    assetModel.musicRelatedClipTimeRangeChangedByUser = [self.musicRelatedClipTimeRangeChangedByUser mutableCopy];
    assetModel.musicRelatedCollectionOffsetX = [self.musicRelatedCollectionOffsetX mutableCopy];
    assetModel.musicRelatedActualLeftPosition = [self.musicRelatedActualLeftPosition mutableCopy];
    assetModel.musicRelatedActualRightPosition = [self.musicRelatedActualRightPosition mutableCopy];

    return assetModel;
}

+ (instancetype)createWithPHAsset:(PHAsset *)asset
{
    AWEAssetModel *model = [[AWEAssetModel alloc] init];
    AWEAssetModelMediaType type = AWEAssetModelMediaTypeUnknow;
    AWEAssetModelMediaSubType subType = AWEAssetModelMediaSubTypeUnknow;
    switch (asset.mediaType) {
        case PHAssetMediaTypeVideo:
            type = AWEAssetModelMediaTypeVideo;
            if (asset.mediaSubtypes == PHAssetMediaSubtypeVideoHighFrameRate) {
                subType = AWEAssetModelMediaSubTypeVideoHighFrameRate;
            }
            break;
        case PHAssetMediaTypeAudio:
            type = AWEAssetModelMediaTypeAudio;
        case PHAssetMediaTypeImage: {
            type = AWEAssetModelMediaTypePhoto;
            if (@available(iOS 9.1, *)) {
                if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    subType = AWEAssetModelMediaSubTypePhotoLive;
                }
                break;
            }
            if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                subType = AWEAssetModelMediaSubTypePhotoGif;
            }
        }
            break;
        default:
            break;
    }

    model.mediaType = type;
    model.mediaSubType = subType;
    model.selectedNum = nil;
    model.asset = asset;
    if (type == AWEAssetModelMediaTypeVideo) {
        NSTimeInterval duration = asset.duration;
        NSInteger seconds = (NSInteger)round(duration);
        NSInteger second = seconds % 60;
        NSInteger minute = seconds / 60;
        model.videoDuration = [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
//        model.videoDuration = [self timeStringWithDuration:asset.duration];
    }

    return model;
}

#pragma mark - Getter

- (NSValue *)clipTimeRange
{
    if (!_clipTimeRange) {
        if (ACCConfigBool(kConfigBool_enable_new_clips)) {
            if (!self.avAsset.isSceneDoNotNeedLimitDuration && self.avAsset.frameImageURL) {
                _clipTimeRange = [NSValue valueWithCMTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3.0, 10000.0))];
            } else {
                _clipTimeRange = [NSValue valueWithCMTimeRange:CMTimeRangeMake(kCMTimeZero, self.avAsset.duration)];
            }
        }
    }

    return _clipTimeRange;
}

@end

@implementation AWEAlbumModel


@end

@implementation AVAsset (MixexUploading)

- (NSURL *)frameImageURL {
    return objc_getAssociatedObject(self, @selector(frameImageURL));
}

- (void)setFrameImageURL:(NSURL *)frameImageURL {
    objc_setAssociatedObject(self, @selector(frameImageURL), frameImageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)thumbImage {
    return objc_getAssociatedObject(self, @selector(thumbImage));
}

- (void)setThumbImage:(UIImage *)thumbImage {
    objc_setAssociatedObject(self, @selector(thumbImage), thumbImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark 是否是不需要限制时长的场景
- (BOOL)isSceneDoNotNeedLimitDuration
{
    return [objc_getAssociatedObject(self, @selector(isSceneDoNotNeedLimitDuration)) boolValue];
}

#pragma mark 设置是否是不需要限制时长的场景
- (void)setIsSceneDoNotNeedLimitDuration:(BOOL)isSceneDoNotNeedLimitDuration
{
    objc_setAssociatedObject(self, @selector(isSceneDoNotNeedLimitDuration), @(isSceneDoNotNeedLimitDuration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

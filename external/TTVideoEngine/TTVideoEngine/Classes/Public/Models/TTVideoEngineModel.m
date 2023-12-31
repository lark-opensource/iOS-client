//
//  ExploreLeTVVideoModel.m
//  Article
//
//  Created by Zhang Leonardo on 15-3-5.
//
//

#import "TTVideoEngineModel.h"
#import "TTVideoEngineModelCache.h"
#import "NSObject+TTVideoEngine.h"
#import "NSString+TTVideoEngine.h"

@interface TTVideoEngineModel ()<TTVideoEngineModelCacheItem>

@end

@interface TTVideoEngineModel ()
@property (nonatomic, copy) NSDictionary *jsonInfo;
@end

@implementation TTVideoEngineModel
/// Please use @property.
+ (nullable instancetype)videoModelWithPb:(NSData *)data {
    TTVideoEngineInfoModel *infoModel = [[TTVideoEngineInfoModel alloc] initVideoInfoWithPb:data];
    if ([infoModel getValueStr:VALUE_VIDEO_ID]) {
        TTVideoEngineModel *videoModel = [[TTVideoEngineModel alloc] init];
        videoModel.videoInfo = infoModel;
        return videoModel;
    }
    return nil;
}

+ (nullable instancetype)videoModelWithDict:(NSDictionary *)info {
    return [self videoModelWithDict:info encrypted:NO];
}

+ (nullable instancetype)videoModelWithDict:(NSDictionary *)info encrypted:(BOOL)encrypted {
    TTVideoEngineInfoModel *infoModel = [[TTVideoEngineInfoModel alloc] initWithDictionary:info encrypted:encrypted];
    if ([infoModel getValueStr:VALUE_VIDEO_ID]) {
        TTVideoEngineModel *videoModel = [[TTVideoEngineModel alloc] init];
        videoModel.videoInfo = infoModel;
        videoModel.jsonInfo = info;
        return videoModel;
    }
    
    return nil;
}

+ (nullable instancetype)videoModelWithMediaJsonString:(NSString *)mediaJsonString {
    TTVideoEngineInfoModel *infoModel = [TTVideoEngineInfoModel new];
    [infoModel parseMediaDict:[mediaJsonString ttvideoengine_jsonStr2Dict]];
    if ([infoModel getValueStr:VALUE_VIDEO_ID]) {
        TTVideoEngineModel *videoModel = [TTVideoEngineModel new];
        videoModel.videoInfo = infoModel;
        return videoModel;
    }
    return nil;
}

- (nullable NSDictionary *)dictInfo {
    return self.jsonInfo;
}

- (NSArray *)allURLWithDefinitionType:(TTVideoEngineResolutionType)type transformedURL:(BOOL)transformed
{
    if (self.videoInfo) {
        return [self.videoInfo allURLWithDefinition:type transformedURL:transformed];
    }
    return nil;
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType)type {
    if (self.videoInfo) {
        return [self.videoInfo videoInfoForType:type];
    }
    return nil;
}

- (NSString *)codecType {
    if (self.videoInfo) {
        NSArray* codecs = [self.videoInfo codecTypes];
        if ([codecs containsObject:kTTVideoEngineCodecByteVC2]) {
            return kTTVideoEngineCodecByteVC2;
        }
        if ([codecs containsObject:kTTVideoEngineCodecByteVC1]) {
            return kTTVideoEngineCodecByteVC1;
        }
    }
    return kTTVideoEngineCodecH264;
}

- (NSArray *)codecTypes {
    if (self.videoInfo) {
        return [self.videoInfo codecTypes];
    }
    return nil;
}

- (NSString *)videoType {
    if (self.videoInfo) {
        return [self.videoInfo videoType];
    }
    return @"mp4";
}

+ (NSString* )buildCacheKey:(NSString *)vid params:(NSDictionary *)params ptoken:(NSString *)ptoken {
    if (vid == nil || vid.length == 0) {
        return nil;
    }
    
    NSMutableString* cacheKey = [NSMutableString string];
    if (params && params.count > 0) {
        NSString *obj = params[@"codec_type"];
        if (obj) {
            [cacheKey appendFormat:@"%@&%@",@"codec_type",obj];
        }
        obj = params[@"format_type"];
        if (obj) {
            [cacheKey appendFormat:@"%@&%@",@"format_type",obj];
        }
        obj = params[@"ssl"];
        if (obj) {
            [cacheKey appendFormat:@"%@&%@",@"ssl",obj];
        }
    }
    [cacheKey appendFormat:@"$%@",vid];
    [cacheKey appendFormat:@"$%@",ptoken?:@""];
    return cacheKey;
}

- (NSArray<NSNumber *> *)supportedResolutionTypes {
    if (self.videoInfo) {
        return [self.videoInfo supportedResolutionTypes];
    }
    return nil;
}
- (NSArray<NSString *> *)supportedQualityInfos {
    if (self.videoInfo) {
        return [self.videoInfo supportedQualityInfos];
    }
    return nil;
}
- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[TTVideoEngineModel class]]) {
        return NO;
    }
   
    if ([super isEqual:object]) {
        return YES;
    }
    
    return [self.videoInfo isEqual:((TTVideoEngineModel *)object).videoInfo];
}

- (BOOL)supportBash {
    if (self.videoInfo.memString.length <= 0) {
        return NO;
    }
    if ([self supportDash] && [[self.videoInfo getValueStr:VALUE_DYNAMIC_TYPE] isEqualToString:@"segment_base"]) {
        return YES;
    } else if ([self supportMp4] && [self.videoInfo enableAdaptive] && ![self isHaveSpadea]) {
        return YES;
    }
    return NO;
}

- (BOOL)supportHLSSeamlessSwitch {
    if (self.videoInfo.memString.length <= 0) {
        return NO;
    }
    if ([self supportHLS] && [self.videoInfo enableAdaptive]) {
       return YES;
    }
    return NO;
}

- (BOOL)isHaveSpadea {
    BOOL isHaveSpadea = NO;
    NSArray <TTVideoEngineURLInfo *> *videoEngineUrlInfos = [self.videoInfo getValueArray:VALUE_VIDEO_LIST];
    for (int i = 0; i < videoEngineUrlInfos.count; i++) {
        TTVideoEngineURLInfo *info = videoEngineUrlInfos[i];
        if ([info getValueStr:VALUE_PLAY_AUTH].length > 0) {
            isHaveSpadea = YES;
            break;
        }
    }
    return isHaveSpadea;
}

- (BOOL)supportDash {
    if (self.videoInfo) {
        return [[self videoType] isEqualToString:@"dash"] || [[self videoType] isEqualToString:@"mpd"];
    }
    return NO;
}

- (BOOL)supportMp4 {
    if (self.videoInfo) {
        return [[self videoType] isEqualToString:@"mp4"];
    }
    return NO;
}

- (BOOL)supportHLS {
    if (self.videoInfo) {
        return [[self videoType] isEqualToString:@"hls"];
    }
    return NO;
}

//MARK: - TTVideoEngineModelCacheItem

- (BOOL)hasExpired {
    if (self.videoInfo) {
        return [self.videoInfo hasExpired];
    }
    return YES;
}

///MARK: - NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

//
//  ACCRepoVideoInfoModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import "ACCRepoVideoInfoModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitArch/HTSVideoSepcialEffect.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCRepoUploadInfomationModel.h"
#import "ACCRepoContextModel.h"
#import "ACCVideoDataProtocol.h"


@interface AWEVideoPublishViewModel (RepoVideoInfo) <ACCRepositoryElementRegisterCategoryProtocol, ACCRepositoryDraftContextProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoVideoInfo)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoVideoInfoModel.class];
}

- (ACCRepoVideoInfoModel *)repoVideoInfo
{
    ACCRepoVideoInfoModel *videoInfoModel = [self extensionModelOfClass:ACCRepoVideoInfoModel.class];
    NSAssert(videoInfoModel, @"extension model should not be nil");
    return videoInfoModel;
}

@end


@interface ACCRepoVideoInfoModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation ACCRepoVideoInfoModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoVideoInfoModel *model = [[[self class] alloc] init];
    model.videoMuted = self.videoMuted;
    model.isExposureOptmize = self.isExposureOptmize;
    model.enableHDRNet = self.enableHDRNet;
    model.fragmentInfo = [[NSMutableArray alloc] initWithArray:self.fragmentInfo copyItems:YES];
    return model;
}

- (id<ACCVideoDataProtocol>)videoData
{
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    return videoData;
}

- (float)fps
{
    AVAssetTrack *videoTrack = [self.videoData.videoAssets.firstObject tracksWithMediaType:AVMediaTypeVideo].firstObject;
    __block float fps = -1;
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    if (contextModel.videoSource == AWEVideoSourceCapture) {
        __block float totalFragment = 0;
        __block float totalDuration = 0;
        
        [self.fragmentInfo enumerateObjectsUsingBlock:^(id<ACCVideoFragmentInfoProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.frameCount > 0 && obj.recordDuration > 0) {
                totalFragment += obj.frameCount;
                totalDuration += obj.recordDuration;
            }
        }];
        
        if (totalDuration > 0) {
            fps = totalFragment / totalDuration;
        }
    } else {
        fps = videoTrack.nominalFrameRate;
    }
    return fps;
}

- (NSValue *)sizeOfVideo
{
    NSAssert(NO, @"should implementation in chaild class");
    return [NSValue valueWithCGSize:CGSizeZero];
}

- (BOOL)isVideoNeedReverse
{
    ACCRepoContextModel *context = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    return [self.videoData effect_timeMachineType] == HTSPlayerTimeMachineReverse || context.videoRecordType == AWEVideoRecordTypeBoomerang;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams
{
    id<ACCVideoDataProtocol> videoData = self.videoData;
    
    NSMutableArray *sizes = @[].mutableCopy;
    NSMutableArray *durations = @[].mutableCopy;
    [videoData.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVAssetTrack *videoTrack = [obj tracksWithMediaType:AVMediaTypeVideo].lastObject;
        [durations addObject:[NSString stringWithFormat:@"%.2f",CMTimeGetSeconds(obj.duration)]];
        [sizes addObject:NSStringFromCGSize(videoTrack.naturalSize)];
    }];
    
    NSString *video_durations = [durations componentsJoinedByString:@","];
    NSString *video_sizes = [sizes componentsJoinedByString:@","];
    NSDictionary *effects = [self.videoData effect_dictionary];
    NSInteger timeMachine = [self.videoData effect_timeMachineType];
    CGFloat timeMachineLocation = [self.videoData effect_timeMachineBeginTime];
    
    NSString *effectsJsonString = @"";
    if (effects.allKeys.count > 0) {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:effects options:0 error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        if (data) {
            effectsJsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    
    NSMutableArray *audioDurations = @[].mutableCopy;
    [videoData.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [audioDurations addObject:[NSString stringWithFormat:@"%.2f",CMTimeGetSeconds(obj.duration)]];
    }];
    NSString *audio_durations = [audioDurations componentsJoinedByString:@","];
    
    NSString *fragmentInfoString = @"";
    NSArray *fragmentInfo = self.fragmentInfo.copy;
    if (fragmentInfo.count > 0) {
        NSError *convertError = nil;
        NSArray *jsonArray = [MTLJSONAdapter JSONArrayFromModels:fragmentInfo error:&convertError];
        if (convertError) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, convertError);
        }
        if (!jsonArray) {
            jsonArray = [NSArray new];
        }
        
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonArray options:0 error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        
        if (data) {
            fragmentInfoString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    
    return @{
        @"time_machine":@(timeMachine),
        @"time_machine_loc":@(timeMachineLocation),
        @"total_duration":@([videoData totalVideoDuration]),
        @"video_durations":video_durations?:@"",
        @"audio_durations":audio_durations?:@"",
        @"video_sizes":video_sizes?:@"",
        @"segment_count":@(videoData.videoAssets.count),
        @"effects":effectsJsonString?:@"",
        @"effects_count":@(effects.count),
        @"bitRate":@(videoData.transParam.bitrate),
        @"outputSize":NSStringFromCGSize(videoData.transParam.videoSize),
        @"hasRecordAudio":@(videoData.hasRecordAudio),
        @"fragment_info":fragmentInfoString?:@"",
        @"fragmentInfoLoss":@(self.videoData.videoAssets.count != self.fragmentInfo.count),
    };
}

- (NSDictionary *)acc_referExtraParams
{
    return @{
        @"fps" : @(self.fps),
    };
}

#pragma mark - Getter

- (NSMutableArray<id<ACCVideoFragmentInfoProtocol>> *)fragmentInfo
{
    if (!_fragmentInfo) {
        _fragmentInfo = [NSMutableArray array];
    }
    return _fragmentInfo;
}

@end


@implementation ACCVideoCanvasSource

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeCGPoint:self.center forKey:@"center"];
    [coder encodeDouble:self.scale forKey:@"scale"];
    [coder encodeDouble:self.rotation forKey:@"rotation"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _center = [coder decodeCGPointForKey:@"center"];
        _scale = [coder decodeDoubleForKey:@"scale"];
        _rotation = [coder decodeDoubleForKey:@"rotation"];
    }
    return self;
}

- (BOOL)isEqualToObject:(ACCVideoCanvasSource *)object
{
    if (![object isKindOfClass:[ACCVideoCanvasSource class]]) {
        return NO;
    }
    if (!ACC_FLOAT_EQUAL_TO(self.center.x, object.center.x) ||
        !ACC_FLOAT_EQUAL_TO(self.center.y, object.center.y) ||
        !ACC_FLOAT_EQUAL_TO(self.scale, object.scale) ||
        !ACC_FLOAT_EQUAL_TO(self.rotation, object.rotation)) {
        return NO;
    }
    return YES;
}

@end

//
//  ACCRepoTranscodingModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/14.
//

#import "ACCRepoTranscodingModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

#import "ACCRepoVideoInfoModel.h"
#import "ACCVideoDataProtocol.h"

@interface AWEVideoPublishViewModel (RepoTranscoding) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoTranscoding)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoTranscodingModel.class];
}

- (ACCRepoTranscodingModel *)repoTranscoding
{
    ACCRepoTranscodingModel *transcodingModel = [self extensionModelOfClass:ACCRepoTranscodingModel.class];
    NSAssert(transcodingModel, @"extension model should not be nil");
    return transcodingModel;
}

@end

@interface ACCRepoTranscodingModel()

@end

@implementation ACCRepoTranscodingModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoTranscodingModel *model = [[[self class] alloc] init];
    model.isReencode = self.isReencode;
    model.bitRate = self.bitRate;
    model.outputHeight = self.outputHeight;
    model.outputWidth = self.outputWidth;
    model.uploadFileSize = self.uploadFileSize;
    return model;
}

- (NSMutableDictionary *)videoQualityTraceInfo
{
    ACCRepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    if (self.uploadURL) {
        AVAsset *asset = [AVAsset assetWithURL:self.uploadURL];
        AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (videoTrack) {
            CGSize videoSize = videoTrack.naturalSize;
            NSString *size = [NSString stringWithFormat:@"%@*%@",@(videoSize.width),@(videoSize.height)];
            NSString *fileBitRate = [NSString stringWithFormat:@"%.1f",videoTrack.estimatedDataRate / 1000.f]; //kbps
            NSString *settingBitRate = [NSString stringWithFormat:@"%.1f",videoData.transParam.bitrate / 1000.f]; //kbps
            
            return @{@"resolution":size,
                     @"file_bitrate":fileBitRate,
                     @"bitrate":settingBitRate,
                     @"is_hardcode":@"1",
                     @"fps":@(videoInfoModel.fps),
                     @"file_fps":@(videoTrack.nominalFrameRate),
                     @"_perf_monitor":@"1"}.mutableCopy;
        } else {
            return @{
                @"is_hardcode":@"1",
                @"_perf_monitor":@"1"}.mutableCopy;
        }
    } else {
        AVAsset *firstAsset = videoData.videoAssets.firstObject;
        NSURL *imageUrl = [videoData.photoAssetsInfo objectForKey:firstAsset];
        AVAssetTrack *videoTrack = [firstAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        CGSize videoSize = CGSizeZero;
        if (imageUrl) {
            //When the first segment is a picture (single picture, multi picture, mixed picture and video), the resolution of the first segment is 90 * 120 of the occupied video, and the replacement strategy is targetvideosize.
            videoSize = videoData.transParam.targetVideoSize;
        } else {
            videoSize = videoTrack.naturalSize;
        }
        NSString *size = [NSString stringWithFormat:@"%@*%@",@(videoSize.width),@(videoSize.height)];
        NSString *fileBitRate = [NSString stringWithFormat:@"%.1f",videoTrack.estimatedDataRate / 1000.f]; //kbps
        NSString *settingBitRate = [NSString stringWithFormat:@"%.1f",videoData.transParam.bitrate / 1000.f]; //kbps
        
        return @{@"resolution":size,
                 @"file_bitrate":fileBitRate,
                 @"bitrate":settingBitRate,
                 @"is_hardcode":@"1",
                 @"fps":@(videoInfoModel.fps),
                 @"_perf_monitor":@"1"}.mutableCopy;
    }
}

- (NSDictionary *)videoComposeQualityTraceInfo
{
    NSAssert(NO, @"should implementation in sub class");
    return @{};
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSInteger videoWidth = 0;
    NSInteger videoHeight = 0;
    
    ACCRepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    if (self.outputWidth && self.outputHeight) {
        videoWidth = self.outputWidth;
        videoHeight = self.outputHeight;
    } else if (videoInfoModel.sizeOfVideo) {
        CGSize videoSize = [videoInfoModel.sizeOfVideo CGSizeValue];
        videoWidth = videoSize.width;
        videoHeight = videoSize.height;
    }
    
    return @{
        @"is_bytevc1" : (self.isByteVC1 ? @1 : @0),
        @"video_width" : @(videoWidth),
        @"video_height" : @(videoHeight),
    };
}

@end

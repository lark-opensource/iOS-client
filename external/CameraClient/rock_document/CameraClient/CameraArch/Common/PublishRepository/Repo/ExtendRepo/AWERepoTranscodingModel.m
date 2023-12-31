//
//  AWERepoTranscodingModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/14.
//

#import "AWERepoTranscodingModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitArch/ACCVideoDataProtocol.h>

@interface AWEVideoPublishViewModel (AWERepoTranscoding) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoTranscoding)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoTranscodingModel.class];
	return info;
}

- (AWERepoTranscodingModel *)repoTranscoding
{
    AWERepoTranscodingModel *transcodingModel = [self extensionModelOfClass:AWERepoTranscodingModel.class];
    NSAssert(transcodingModel, @"extension model should not be nil");
    return transcodingModel;
}

@end

@interface AWERepoTranscodingModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation AWERepoTranscodingModel

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoTranscodingModel *model = [super copyWithZone:zone];
    model.isByteVC1 = self.isByteVC1;
    model.encodeHdrType = self.encodeHdrType;
    model.encodeBitsType = self.encodeBitsType;
    model.uploadURL = self.uploadURL;
    model.exportVideoDuration = self.exportVideoDuration;
    model.uploadSpeedIndex = self.uploadSpeedIndex;
    return model;
}

- (NSMutableDictionary *)videoComposeQualityTraceInfo
{
    ACCRepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    
    AVAssetTrack *videoTrack = [videoData.videoAssets.firstObject tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGSize videoSize = videoTrack.naturalSize;
    NSString *size = [NSString stringWithFormat:@"%@*%@",@(videoSize.width),@(videoSize.height)];
    NSString *fileBitRate = [NSString stringWithFormat:@"%.0f",videoTrack.estimatedDataRate / 1000.f]; //kbps
    NSString *durationStr = [NSString stringWithFormat:@"%.1f", videoData.totalVideoDuration * 1000]; //ms

    NSMutableDictionary *resultParams = @{@"source_fps":@(videoInfoModel.fps),
                                          @"source_resolution":size,
                                          @"source_file_bitrate":fileBitRate,
                                          @"source_file_size":@"",
                                          @"source_duration":durationStr}.mutableCopy;
    if (self.uploadURL) {
        AVAsset *asset = [AVAsset assetWithURL:self.uploadURL];
        AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (videoTrack) {
            CGSize videoSize = videoTrack.naturalSize;
            NSString *size = [NSString stringWithFormat:@"%@*%@",@(videoSize.width),@(videoSize.height)];
            NSString *fileBitRate = [NSString stringWithFormat:@"%.0f",videoTrack.estimatedDataRate / 1000.f]; //kbps
            NSString *settingBitRate = [NSString stringWithFormat:@"%.0f",videoData.transParam.bitrate / 1000.f]; //kbps
            NSString *durationStr = [NSString stringWithFormat:@"%.1f", CMTimeGetSeconds(asset.duration) * 1000]; //ms

            [resultParams addEntriesFromDictionary:@{@"compose_fps":@(videoTrack.nominalFrameRate),
                                                     @"compose_resolution":size,
                                                     @"compose_file_bitrate":fileBitRate,
                                                     @"compose_file_size":@(self.uploadFileSize),
                                                     @"compose_file_duration":durationStr,
                                                     @"compose_bitrate":settingBitRate}];
        }
    }
    resultParams[@"select_gear_by_upload_speed"] = self.uploadSpeedIndex;
    return resultParams;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *dict = [super acc_publishRequestParams:publishViewModel].mutableCopy;
    [dict addEntriesFromDictionary:@{
        @"encode_bits_type" : @(self.encodeBitsType),
        @"encode_hdr_type" : @(self.encodeHdrType),
        @"is_h265" : @(self.isByteVC1),
    }];
    return dict;
}

- (NSDictionary *)acc_publishTrackEventParams:(AWEVideoPublishViewModel *)publishViewModel
{
    ACCRepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    
    AVAssetTrack *videoTrack = [videoData.videoAssets.firstObject tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGSize videoSize = videoTrack.naturalSize;
    NSString *size = [NSString stringWithFormat:@"%@*%@",@(videoSize.width),@(videoSize.height)];
    NSString *fileBitRate = [NSString stringWithFormat:@"%.0f",videoTrack.estimatedDataRate / 1000.f]; //kbps
    NSString *durationStr = [NSString stringWithFormat:@"%.1f", videoData.totalVideoDuration * 1000]; //ms
    
    return @{@"source_fps":@(videoInfoModel.fps),
             @"source_resolution":size,
             @"source_file_bitrate":fileBitRate,
             @"source_file_size":@"",
             @"source_duration":durationStr}.mutableCopy;
}

@end

//
//  ACCCountDownViewModel.m
//  CameraClient
//
//  Created by guochenxiang on 2020/4/26.
//

#import "ACCCountDownViewModel.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import "ACCCountDownModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/ACCEditVideoDataConsumer.h>
#import <CameraClient/ACCEditVideoDataFactory.h>
#import <CreationKitArch/ACCRepoDraftModel.h>

static NSString * const kAWEDelayRecordMode = @"kAWEDelayRecordMode";

@interface ACCCountDownViewModel ()

@end

@implementation ACCCountDownViewModel

@synthesize delayRecordMode = _delayRecordMode;
@synthesize countDownModel = _countDownModel;

#pragma mark - Life Cycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

#pragma mark - getter setter

- (AVAsset *)musicAsset
{
    if (self.inputData.publishModel.repoDuet.isDuet) {
        AVAsset *asset = [AVAsset assetWithURL:self.inputData.publishModel.repoDuet.duetLocalSourceURL];
        return asset;
    }
    return self.inputData.publishModel.repoMusic.bgmAsset;
}

- (void)setDelayRecordMode:(AWEDelayRecordMode)delayRecordMode
{
    _delayRecordMode = delayRecordMode;
    [ACCCache() setObject:@(delayRecordMode) forKey:kAWEDelayRecordMode];
}

- (ACCCountDownModel *)countDownModel
{
    if (!_countDownModel) {
        _countDownModel = [[ACCCountDownModel alloc] init];
        _countDownModel.toBePlayedLocation = 1;
    }
    return _countDownModel;
}

#pragma mark -

//获取缓存的delay模式
- (void)configDelayRecordMode
{
    NSNumber *delayMode = [ACCCache() objectForKey:kAWEDelayRecordMode];
    if (delayMode != nil) {
        self.delayRecordMode = [delayMode integerValue];
    } else {
        self.delayRecordMode = AWEDelayRecordMode3S;
    }
}

# pragma mark - Volumes Converter

- (NSArray<NSNumber *> *)convertVolumesWithPoints:(NSArray<NSNumber *> * _Nullable)points barCount:(NSInteger)barCount assetDuration:(CGFloat)assetDuration shouldCount:(NSInteger)shouldCount shouldConvert:(BOOL)shouldConvert
{
    NSMutableArray *volumes = [NSMutableArray arrayWithCapacity:barCount];

    if (shouldConvert) {
        BOOL isVolumeDataValid = NO;
        for (NSNumber *point in points) {
            CGFloat volume = [point floatValue];
            if (volume > 0) {
                isVolumeDataValid = YES;
                break;
            }
        }

        if (!isVolumeDataValid) {
            CGFloat currentHeight = 0;
            BOOL increasing = YES;
            for (int i = 0; i < barCount; i++) {
                NSNumber *volumeNumber = [NSNumber numberWithFloat:currentHeight];
                [volumes addObject:volumeNumber];

                if (currentHeight <= 0.875 && increasing) {
                    currentHeight += 0.125;
                } else if (currentHeight > 0.875 && increasing) {
                    currentHeight -= 0.125;
                    increasing = NO;
                } else if (currentHeight >= 0.125 && !increasing) {
                    currentHeight -= 0.125;
                } else if (currentHeight <= 0.125 && !increasing) {
                    increasing = YES;
                    currentHeight += 0.125;
                }
            }
        } else {
            volumes = [points mutableCopy];
        }
    } else {
        // 48 - 4 = 44 11 5 9 ( 8 * 4 * 10)
        // 0 0.25 0.5 0.75 1.0 0.75 0.5 0.25 0 8个点
        NSInteger smallBarCount = barCount / 8;
        NSInteger leftCount = barCount - (smallBarCount * 8);

        for (int i = 0; i < leftCount / 2; i++) {
            NSNumber *volumeNumber = [NSNumber numberWithFloat:0];
            [volumes addObject:volumeNumber];
        }

        CGFloat currentHeight = 0;
        BOOL increasing = YES;
        for (NSInteger i = leftCount / 2; i < leftCount/2 + smallBarCount * 8; i++) {
            NSNumber *volumeNumber = [NSNumber numberWithFloat:currentHeight];
            [volumes addObject:volumeNumber];
            if (currentHeight <= 0.8 && increasing) {
                currentHeight += 0.25;
            } else if (currentHeight > 0.8 && increasing) {
                currentHeight -= 0.25;
                increasing = NO;
            } else if (currentHeight >= 0.25 && !increasing) {
                currentHeight -= 0.25;
            } else if (currentHeight <= 0.25 && !increasing) {
                increasing = YES;
                currentHeight += 0.25;
            }
        }

        for (NSInteger i = smallBarCount * 8 + leftCount / 2; i < barCount; i++) {
            NSNumber *volumeNumber = [NSNumber numberWithFloat:0];
            [volumes addObject:volumeNumber];
        }
    }

    HTSAudioRange audioRange = self.inputData.publishModel.repoMusic.audioRange;
    NSInteger startPosition = 0;
    barCount = volumes.count;

    if (isnan(audioRange.location) || audioRange.location < 0 || assetDuration <= 0) {
        startPosition = 0;
    } else if (!isnan(assetDuration)) {
        startPosition = (NSInteger)(ceil(audioRange.location * barCount / assetDuration));
    }

    if (startPosition >= barCount) {
        startPosition = 0;
    }

    NSArray *showVolumes = [volumes subarrayWithRange:NSMakeRange(startPosition, barCount - startPosition > shouldCount ? shouldCount : barCount - startPosition)];
    return showVolumes;
}

- (NSArray<NSNumber *> *)normalizePointsData:(NSArray<NSNumber *> *)originalData
{
    NSMutableArray *normalziedData = originalData.mutableCopy;
    double maxPoint = 0;
    for (NSNumber *point in originalData) {
        if (ABS(point.doubleValue) > maxPoint) {
            maxPoint = ABS(point.doubleValue);
        }
    }

    if (maxPoint > 0.f) {
        for (int i = 0; i < originalData.count; i++) {
            normalziedData[i] = @(originalData[i].doubleValue / maxPoint);
        }
    }

    return [normalziedData copy];
}

- (void)showVolumesWithShouldCount:(NSInteger)shouldCount completion:(void(^)(NSArray<NSNumber *> *volumes))completion
{
    AVAsset *asset = [self musicAsset];
    CGFloat assetDuration = CMTimeGetSeconds(asset.duration);

    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    CGFloat maxLength = [config standardVideoMaxSeconds];
    CGFloat currentLength = CMTimeGetSeconds(asset.duration);
    if (currentLength < maxLength || isnan(currentLength)) {
        currentLength = maxLength;
    }

    NSInteger barCount = 0;
    if (maxLength > 0) {
        barCount = (NSInteger)(ceil(shouldCount * currentLength / maxLength));
    }

    CGFloat musicLength = CMTimeGetSeconds(asset.duration);

    BOOL isDuet = self.inputData.publishModel.repoDuet.isDuet;
    NSURL *assetURL = isDuet ? self.inputData.publishModel.repoDuet.duetLocalSourceURL : self.inputData.publishModel.repoMusic.music.loaclAssetUrl;
    BOOL shouldConvert = assetURL && musicLength > 0 && !isnan(musicLength);

    if (shouldConvert) {
        // should convert audio/video into points data
        if (isDuet) {
            // Video Converter
            AVAsset *asset = [AVAsset assetWithURL:assetURL];
            ACCEditVideoData *videoData = [ACCEditVideoDataFactory videoDataWithVideoAsset:asset cacheDirPath:self.inputData.publishModel.repoDraft.draftFolder];
            
            [ACCEditVideoDataConsumer getVolumnWaveWithVideoData:videoData pointsCount:barCount completion:^(NSArray * _Nullable values, NSError * _Nullable error) {
                if (!error) {
                    NSArray<NSNumber *> *showVolumes = [self convertVolumesWithPoints:[self normalizePointsData:values]
                                                                             barCount:barCount
                                                                        assetDuration:assetDuration
                                                                          shouldCount:shouldCount
                                                                        shouldConvert:YES];
                    if (completion) {
                        completion(showVolumes);
                    }
                } else {
                    // handle error while converting video to points data
                    AWELogToolError(AWELogToolTagRecord, @"error when IESVideoVolumConvert instance starts the process, %s %@", __PRETTY_FUNCTION__, error);
                }
            }];
        } else {
            NSArray *points = [ACCEditVideoDataConsumer getVolumnWaveWithAudioURL:assetURL waveformduration:currentLength pointsCount:barCount];
            NSArray<NSNumber *> *showVolumes = [self convertVolumesWithPoints:points
                                                                     barCount:barCount
                                                                assetDuration:assetDuration
                                                                  shouldCount:shouldCount
                                                                shouldConvert:YES];
            if (completion) {
                completion(showVolumes);
            }
        }
    } else {
        // should not convert audio/video into points data
        NSArray<NSNumber *> *showVolumes = [self convertVolumesWithPoints:NULL
                                                                 barCount:barCount
                                                            assetDuration:assetDuration
                                                              shouldCount:shouldCount
                                                            shouldConvert:shouldConvert];
        if (completion) {
            completion(showVolumes);
        }
    }
}

@end

//
//  ACCAudioExport.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/15.
//

#import "ACCAudioExport.h"
#import "ACCEditVideoDataDowngrading.h"
#import <TTVideoEditor/HTSAudioExport.h>

@interface ACCAudioExport()

@property (nonatomic, strong) HTSAudioExport *veAudioExport;

@end
@implementation ACCAudioExport

- (instancetype)init
{
    self = [super init];
    if (self) {
        _veAudioExport = [[HTSAudioExport alloc] init];
    }
    return self;
}

- (void)exportAllAudioSoundInVideoData:(ACCEditVideoData *)videoData
                            completion:(void (^)(NSURL * _Nullable, NSError * _Nullable))completion
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [self.veAudioExport exportAllAudioSoundInVideoData:videoData
                                                completion:completion];
    }, ^(ACCNLEEditVideoData *videoData) {
        // 音频导出目前不支持 NLE，不能走此逻辑
        NSAssert(NO, @"audio export not support nle");
    });
}

- (void)cancelAudioExport
{
    [self.veAudioExport cancelAudioExport];
}

@end

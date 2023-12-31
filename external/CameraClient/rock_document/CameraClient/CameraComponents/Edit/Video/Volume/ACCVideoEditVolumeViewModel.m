//
//  ACCVideoEditVolumeViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2020/8/10.
//

#import "ACCVideoEditVolumeViewModel.h"

@interface ACCVideoEditVolumeViewModel ()

@property (nonatomic, strong) RACSubject *checkMusicFeatureToastSubject;

@end

@implementation ACCVideoEditVolumeViewModel

- (void)dealloc
{
    [_checkMusicFeatureToastSubject sendCompleted];
}

- (void)sendCheckMusicFeatureToastSignal
{
    [self.checkMusicFeatureToastSubject sendNext:nil];
}

#pragma - mark Getters

- (RACSignal *)checkMusicFeatureToastSignal
{
    return self.checkMusicFeatureToastSubject;
}

- (RACSubject *)checkMusicFeatureToastSubject
{
    if (!_checkMusicFeatureToastSubject) {
        _checkMusicFeatureToastSubject = [RACSubject subject];
    }
    return _checkMusicFeatureToastSubject;
}

@end

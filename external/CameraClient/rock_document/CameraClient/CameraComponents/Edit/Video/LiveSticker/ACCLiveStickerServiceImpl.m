//
//  ACCLiveStickerServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/1/29.
//

#import "ACCLiveStickerServiceImpl.h"

@implementation ACCLiveStickerServiceImpl

- (void)dealloc
{
    [self.toggleEditingViewSubject sendCompleted];
}

- (RACSignal<NSNumber *> *)toggleEditingViewSignal
{
    return self.toggleEditingViewSubject;
}

- (RACSubject<NSNumber *> *)toggleEditingViewSubject
{
    if (!_toggleEditingViewSubject) {
        _toggleEditingViewSubject = [RACSubject<NSNumber *> subject];
    }
    return _toggleEditingViewSubject;
}

@end

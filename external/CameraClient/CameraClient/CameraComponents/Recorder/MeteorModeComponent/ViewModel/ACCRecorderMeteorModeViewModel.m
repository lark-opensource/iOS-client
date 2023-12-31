//
//  ACCRecorderMeteorModeViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/11.
//

#import "ACCRecorderMeteorModeViewModel.h"

@interface ACCRecorderMeteorModeViewModel ()

@property (nonatomic, strong) RACSubject<NSNumber *> *didChangeMeteorModeSubject;

@end

@implementation ACCRecorderMeteorModeViewModel

- (void)dealloc
{
    [_didChangeMeteorModeSubject sendCompleted];
}

- (void)sendDidChangeMeteorModeSignal:(BOOL)isMeteorModeOn
{
    [self.didChangeMeteorModeSubject sendNext:@(isMeteorModeOn)];
}

#pragma mark - Getters

- (RACSignal<NSNumber *> *)didChangeMeteorModeSignal
{
    return self.didChangeMeteorModeSubject;
}

- (RACSubject<NSNumber *> *)didChangeMeteorModeSubject
{
    if (!_didChangeMeteorModeSubject) {
        _didChangeMeteorModeSubject = [RACSubject subject];
    }
    return _didChangeMeteorModeSubject;
}

@end

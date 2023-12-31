//
//  ACCSpecialEffectViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/8/7.
//

#import "ACCSpecialEffectViewModel.h"

@interface ACCSpecialEffectViewModel ()

@property (nonatomic, strong, readwrite) RACSignal *willDismissVCSignal;
@property (nonatomic, strong, readwrite) RACSubject *willDismissVCSubject;

@end

@implementation ACCSpecialEffectViewModel

- (void)dealloc
{
    [_willDismissVCSubject sendCompleted];
}

- (void)sendWillDismissVCSignal
{
    [self.willDismissVCSubject sendNext:nil];
}

- (RACSignal *)willDismissVCSignal
{
    return self.willDismissVCSubject;
}

- (RACSubject *)willDismissVCSubject
{
    if (!_willDismissVCSubject) {
        _willDismissVCSubject = [RACSubject subject];
    }
    return _willDismissVCSubject;
}


@end

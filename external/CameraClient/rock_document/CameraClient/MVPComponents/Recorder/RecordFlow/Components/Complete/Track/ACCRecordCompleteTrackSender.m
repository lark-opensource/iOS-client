//
//  ACCRecordCompleteTrackSender.m
//  CameraClient
//
//  Created by haoyipeng on 2022/2/17.
//

#import "ACCRecordCompleteTrackSender.h"
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCRecordCompleteTrackSender()

@property (nonatomic, strong) RACSubject *completeButtonDidClickedSubject;

@end

@implementation ACCRecordCompleteTrackSender

- (void)sendCompleteButtonClickedSignal
{
    [self.completeButtonDidClickedSubject sendNext:nil];
}

- (void)dealloc
{
    [self.completeButtonDidClickedSubject sendCompleted];
}

- (RACSignal *)completeButtonDidClickedSignal
{
    return self.completeButtonDidClickedSubject;
}

- (RACSubject *)completeButtonDidClickedSubject
{
    if (!_completeButtonDidClickedSubject) {
        _completeButtonDidClickedSubject = [[RACSubject alloc] init];
    }
    return _completeButtonDidClickedSubject;
}

@end

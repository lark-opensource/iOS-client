//
//  ACCAdvancedRecordSettingServiceImpl.m
//  Indexer
//
//  Created by Shichen Peng on 2021/11/2.
//

#import "ACCAdvancedRecordSettingServiceImpl.h"

@interface ACCAdvancedRecordSettingServiceImpl ()

@end

@implementation ACCAdvancedRecordSettingServiceImpl

@synthesize delegate = _delegate;
@synthesize subscription = _subscription;

#pragma mark - subscription

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCAdvancedRecordSettingServiceSubScriber>)subscriber {
    [self.subscription addSubscriber:subscriber];
}

- (void)removeSubscriber:(id<ACCAdvancedRecordSettingServiceSubScriber>)subscriber
{
    [self.subscription removeSubscriber:subscriber];
}

@end

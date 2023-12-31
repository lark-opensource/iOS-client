//
//  ACCAction.m
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import "ACCAction.h"

@interface ACCAction ()
@end

@implementation ACCAction
+ (instancetype)action
{
    return [[self alloc] init];
}

+ (instancetype)fulfilled
{
    ACCAction *action = [self action];
    [action fulfill];
    return action;
}

+ (instancetype)rejected
{
    ACCAction *action = [self action];
    [action reject];
    return action;
}

- (ACCAction *)fulfill
{
    NSAssert(self.status == ACCActionStatusPending, @"action fullfilled/rejected already");
    
    @synchronized (self) {
        _status = ACCActionStatusSucceeded;
    }
    return self;
}

- (ACCAction *)reject
{
    NSAssert(self.status == ACCActionStatusPending, @"action fulfilled/rejected already");
    
    @synchronized (self) {
        _status = ACCActionStatusFailed;
    }
    return self;
}
@end


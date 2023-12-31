//
//  ACCRecordGestureServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/2/28.
//

#import "ACCRecordGestureServiceImpl.h"
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCRecordGestureServiceImpl()

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@end

@implementation ACCRecordGestureServiceImpl

@synthesize gesturesSet = _gesturesSet;
@synthesize sdkGesturesAction = _sdkGesturesAction;

- (NSArray<UIGestureRecognizer *> *)gesturesNeedAdded
{
    @weakify(self);
    NSMutableArray *componentGestures = [NSMutableArray array];
    [self.subscription performEventSelector:@selector(gesturesWillAdded) realPerformer:^(id<ACCRecordGestureServiceSubscriber> handler) {
        @strongify(self);
        NSArray <UIGestureRecognizer *>*gestures = [handler gesturesWillAdded];
        [self.gesturesSet addObjectsFromArray:gestures];
        [componentGestures addObjectsFromArray:gestures];
    }];
    return componentGestures;
}

- (void)addSubscriber:(id<ACCRecordGestureServiceSubscriber>)subscriber {
    [self.subscription addSubscriber:subscriber];
}

- (void)disableAllGestures
{
    for (UIGestureRecognizer *g in self.gesturesSet) {
        g.enabled = NO;
    }
    
    [self.subscription performEventSelector:@selector(gesturesWillDisabled) realPerformer:^(id<ACCRecordGestureServiceSubscriber> handler) {
        [handler gesturesWillDisabled];
    }];
}

- (void)enableAllGestures
{
    for (UIGestureRecognizer *g in self.gesturesSet) {
        g.enabled = YES;
    }
    
    [self.subscription performEventSelector:@selector(gesturesWillEnable) realPerformer:^(id<ACCRecordGestureServiceSubscriber> handler) {
        [handler gesturesWillEnable];
    }];
}

- (void)gestureDidRecognized:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        [self.subscription performEventSelector:@selector(tapGestureDidRecognized:) realPerformer:^(id<ACCRecordGestureServiceSubscriber> handler) {
            [handler tapGestureDidRecognized:(UITapGestureRecognizer *)gesture];
        }];
    } else if ([gesture isKindOfClass:[UIPinchGestureRecognizer class]]) {
        [self.subscription performEventSelector:@selector(pinchGestureDidRecognized:) realPerformer:^(id<ACCRecordGestureServiceSubscriber> handler) {
            [handler pinchGestureDidRecognized:(UIPinchGestureRecognizer *)gesture];
        }];
    }
    else if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]){
        [self.subscription performEventSelector:@selector(longPressGestureDidRecognized:) realPerformer:^(id<ACCRecordGestureServiceSubscriber> handler) {
            [handler longPressGestureDidRecognized:(UILongPressGestureRecognizer *)gesture];
        }];
    }
}

- (void)gesturesOnReceivedTouch
{
    [self.subscription performEventSelector:@selector(gesturesOnReceivedTouch) realPerformer:^(id<ACCRecordGestureServiceSubscriber> handler) {
        [handler gesturesOnReceivedTouch];
    }];
}

#pragma mark - getter

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (NSMutableSet *)gesturesSet {
    if (!_gesturesSet) {
        _gesturesSet = [[NSMutableSet alloc] init];
    }
    return _gesturesSet;
}

@end

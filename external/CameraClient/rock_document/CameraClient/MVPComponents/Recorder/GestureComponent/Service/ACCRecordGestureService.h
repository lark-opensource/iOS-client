//
//  ACCRecordGestureService.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/2/28.
//

#ifndef ACCRecordGestureService_h
#define ACCRecordGestureService_h

@protocol ACCRecordGestureServiceSubscriber <NSObject>

@optional
- (NSArray <UIGestureRecognizer *>*)gesturesWillAdded;

- (void)gesturesWillDisabled;
- (void)gesturesWillEnable;

- (void)gesturesOnReceivedTouch;

- (void)tapGestureDidRecognized:(UITapGestureRecognizer *)tap;
- (void)pinchGestureDidRecognized:(UIPinchGestureRecognizer *)pinch;
- (void)longPressGestureDidRecognized:(UILongPressGestureRecognizer *)longPress;

@end

typedef NS_ENUM(NSInteger, ACCRecordGestureAction)
{
    ACCRecordGestureActionNone,
    ACCRecordGestureActionDisable,
    ACCRecordGestureActionRecover,
};

@protocol ACCRecordGestureService <NSObject>

@property (nonatomic, strong) NSMutableSet *gesturesSet;
@property (nonatomic, assign) ACCRecordGestureAction sdkGesturesAction;

- (NSArray <UIGestureRecognizer *>*)gesturesNeedAdded;

- (void)disableAllGestures;
- (void)enableAllGestures;

- (void)gesturesOnReceivedTouch;
- (void)gestureDidRecognized:(UIGestureRecognizer *)gesture;

- (void)addSubscriber:(id<ACCRecordGestureServiceSubscriber>)subscriber;

@end

#endif /* ACCRecordGestureService_h */

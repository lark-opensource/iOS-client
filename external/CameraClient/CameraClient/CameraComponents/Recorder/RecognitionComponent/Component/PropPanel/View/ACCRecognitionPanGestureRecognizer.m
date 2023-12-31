//
//  ACCExposePanGestureRecognizer.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/6.
//

#import "ACCRecognitionPanGestureRecognizer.h"

typedef NS_ENUM(NSUInteger, ACCGestureType) {
    ACCGestureTypeTap = 0,
    ACCGestureTypePan
};

@interface ACCRecognitionPanGestureRecognizer()

@property (nonatomic, strong) UITouch *trackingTouch;
@property (nonatomic, assign) CGPoint originPoint;
@property (nonatomic, strong) NSTimer *recognizeTimer;
@property (nonatomic, assign) CGFloat movementJitterThreshold;
@property (nonatomic, assign) NSTimeInterval recognizeDuration;
@property (nonatomic, assign) ACCGestureType gestureType;

@property (nonatomic, strong) NSSet<UITouch *> *lastTouches;
@property (nonatomic, strong) UIEvent *lastEvent;

@end

@implementation ACCRecognitionPanGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        self.movementJitterThreshold = 0.5;
        self.recognizeDuration = 0.15;
        self.gestureType = ACCGestureTypeTap;
    }
    return self;
}

- (CGPoint)movement
{
    CGPoint location = [self.trackingTouch locationInView:self.view];
    return CGPointMake(location.x - self.originPoint.x, location.y - self.originPoint.y);
}

- (BOOL)isTapPossible
{
    return self.state == UIGestureRecognizerStatePossible;
}

- (void)setState:(UIGestureRecognizerState)state
{
    [super setState:state];
    if (self.recognizeTimer != nil && ![self isTapPossible]) {
        [self resetDataForTouchRecognizer];
    }
}

- (void)recognizeTap
{
    if ([self isTapPossible]) {
        self.gestureType = ACCGestureTypeTap;
        self.state = UIGestureRecognizerStateBegan;
        [self.innerTouchDelegateView touchesBegan:self.lastTouches withEvent:self.lastEvent];
    }
}

- (UISwipeGestureRecognizerDirection)directionOfMovement:(CGPoint)movement
{
    if (movement.x == 0 && movement.y == 0) {
        return 0;
    }
    BOOL upperRight = movement.x >= movement.y;
    BOOL lowerRight = movement.x >= -movement.y;
    if (upperRight && lowerRight) {
        return UISwipeGestureRecognizerDirectionRight;
    } else if (upperRight && !lowerRight) {
        return UISwipeGestureRecognizerDirectionUp;
    } else if (!upperRight && lowerRight) {
        return UISwipeGestureRecognizerDirectionDown;
    } else {
        return UISwipeGestureRecognizerDirectionLeft;
    }
}

#pragma mark - Touch event
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.trackingTouch == nil && event.allTouches.count == 1) {
        self.trackingTouch = touches.anyObject;
        self.originPoint = [self.trackingTouch locationInView:self.view];
        CGPoint point = [self.view convertPoint:self.originPoint toView:self.innerTouchDelegateView];
        if ([self.innerTouchDelegateView hitTest:point withEvent:event] != self.innerTouchDelegateView) {
            self.state = UIGestureRecognizerStateFailed;
            return;
        }
        // try to setup data for recognized as touch, not pan gesture
        self.lastEvent = event;
        self.lastTouches = touches;
        self.recognizeTimer = [NSTimer timerWithTimeInterval:self.recognizeDuration target:self selector:@selector(recognizeTap) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.recognizeTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.trackingTouch == nil || ![touches containsObject:self.trackingTouch]) {
        return;
    }
    if (self.state == UIGestureRecognizerStatePossible) {
        CGPoint movement = [self movement];
        UISwipeGestureRecognizerDirection direction = [self directionOfMovement:movement];
        BOOL horizontal = direction & (UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight);
        BOOL vertical = direction & (UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown);
        CGFloat moved = movement.x * movement.x + movement.y * movement.y > self.movementJitterThreshold;
        if (!moved) {
            // pass
            self.lastEvent = event;
            self.lastTouches = touches;
        } else if (horizontal) {
            self.state = UIGestureRecognizerStateFailed;
        } else if (vertical) {
            self.gestureType = ACCGestureTypePan;
            self.state = UIGestureRecognizerStateBegan;
        }
    }
    if ((self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) && self.gestureType == ACCGestureTypeTap) {
        [self.innerTouchDelegateView touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.trackingTouch == nil || ![touches containsObject:self.trackingTouch]) {
        return;
    }
    if (self.state == UIGestureRecognizerStatePossible) {
        if (self.gestureType == ACCGestureTypeTap) {
            [self recognizeTap];
        } else {
            // touch ends before gesture recognized, send a "state began" message along with "state end"
            self.state = UIGestureRecognizerStateBegan;
        }
    }
    if (self.gestureType == ACCGestureTypeTap) {
        [self.innerTouchDelegateView touchesEnded:touches withEvent:event];
        [self resetDataForTouchRecognizer];
    }
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.trackingTouch == nil || ![touches containsObject:self.trackingTouch]) {
        return;
    }
    if (self.gestureType == ACCGestureTypeTap) {
        [self.innerTouchDelegateView touchesCancelled:touches withEvent:event];
        [self resetDataForTouchRecognizer];
    }
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)resetDataForTouchRecognizer
{
    _lastTouches = nil;
    _lastEvent = nil;
    [self.recognizeTimer invalidate];
    self.recognizeTimer = nil;
}

- (void)reset
{
    self.gestureType = ACCGestureTypeTap;
    self.trackingTouch = nil;
    [self resetDataForTouchRecognizer];
}

@end

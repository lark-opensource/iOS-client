//
//  BDPXScreenNavigationBar.h
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/28.
//

#import "BDPDirectionPanGestureRecognizer.h"

@interface BDPDirectionPanGestureRecognizer()<UIGestureRecognizerDelegate>
@property(nonatomic, strong) NSPointerArray *delegates;
@property(nonatomic, assign) BOOL isStartFromEdge;
@end

@implementation BDPDirectionPanGestureRecognizer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.maximumNumberOfTouches = 1;
    self.allowDirection = kBDPDirectionPanGestureRecognizerDirectionLTR;
    self.mode = kBDPDirectionPanGestureRecognizerModeFullScreen;
    self.delegates = [NSPointerArray weakObjectsPointerArray];
    self.isStartFromEdge = NO;
    self.cancelsTouchesInView = NO;
}

- (void)setDelegate:(id<UIGestureRecognizerDelegate>)delegate
{
    [self.delegates compact];
    while (self.delegates.count > 0) {
        [self.delegates removePointerAtIndex:0];
    }
    
    if (delegate) {
        [self.delegates addPointer:(__bridge void * _Nullable)(delegate)];
        [super setDelegate:self];
    }else{
        [super setDelegate:nil];
    }
}

- (BOOL)isEdgeGestureRecognizer
{
    const CGFloat threshold = 80;
    CGPoint point = [self locationInView:self.view.window];
    CGRect screen = [[UIScreen mainScreen] bounds];
    if (self.allowDirection & kBDPDirectionPanGestureRecognizerDirectionTTB) {
        if (point.y > threshold) {
            return NO;
        }
    }else if(self.allowDirection & kBDPDirectionPanGestureRecognizerDirectionLTR) {
        if (point.x > threshold) {
            return NO;
        }
    }else if(self.allowDirection & kBDPDirectionPanGestureRecognizerDirectionBTT) {
        if (point.y < CGRectGetMaxY(screen) - threshold) {
            return NO;
        }
    }else if(self.allowDirection & kBDPDirectionPanGestureRecognizerDirectionRTL) {
        if (point.x < CGRectGetMaxX(screen) - threshold) {
            return NO;
        }
    }
    return self.mode != kBDPDirectionPanGestureRecognizerModeIgnore;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (self.state == UIGestureRecognizerStateBegan) {
        CGPoint velocity = [self velocityInView:self.view];
        self.isStartFromEdge = [self isEdgeGestureRecognizer];
        if(self.mode == kBDPDirectionPanGestureRecognizerModeIgnore) {
            self.state = UIGestureRecognizerStateCancelled;
        }else if(self.mode == kBDPDirectionPanGestureRecognizerModeScreenEdge) {
            if (!self.isStartFromEdge) {
                self.state = UIGestureRecognizerStateCancelled;
            }
        }
        
        BDPDirectionPanGestureRecognizerDirection mask = kBDPDirectionPanGestureRecognizerDirectionUnknown;
        BOOL horizontal = fabs(velocity.x) > fabs(velocity.y);
        
        if (horizontal && velocity.x > 0) {
            mask |= kBDPDirectionPanGestureRecognizerDirectionLTR;
        }
        
        if (horizontal && velocity.x < 0) {
            mask |= kBDPDirectionPanGestureRecognizerDirectionRTL;
        }
        
        if (!horizontal && velocity.y > 0) {
            mask |= kBDPDirectionPanGestureRecognizerDirectionTTB;
        }
        
        if (!horizontal && velocity.y < 0) {
            mask |= kBDPDirectionPanGestureRecognizerDirectionBTT;
        }
        
        if (mask == kBDPDirectionPanGestureRecognizerDirectionUnknown || !(mask & self.allowDirection)) {
            self.state = UIGestureRecognizerStateCancelled;
        }
    }
}

- (void)setMode:(BDPDirectionPanGestureRecognizerMode)mode
{
    if (_mode != mode) {
        _mode = mode;
        [self reset];
    }
    self.enabled = (mode != kBDPDirectionPanGestureRecognizerModeIgnore);
}

- (void)reset
{
    [super reset];
    self.isStartFromEdge = NO;
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    for (NSInteger i = 0; i < [self.delegates count]; i++) {
        id<UIGestureRecognizerDelegate> delegate = [self.delegates pointerAtIndex:i];
        if ([delegate respondsToSelector:_cmd]) {
            return [delegate gestureRecognizerShouldBegin:gestureRecognizer];
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    for (NSInteger i = 0; i < [self.delegates count]; i++) {
        id<UIGestureRecognizerDelegate> delegate = [self.delegates pointerAtIndex:i];
        if ([delegate respondsToSelector:_cmd]) {
            return [delegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    for (NSInteger i = 0; i < [self.delegates count]; i++) {
        id<UIGestureRecognizerDelegate> delegate = [self.delegates pointerAtIndex:i];
        if ([delegate respondsToSelector:_cmd]) {
            return [delegate gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    for (NSInteger i = 0; i < [self.delegates count]; i++) {
        id<UIGestureRecognizerDelegate> delegate = [self.delegates pointerAtIndex:i];
        if ([delegate respondsToSelector:_cmd]) {
            return [delegate gestureRecognizer:gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:otherGestureRecognizer];
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    for (NSInteger i = 0; i < [self.delegates count]; i++) {
        id<UIGestureRecognizerDelegate> delegate = [self.delegates pointerAtIndex:i];
        if ([delegate respondsToSelector:_cmd]) {
            return [delegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press
{
    for (NSInteger i = 0; i < [self.delegates count]; i++) {
        id<UIGestureRecognizerDelegate> delegate = [self.delegates pointerAtIndex:i];
        if ([delegate respondsToSelector:_cmd]) {
            return [delegate gestureRecognizer:gestureRecognizer shouldReceivePress:press];
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveEvent:(UIEvent *)event
{
    if (@available(iOS 13.4, *)) {
        for (NSInteger i = 0; i < [self.delegates count]; i++) {
            id<UIGestureRecognizerDelegate> delegate = [self.delegates pointerAtIndex:i];
            if ([delegate respondsToSelector:_cmd]) {
                return [delegate gestureRecognizer:gestureRecognizer shouldReceiveEvent:event];
            }
        }
    }
    return YES;
}

@end

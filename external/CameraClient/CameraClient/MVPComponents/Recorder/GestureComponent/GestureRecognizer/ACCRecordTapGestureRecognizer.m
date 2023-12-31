//
//  ACCRecordTapGestureRecognizer.m
//  CameraClient-Pods-Aweme
//
//  Created by Shichen Peng on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import "ACCRecordTapGestureRecognizer.h"
#import <UIKit/UIKit.h>

@interface ACCRecordTapGestureRecognizer()

@property (nonatomic, assign) NSInteger tapCounter;
@property (nonatomic, assign) NSTimeInterval intervalBetweenTaps; // Control the interval time of consecutive taps.

@end

@implementation ACCRecordTapGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if(self) {
        _tapCounter = 0;
        _intervalBetweenTaps = 0.2;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _tapCounter = _tapCounter + 1;
    
    NSInteger blockCounter = _tapCounter;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_intervalBetweenTaps*NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        if ([self tapCounter] == blockCounter) {
            [self setState:UIGestureRecognizerStateFailed];
        }
    });
    [super touchesEnded:touches withEvent:event];
}

- (void)setIntervalBetweenTaps:(NSTimeInterval)intervalTime
{
    _intervalBetweenTaps = intervalTime;
}

- (void)reset
{
    [super reset];
    _tapCounter = 0;
}
@end

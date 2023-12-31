//
//  CJPayStyleButton+Freeze.m
//  CJPay
//
//  Created by liyu on 2019/11/26.
//

#import "CJPayStyleButton+Freeze.h"

#import <objc/runtime.h>
#import "CJPayUIMacro.h"

@implementation CJPayStyleButton (Freeze)

- (void)freezeFor:(NSInteger)totalInterval {
    if (totalInterval <= 0) {
        return;
    }
    self.enabled = NO;
    
    __block NSInteger remainingTime = totalInterval;
    NSString *originalTitle = [self titleForState:UIControlStateNormal];
    
    dispatch_queue_t timerQueue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
    self.cjButtonFreezeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue);
    dispatch_source_set_timer(self.cjButtonFreezeTimer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
    @CJWeakify(self)
    dispatch_source_set_event_handler(self.cjButtonFreezeTimer, ^{
        @CJStrongify(self)

        if (remainingTime > 0) {
            NSString *title =[NSString stringWithFormat:@"%@（%lds）", originalTitle, (long)remainingTime];
            remainingTime -= 1;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self setTitle:title forState:UIControlStateNormal];
            });

        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_source_cancel(self.cjButtonFreezeTimer);
                [self setTitle:originalTitle forState:UIControlStateNormal];
                self.enabled = YES;
            });

        }
    });
    dispatch_resume(self.cjButtonFreezeTimer);
}

- (void)setCjButtonFreezeTimer:(dispatch_source_t)cjButtonFreezeTimer {
    objc_setAssociatedObject(self, @selector(cjButtonFreezeTimer), cjButtonFreezeTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_source_t)cjButtonFreezeTimer {
    return objc_getAssociatedObject(self, @selector(cjButtonFreezeTimer));
}

@end

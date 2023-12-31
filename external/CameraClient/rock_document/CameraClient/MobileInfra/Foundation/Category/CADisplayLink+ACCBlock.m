//
//  CADisplayLink+ACCBlock.m
//  Pods
//
//  Created by xuzichao on 2019/2/18.
//

#import "CADisplayLink+ACCBlock.h"
#import <objc/runtime.h>

static void *accDisplayLinkInvokeBlockKey = &accDisplayLinkInvokeBlockKey;

typedef void (^ACCDisplayLinkInvokeBlock)(CADisplayLink *);

@interface CADisplayLink ()

@property (nonatomic, copy) ACCDisplayLinkInvokeBlock acc_DisplayLinkInvokeBlock;

@end

@implementation CADisplayLink (ACCBlock)

+ (CADisplayLink *)acc_displayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    if (!block) {
        return nil;
    }
    CADisplayLink *dispLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(acc_handleDispLink:)];
    dispLink.acc_DisplayLinkInvokeBlock = block;
    return dispLink;
}

+ (void)acc_handleDispLink:(CADisplayLink *)dispLink
{
    !dispLink.acc_DisplayLinkInvokeBlock ?: dispLink.acc_DisplayLinkInvokeBlock(dispLink);
}

- (ACCDisplayLinkInvokeBlock)acc_DisplayLinkInvokeBlock
{
    return objc_getAssociatedObject(self, accDisplayLinkInvokeBlockKey);
}

- (void)setAcc_DisplayLinkInvokeBlock:(ACCDisplayLinkInvokeBlock)acc_DisplayLinkInvokeBlock
{
    objc_setAssociatedObject(self, accDisplayLinkInvokeBlockKey, acc_DisplayLinkInvokeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


@end


//
//  CADisplayLink+BDXBlock.m
//  BDXElement
//
//  Created by bill on 2020/3/24.
//

#import "CADisplayLink+BDXBlock.h"
#import <objc/runtime.h>

static void *bdxLinkInvokeBlockKey = &bdxLinkInvokeBlockKey;

typedef void (^BDXLinkInvokeBlock)(CADisplayLink *);

@interface CADisplayLink ()

@property (nonatomic, copy) BDXLinkInvokeBlock bdxInvokeBlock;

@end

@implementation CADisplayLink (BDXBlock)

+ (CADisplayLink *)isBDX_displayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    if (!block) {
        return nil;
    }
    CADisplayLink *dispLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(bdx_handleDispLink:)];
    dispLink.bdxInvokeBlock = block;
    return dispLink;
}

+ (void)bdx_handleDispLink:(CADisplayLink *)dispLink
{
    !dispLink.bdxInvokeBlock ?: dispLink.bdxInvokeBlock(dispLink);
}

- (BDXLinkInvokeBlock)bdxInvokeBlock
{
    return objc_getAssociatedObject(self, bdxLinkInvokeBlockKey);
}

- (void)setBdxInvokeBlock:(BDXLinkInvokeBlock)bdxInvokeBlock
{
    objc_setAssociatedObject(self, bdxLinkInvokeBlockKey, bdxInvokeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

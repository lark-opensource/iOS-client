//
//  BDAutoVerify+Private.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/9/6.
//

#import "BDAutoVerify+Private.h"
#import "BDAutoVerifyConstant.h"
#import "BDAutoVerifyView.h"
#import "BDTuring.h"
#import "BDTuring+Private.h"
#import "BDAutoVerifyView.h"
#import "BDAutoVerifyMaskView.h"

@implementation BDAutoVerify (Private)

@dynamic autoVerifyView;
@dynamic fullAutoVerifyMaskView;
@dynamic turing;
@dynamic type;
@dynamic model;

- (void)startAutoVerify {
    switch (self.type) {
        case BDAutoVerifyViewWebButtonType:
            [self startWebButtonVerify];
            break;
        case BDAutoVerifyViewMaskViewType: {
            [self startMaskViewVerify];
        }
            break;
        default:
            break;
    }
}

- (void)startWebButtonVerify {
    if (self.autoVerifyView != nil) {
        [self.autoVerifyView uploadAutoVerifyData];
    }
}

- (void)startMaskViewVerify {
    [self.turing popVerifyViewWithModel:self.model];
    if ([self.turing.autoVerifyView isKindOfClass:[BDAutoVerifyView class]]) {
        self.autoVerifyView = (BDAutoVerifyView *)self.turing.autoVerifyView;
        self.autoVerifyView.verify = self;
        [self.autoVerifyView.maskView removeFromSuperview];
        //remove fullscreen maskview
        self.autoVerifyView.maskView = self.fullAutoVerifyMaskView;
    }
}


@end

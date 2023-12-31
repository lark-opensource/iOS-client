//
//  BDAccountSealer+Model.m
//  BDTuring
//
//  Created by bob on 2020/7/15.
//

#import "BDAccountSealer+Model.h"
#import "BDAccountSealer+Delegate.h"
#import "BDTuringUIHelper.h"
#import "BDAccountSealModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDAccountSealResult+Creator.h"
#import "BDAccountSealEvent.h"
#import "BDAccountSealConstant.h"
#import "BDTuringCoreConstant.h"
#import "BDAccountSealView.h"

#import "WKWebView+Piper.h"
#import "BDTuringPiper.h"

@implementation BDAccountSealer (Model)

@dynamic isShowSealView;
@dynamic startLoadTime;
@dynamic model;
@dynamic config;

- (void)popWithModel:(BDAccountSealModel *)model {
    self.model = model;
    long long startTime = CFAbsoluteTimeGetCurrent() * 1000;
    self.isShowSealView = YES;
    self.startLoadTime = startTime;
    dispatch_async(dispatch_get_main_queue(), ^{
        [BDTuringUIHelper sharedInstance].supportLandscape = NO;
        CGRect bounds = [UIScreen mainScreen].bounds;
        BDAccountSealView *sealView = [[BDAccountSealView alloc] initWithFrame:bounds];
        sealView.model = model;
        sealView.delegate = self;
        sealView.startLoadTime = startTime;
        sealView.config = self.config;
        [sealView loadSealView];
        [sealView showVerifyView];
    });
}


@end

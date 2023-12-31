//
//  BDAutoVerifyView.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/4.
//

#import "BDAutoVerifyView.h"
#import "BDAutoVerify.h"
#import "BDTuringMacro.h"
#import "BDAutoVerifyDataModel.h"
#import "BDTuring+Private.h"
#import "BDTuringVerifyModel+View.h"
#import "BDTuringVerifyView+Piper.h"
#import "WKWebView+Piper.h"
#import "BDTuringVerifyViewDefine.h"
#import "BDAutoVerifyMaskView.h"
#import "BDTuringVerifyView+UI.h"
#import "BDAutoVerifyModel.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringPiper.h"
#import "BDTuringVerifyConstant.h"
#import "BDAutoVerify+Private.h"

#import <WebKit/WebKit.h>


@interface BDAutoVerifyView ()

@end

@implementation BDAutoVerifyView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.verify = [BDAutoVerify new];
        self.verify.autoVerifyView = self;
        self.webView.frame = frame;
        self.type = self.verify.type;
        if (self.type == BDAutoVerifyViewWebButtonType) {
            self.maskView = [[BDAutoVerifyMaskView alloc] initWithVerify:self.verify frame:self.frame];
            [self addSubview:self.maskView];
            [self bringSubviewToFront:self.maskView];
        } else {
            
        }
    }
    return self;
}

- (void)adjustWebViewPosition {
    [super adjustWebViewPosition];
}

- (void)addGestureForWebView {
    //do nothing
}

- (void)showVerifyView {
    if (self.type == BDAutoVerifyViewMaskViewType) {
        [super showVerifyView];
    } else {
        self.hidden = NO;
    }
}

- (void)uploadAutoVerifyData {
    BDAutoVerifyDataModel *dataModel = self.maskView.dataModel;
    NSDictionary *params = @{
        BDAutoVerifyOperateDuration : @(dataModel.operateDuration),
        BDAutoVerifyForce : @(dataModel.force),
        BDAutoVerifyMajorRadius : @(dataModel.majorRadius),
        BDAutoVerifyClickCoordinate : @[@(dataModel.clickPoint.x),
                                        @(dataModel.clickPoint.y),
                                        @(dataModel.maskViewSize.width),
                                        @(dataModel.maskViewSize.height)],
        BDAutoVerifyClickDuration : @(dataModel.clickDuration),
    };
    [self.webView.turing_piper call:BDTuringAutoVerifyPiperNameVerifyData
                                 msg:BDTuringPiperMsgSuccess
                              params:params
                          completion:^(id  _Nullable result, NSError * _Nullable error) {}];
}

- (void)handleDialogSize:(NSDictionary *)params {
    CGFloat webviewWidth = [params turing_doubleValueForKey:kBDTuringVerifyParamWidth];
    CGFloat webviewHeight = [params turing_doubleValueForKey:kBDTuringVerifyParamHeight];
    
    self.webView.frame = CGRectMake(0, 0, webviewWidth, webviewHeight);
    
    [self adjustWebViewPosition];
}

- (BOOL)isShow {
    if (self.type == BDAutoVerifyViewWebButtonType) {
        return YES;
    }
    return [super isShow];
}

@end

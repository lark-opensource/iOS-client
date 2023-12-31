//
//  BDAutoVerifyView+Piper.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/7.
//

#import "BDAutoVerifyView+Piper.h"
#import "BDTuringVerifyView+Piper.h"
#import "WKWebView+Piper.h"
#import "BDTuringMacro.h"
#import "BDTuringVerifyConstant.h"
#import "BDTuringPiperConstant.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringPiper.h"
#import "NSDictionary+BDTuring.h"
#import "BDAutoVerifyConstant.h"
#import "BDAutoVerifyMaskView.h"
#import "BDAutoVerifyDataModel.h"
#import "BDAutoVerify.h"
#import "BDTuringVerifyModel+Parameter.h"
#import "BDTuringVerifyView+Report.h"
#import "BDTuringVerifyView+Result.h"
#import "BDTuring+Private.h"
#import "BDAutoVerify+Private.h"
#import "BDTuringParameterVerifyModel.h"
#import "BDTuringVerifyModel+Creator.h"

@implementation BDAutoVerifyView (Piper)

- (void)installPiper {
    [super installPiper];
    WKWebView *webView = self.webView;
    [webView turing_installPiper];
    BDTuringPiper *piper = webView.turing_piper;
    BDTuringWeakSelf;
    [piper on:BDTuringAutoVerifyPiperNameVerify callback:^(NSDictionary * _Nullable params, BDTuringPiperOnCallback  _Nullable callback) {
        BDTuringStrongSelf;
        [self handlePiperAutoVerify:params callback:callback];
    }];
    
    [piper on:BDTuringAutoVerifyPiperNameReadyView callback:^(NSDictionary * _Nullable params, BDTuringPiperOnCallback  _Nullable callback) {
        BDTuringStrongSelf;
        [self handlePiperReadyView:params];
    }];
    
    
}

#pragma mark - handle jsb call -

- (void)handlePiperAutoVerify:(NSDictionary *)params callback:(BDTuringPiperOnCallback)callback {
    BDTuringVerifyModel *model = [BDTuringVerifyModel parameterModelWithParameter:[params turing_dictionaryValueForKey:@"params"]];
    BDTuringVerifyResultCallback resultCallback = ^(BDTuringVerifyResult *verify) {
        NSMutableDictionary *result = [NSMutableDictionary new];
        [result setValue:@(verify.status) forKey:kBDTuringVerifyParamResult];
        callback(BDTuringPiperMsgSuccess,result);
    };
    model.callback = resultCallback;
    model.hideLoading = YES;
    [self.verify.turing popVerifyViewWithModel:model];
}

- (void)handlePiperReadyView:(NSDictionary *)params {
    if (self.type == BDAutoVerifyViewWebButtonType) {
        self.maskView.startTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        //start duration calculate
    } else {
        [self uploadAutoVerifyData];
    }
}

- (void)handlePiperVerifyResult:(NSDictionary *)params
                          callback:(BDTuringPiperOnCallback)callback {
    NSUInteger result = [params turing_integerValueForKey:kBDTuringVerifyParamResult];
    if (self.type == BDAutoVerifyViewMaskViewType) {
        [self closeAutoVerifyView];
    }
    if (result == 0) {
        [self.model handleResult:[BDTuringVerifyResult okResult]];
    } else {
        [self.model handleResult:[BDTuringVerifyResult failResult]];
    }
}

- (void)closeAutoVerifyView {
    [self hideVerifyView];
    [self dismissVerifyView];
}

@end

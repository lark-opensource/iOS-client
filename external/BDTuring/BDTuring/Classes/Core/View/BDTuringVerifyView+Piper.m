//
//  BDTuringVerifyView+Piper.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView+Piper.h"
#import "BDTuringVerifyView+Report.h"
#import "BDTuringVerifyView+UI.h"
#import "BDTuringVerifyView+Result.h"
#import "BDTuringVerifyView+Loading.h"

#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyState.h"
#import "BDTuringConfig.h"
#import "WKWebView+Piper.h"
#import "BDTuringPiper.h"
#import "BDTuringMacro.h"
#import "BDTuringVerifyConstant.h"
#import "BDTuringUIHelper.h"
#import "BDTuring+Private.h"
#import "BDTuring+Preload.h"
#import "BDTuringEventService.h"
#import "BDTuringUtility.h"
#import "BDTuringEventConstant.h"


@implementation BDTuringVerifyView (Piper)

- (void)installPiper {
    WKWebView *webView = self.webView;
    [webView turing_installPiper];
    BDTuringPiper *piper = webView.turing_piper;
    BDTuringWeakSelf;
    [piper on:BDTuringVerifyPiperNameOnResult callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handlePiperVerifyResult:params callback:callback];
    }];
    [piper on:BDTuringVerifyPiperNamePageEnd callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handlePiperPageEnd:params callback:callback];
    }];
    [piper on:BDTuringVerifyPiperNameDialogSize callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handlePiperDialogSize:params callback:callback];
    }];

    [piper on:BDTuringVerifyPiperNameGetData callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handlePiperGetData:params callback:callback];
    }];

    [piper on:BDTuringVerifyPiperNameGetTouch callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handlePiperGetTouch:params callback:callback];
    }];
    
    [piper on:BDTuringVerifyPiperNameEventToNative callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handleNativeEventUpload:params callback:callback];
    }];
    
    [piper on:BDTuringVerifyPiperNameH5State callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handleH5State:params callback:callback];
    }];
    
    [piper on:BDTuringVerifyPiperNameThemeSettings callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handlePiperTheme:params callback:callback];
    }];
    [piper on:BDTuringVerifyPiperPreloadVerifyFinish callback:^(NSDictionary * _Nullable params, BDTuringPiperOnCallback  _Nullable callback) {
        BDTuringStrongSelf;
        [self handlePreloadFinish:params callback:callback];
    }];
    
    [piper on:BDTuringVerifyPiperRefreshVerifyViewFinish callback:^(NSDictionary * _Nullable params, BDTuringPiperOnCallback  _Nullable callback) {
        BDTuringStrongSelf;
        [self handleRefreshFinish:params callback:callback];
    }];

    
    [webView onNetworkPiperName:BDTuringVerifyPiperNameNetworkRequest];
}

#pragma mark Piper handler

- (void)handlePiperTheme:(NSDictionary *)params
                   callback:(BDTuringPiperOnCallback)callback {
    if (callback == nil) {
        return;
    }
    
    NSMutableDictionary *theme = [NSMutableDictionary new];
    
    NSDictionary *customTheme = [self customTheme];
    if (BDTuring_isValidDictionary(customTheme)) {
        [theme addEntriesFromDictionary:customTheme];
    }
    
    NSMutableDictionary *text = [NSMutableDictionary new];
    NSDictionary *customText = [self customText];
    if (BDTuring_isValidDictionary(customText)) {
        [text addEntriesFromDictionary:customText];
    }
    
    callback(BDTuringPiperMsgSuccess, @{kBDTuringCustomTheme:theme,kBDTuringCustomText:text});
}



- (void)handleH5State:(NSDictionary *)params
             callback:(BDTuringPiperOnCallback)callback {
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
    if ([params isKindOfClass:[NSDictionary class]]) {
        self.model.state.h5State = params;
    }
}

- (void)handlePiperDialogSize:(NSDictionary *)params
                        callback:(BDTuringPiperOnCallback)callback {
    [self handleDialogSize:params];
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
    [self stopLoadingView];
    self.webView.hidden = NO;
}

- (void)handlePiperVerifyResult:(NSDictionary *)params
                          callback:(BDTuringPiperOnCallback)callback {
    [self handlePiperVerifyResult:params];
    [self handleCallbackResult:params];
    [self hideVerifyView];
    [self scheduleDismissVerifyView];
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
}

- (void)handlePreloadFinish:(NSDictionary *)params
                   callback:(BDTuringPiperOnCallback)callback {
    BDTuring *turing = [BDTuring turingWithConfig:self.config];
    [turing preloadFinishWithVerifyView:self];
    NSMutableDictionary *param = [NSMutableDictionary new];
    long long duration = turing_duration_ms(self.startPreloadTime);
    [param setValue:@(duration) forKey:BDTuringEventParamDuration];
    [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNamePreloadFinish data:param];
}

- (void)handleRefreshFinish:(NSDictionary *)params
                   callback:(BDTuringPiperOnCallback)callback {
    NSMutableDictionary *param = [NSMutableDictionary new];
    long long duration = turing_duration_ms(self.startRefreshTime);
    [param setValue:@(duration) forKey:BDTuringEventParamDuration];
    [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNamePreloadRefreshFinish data:param];
}


- (void)refreshVerifyView {
    self.startRefreshTime = turing_duration_ms(0);
    [self.webView.turing_piper call:BDTuringVerifyPiperRefreshPreloadVerifyView
                                 msg:(BDTuringPiperMsgSuccess)
                              params:nil
                          completion:nil];
}


- (void)closeVerifyView:(NSString *)reason {
    [self hideVerifyView];
    if ([self.webView.turing_piper webOnPiper:BDTuringVerifyPiperNameCallClose]) {
        [self.webView.turing_piper call:BDTuringVerifyPiperNameCallClose
                                     msg:(BDTuringPiperMsgSuccess)
                                  params:@{@"style": reason ?: @""}
                              completion:nil];
    } else {
        [self handleCallbackStatus:self.closeStatus];
    }
    [self scheduleDismissVerifyView];
}

- (void)onOrientationChanged:(NSDictionary *)orientation {
    [self.webView.turing_piper call:BDTuringVerifyPiperNameOrientation
                                 msg:BDTuringPiperMsgSuccess
                              params:orientation
                          completion:nil];
}

@end

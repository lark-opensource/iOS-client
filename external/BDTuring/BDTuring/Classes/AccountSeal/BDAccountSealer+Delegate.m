//
//  BDAccountSealer+Delegate.m
//  BDTuring
//
//  Created by bob on 2020/7/15.
//

#import "BDAccountSealer+Delegate.h"
#import "BDAccountSealer+Model.h"
#import "BDAccountSealEvent.h"
#import "BDTuringCoreConstant.h"
#import "BDAccountSealConstant.h"
#import "BDAccountSealModel.h"
#import "BDAccountSealResult+Creator.h"

@implementation BDAccountSealer (Delegate)

@dynamic eventService;

#pragma mark - BDTuringWebViewDelegate

- (void)webViewDidShow:(BDTuringWebView *)verifyView {
    self.isShowSealView = YES;
}

- (void)webViewDidHide:(BDTuringWebView *)verifyView {
    self.isShowSealView = NO;
}

- (void)webViewDidDismiss:(BDTuringWebView *)verifyView {
    self.model = nil;
}

- (void)webViewLoadDidFail:(BDTuringWebView *)verifyView {
    if (!verifyView.loadingSuccess) {
        self.isShowSealView = NO;
        [verifyView hideVerifyView];
        BDAccountSealResult *result = [BDAccountSealResult new];
        result.resultCode = BDAccountSealResultNetworkError;
        [self.model handleResult:result];
        NSMutableDictionary *param = [NSMutableDictionary new];
        long long duration = CFAbsoluteTimeGetCurrent() * 1000 - self.startLoadTime;
        [param setValue:@(duration) forKey:kBDTuringDuration];
        [self.eventService collectEvent:BDAccountSealEventWebViewFail data:param];
    }
}

- (void)webViewLoadDidSuccess:(BDTuringWebView *)verifyView {
    NSMutableDictionary *param = [NSMutableDictionary new];
    long long duration = CFAbsoluteTimeGetCurrent() * 1000 - self.startLoadTime;
    [param setValue:@(duration) forKey:kBDTuringDuration];
    [self.eventService collectEvent:BDAccountSealEventWebViewSuccess data:param];
}

@end

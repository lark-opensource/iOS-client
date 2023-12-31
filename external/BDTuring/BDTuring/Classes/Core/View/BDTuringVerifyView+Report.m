//
//  BDTuringVerifyView+Report.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView+Report.h"
#import "BDTuringEventService.h"
#import "BDTuringVerifyConstant.h"
#import "WKWebView+Piper.h"
#import "BDTuringPiper.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringUIHelper.h"
#import "BDTuringUtility.h"
#import "BDTuringEventConstant.h"

#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyState.h"

@implementation BDTuringVerifyView (Report)

#pragma mark - BDTuringPiper

- (void)handlePiperGetData:(NSDictionary *)params
                     callback:(BDTuringPiperOnCallback)callback {
    NSDictionary *response = @{kBDTuringVerifyParamData :@[]};
    if (callback) callback(BDTuringPiperMsgSuccess, response);
}

- (void)handlePiperGetTouch:(NSDictionary *)params
                      callback:(BDTuringPiperOnCallback)callback {
    if (callback == nil) {
        return;
    }
    BDTuringEventService *eventCenter = [BDTuringEventService sharedInstance];
    NSDictionary *response = @{kBDTuringVerifyParamTouch    :[eventCenter fetchTouchEvents],
                               kBDTuringOSName :BDTuringOSName,
                               };
    callback(BDTuringPiperMsgSuccess, response);
}

- (void)handleNativeEventUpload:(NSDictionary *)event
                       callback:(BDTuringPiperOnCallback)callback {
    NSString *eventName = [event turing_stringValueForKey:kBDTuringEvent];
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
    [[BDTuringEventService sharedInstance] h5CollectEvent:eventName data:event];
}

- (void)handlePiperPageEnd:(NSDictionary *)params
                     callback:(BDTuringPiperOnCallback)callback {
    [self dismissVerifyView];
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
}

- (void)handlePiperVerifyResult:(NSDictionary *)params {
    BDTuringEventService *eventCenter = [BDTuringEventService sharedInstance];
    
    BDTuringVerifyStatus status = [params turing_integerValueForKey:kBDTuringVerifyParamResult];
    NSString *mode = [params turing_stringValueForKey:kBDTuringMode];
    self.model.state.subType = mode;
    
    long long  duration = turing_duration_ms(self.startLoadTime);
    NSDictionary *reportParam = @{BDTuringEventParamDuration  : @(duration),
                                  BDTuringEventParamResult : @(status)};

    [eventCenter collectEvent:BDTuringEventNameResult data:reportParam];
}


#pragma mark - WebView load

- (void)onWebViewFinish {
    long long  duration = turing_duration_ms(self.startLoadTime);
    NSDictionary *params = @{BDTuringEventParamDuration  : @(duration),
                             BDTuringEventParamResult : @(0)
                             };
    BDTuringEventService *eventCenter = [BDTuringEventService sharedInstance];
    [eventCenter collectEvent:BDTuringEventNameWebView data:params];
}

- (void)onWebViewFailWithError:(NSError *)error {
    long long  duration = turing_duration_ms(self.startLoadTime);
    NSDictionary *params = @{BDTuringEventParamDuration  : @(duration),
                             BDTuringEventParamResult : @(error.code),
                             BDTuringEventParamCustom : error.description ?: @""
                             };
    BDTuringEventService *eventCenter = [BDTuringEventService sharedInstance];
    [eventCenter collectEvent:BDTuringEventNameWebView data:params];
}

- (void)closeEvent:(BDTuringEventCloseReason)reason {
    long long  duration = turing_duration_ms(self.startLoadTime);
    NSDictionary *reportParam = @{BDTuringEventParamDuration  : @(duration),
                                  BDTuringEventParamResult : @(reason)};
    [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNameClose data:reportParam];
}

@end

//
//  BytedCertCorePiperHandler+EventLog.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/10.
//

#import "BDCTCorePiperHandler+EventLog.h"
#import "BDCTEventTracker.h"
#import "BytedCertInterface.h"
#import "BytedCertManager+Piper.h"
#import "BytedCertManager+Private.h"
#import "BDCTLog.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@implementation BDCTCorePiperHandler (EventLog)

- (void)registerSendLog {
    [self registeJSBWithName:@"bytedcert.sendLog" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        [self.flow.eventTracker trackWithEvent:[params btd_stringValueForKey:@"eventName"] params:[params btd_dictionaryValueForKey:@"params"]];
        callback(TTBridgeMsgSuccess, nil, nil);
    }];
}

- (void)registerWebEvent {
    [self registeJSBWithName:@"bytedcert.webEvent" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BDCTLogInfo(@"New event comes from H5: %@", params);
        [BytedCertManager handleWebEventWithParams:params completion:^(BOOL completed, NSDictionary *_Nullable result) {
            callback(
                completed ? TTBridgeMsgSuccess : TTBridgeMsgFailed, [BDCTCorePiperHandler jsbCallbackResultWithParams:result error:(!completed ? [[BytedCertError alloc] initWithType:-1] : nil)], nil);
        }];
    }];
}

- (void)registerUploadEvent {
    [self registeJSBWithName:@"bytedcert.uploadEvent" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BDCTLogInfo(@"New event comes from H5: %@", params);
        if (params == nil || params[@"event"] == nil || params[@"message"] == nil) {
            return;
        }

        NSData *data = [params[@"message"] dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *msgDict = [NSJSONSerialization JSONObjectWithData:data
                                                                options:NSJSONReadingMutableContainers
                                                                  error:nil];
        BDCTLogInfo(@"msgDict = %@", msgDict);

        BytedCertInterface *bytedIf = [BytedCertInterface sharedInstance];
        if ([bytedIf.BytedCertTrackEventDelegate respondsToSelector:@selector(trackWithEvent:params:)]) {
            [bytedIf.BytedCertTrackEventDelegate trackWithEvent:params[@"event"] params:msgDict];
        }
    }];
}

- (void)registerSetCertStatusEvent {
    [self registeJSBWithName:@"bytedcert.setCertStatus" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        self.flow.context.certResult = params.copy;
        callback(TTBridgeMsgSuccess, nil, nil);
    }];
}

@end

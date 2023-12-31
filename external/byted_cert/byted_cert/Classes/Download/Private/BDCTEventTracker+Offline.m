//
//  BDCTEventTracker+Offline.m
//  AFgzipRequestSerializer
//
//  Created by chenzhendong.ok@bytedance.com on 2020/11/27.
//

#import "BDCTEventTracker+Offline.h"
#import "BytedCertWrapper+Download.h"
#import "BytedCertError.h"
#import <IESGeckoKit/IESGeckoKit.h>


@implementation BDCTEventTracker (Offline)

+ (void)trackLocalModelAvailable:(NSString *)channel error:(BytedCertError *)error {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    [mutableParams setValue:channel forKey:@"channel"];
    [mutableParams setValue:@(error.errorCode) forKey:@"error_code"];
    [mutableParams setValue:error.errorMessage forKey:@"error_msg"];
    [self trackWithEvent:@"cert_local_model_status" params:mutableParams.copy];
}

+ (void)trackGeckoResourceSyncResult:(NSDictionary *)result {
    [self trackWithEvent:@"cert_geco_resource_sync_result" params:result];
}

+ (void)trackCertModelUpdateEventWithResult:(NSInteger)result errorMsg:(NSString *)errorMsg {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@(result) forKey:@"result"];
    [params setValue:errorMsg forKey:@"error_msg"];
    [self trackWithEvent:@"cert_model_update" params:params.copy];
}

+ (void)trackcertModelPreloadStartEvent {
    [self trackWithEvent:@"cert_model_preload_start" params:nil];
}

+ (void)trackCertModelPreloadEventWithResult:(NSInteger)result errorMsg:(NSString *)errorMsg {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@(result) forKey:@"error_code"];
    [params setValue:errorMsg forKey:@"error_msg"];
    [self trackWithEvent:@"cert_model_preload" params:params.copy];
}

- (void)trackCertDoStillLivenessEventWithError:(BytedCertError *)error {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@(error ? 0 : 1) forKey:@"result"];
    [params setValue:@(error.detailErrorCode ?: error.errorCode ?:
                                                                  0)
              forKey:@"error_code"];
    [params setValue:(error.detailErrorMessage ?: error.errorMessage ?:
                                                                       @"")
              forKey:@"error_msg"];
    [self trackWithEvent:@"cert_do_still_liveness" params:params.copy];
}

- (void)trackCertOfflineFaceVerifyEventWithError:(BytedCertError *)error {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@(error ? 0 : 1) forKey:@"result"];
    [params setValue:@(error.detailErrorCode ?: error.errorCode ?:
                                                                  0)
              forKey:@"error_code"];
    [params setValue:(error.detailErrorMessage ?: error.errorMessage ?:
                                                                       @"")
              forKey:@"error_msg"];
    [self trackWithEvent:@"cert_offline_face_verify" params:params.copy];
}

@end

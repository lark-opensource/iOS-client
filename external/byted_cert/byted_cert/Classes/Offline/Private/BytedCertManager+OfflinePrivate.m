//
//  BytedCertManager+OfflinePrivate.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import "BytedCertManager+OfflinePrivate.h"
#import "BytedCertError.h"
#import "BDCTOfflineFaceVerificationFlow.h"
#import "BDCTFlowContext.h"
#import "BytedCertManager+Offline.h"
#import <BDAlogProtocol/BDAlogProtocol.h>


@implementation BytedCertManager (OfflinePrivate)

+ (void)p_beginOfflineFaceVerificationWithParameter:(BytedCertOfflineDetectPatameter *)parameter completion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    BDALOG_PROTOCOL_INFO_TAG(BytedCertLogTag, @"Begin offline face verify: image_to_compare=%@]", @(parameter.imageCompare != nil));
    BDCTFlowContext *context = [BDCTFlowContext contextWithParameter:parameter];
    BDCTOfflineFaceVerificationFlow *flow = [[BDCTOfflineFaceVerificationFlow alloc] initWithContext:context];
    flow.completionBlock = completion;
    [flow begin];
}

@end

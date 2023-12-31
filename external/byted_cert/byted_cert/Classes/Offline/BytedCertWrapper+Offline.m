//
//  BytedCertWrapper+Offline.m
//  AFgzipRequestSerializer
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/10.
//

#import "BytedCertWrapper+Offline.h"
#import "BytedCertWrapper+Download.h"
#import "FaceLiveUtils.h"
#import "BDCTEventTracker.h"
#import "BDCTStringConst.h"
#import "BytedCertDefine.h"
#import "BytedCertManager+Offline.h"
#import "BytedCertManager+OfflinePrivate.h"


@implementation BytedCertWrapper (Offline)

- (void)doOfflineFaceLivenessWithParams:(NSDictionary *_Nullable)params
                               callback:(BytedCertFaceLivenessResultBlock)callback {
    BytedCertOfflineDetectPatameter *parameter = [[BytedCertOfflineDetectPatameter alloc] initWithBaseParams:params identityParams:nil];
    [BytedCertManager p_beginOfflineFaceVerificationWithParameter:parameter completion:callback];
}

@end

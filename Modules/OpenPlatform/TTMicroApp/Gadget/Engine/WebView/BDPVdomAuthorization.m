//
//  BDPVdomAuthorization.m
//  Timor
//
//  Created by MacPu on 2019/12/9.
//

#import "BDPVdomAuthorization.h"

@implementation BDPVdomAuthorization

#pragma mark - BDPJSBridgeAuthorizationProtocol

- (void)checkAuthorization:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine completion:(void (^)(BDPAuthorizationPermissionResult))completion
{
    if (completion) {
        completion(BDPAuthorizationPermissionResultEnabled);
    }
}

@end

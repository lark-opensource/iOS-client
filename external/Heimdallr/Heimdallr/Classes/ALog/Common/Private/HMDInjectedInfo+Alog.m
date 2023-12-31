//
//  HMDInjectedInfo+Alog.m
//  Heimdallr
//
//  Created by fengyadong on 2019/1/2.
//

#import "HMDInjectedInfo+Alog.h"
#import "HMDUploadHelper.h"

@implementation HMDInjectedInfo (Alog)

- (NSDictionary *)alogUploadCommonParams {
		if ([HMDInjectedInfo defaultInfo].commonParams) {
				return [HMDInjectedInfo defaultInfo].commonParams;
		}
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params addEntriesFromDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    [params addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
    
    return [params copy];
}

@end

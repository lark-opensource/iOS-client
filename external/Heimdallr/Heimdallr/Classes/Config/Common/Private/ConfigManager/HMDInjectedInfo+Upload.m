//
//  HMDInjectedInfo+Upload.m
//  Heimdallr
//
//  Created by fengyadong on 2018/11/6.
//

#import "HMDInjectedInfo+Upload.h"
#import "HMDUploadHelper.h"

@implementation HMDInjectedInfo (Upload)
- (NSDictionary *)reportHeaderParams {
    return [HMDUploadHelper sharedInstance].headerInfo;
}

- (NSDictionary *)reportCommonParams {
    return self.commonParams;
}

- (BOOL)enableBackgroundUpload {
    return YES;
}

@end

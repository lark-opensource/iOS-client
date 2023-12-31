//
//  HMDFileUploadRequest.m
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/2/28.
//

#import "HMDFileUploadRequest.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDFileUploadRequest

- (NSString *)path {
    return (_path ?: [HMDURLSettings fileUploadPath]);
}

@end

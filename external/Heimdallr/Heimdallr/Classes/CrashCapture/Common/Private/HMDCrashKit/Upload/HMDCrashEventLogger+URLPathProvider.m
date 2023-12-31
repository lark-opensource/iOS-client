//
//  HMDCrashEventLogger+URLPathProvider.m
//  Heimdallr
//
//  Created by Nickyo on 2023/8/3.
//

#import "HMDCrashEventLogger+URLPathProvider.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDCrashEventLogger (URLPathProvider)

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings crashEventUploadPath];
}

@end

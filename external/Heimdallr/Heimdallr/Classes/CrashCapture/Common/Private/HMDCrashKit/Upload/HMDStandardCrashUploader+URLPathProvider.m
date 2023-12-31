//
//  HMDStandardCrashUploader+URLPathProvider.m
//  Heimdallr
//
//  Created by Nickyo on 2023/8/3.
//

#import "HMDStandardCrashUploader+URLPathProvider.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDStandardCrashUploader (URLPathProvider)

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings crashUploadPath];
}

@end

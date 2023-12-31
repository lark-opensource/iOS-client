//
//  HMDCloudCommandConfig.m
//  Heimdallr
//
//  Created by liuhan on 2022/12/5.
//

#import "HMDCloudCommandConfig.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDCloudCommandConfig

- (instancetype)initWithParams:(NSDictionary *)params {
    if (![params isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    if (self = [super init]) {
        _complianceRelativePaths = [params hmd_arrayForKey:@"compliance_relative_paths"];
    }
    
    return self;
}

@end

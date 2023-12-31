//
//  HMDInjectedInfo+URLHosts.m
//  HeimdallrFinder
//
//  Created by Nickyo on 2023/8/21.
//

#import "HMDInjectedInfo+URLHosts.h"
#import "HMDMacro.h"

@implementation HMDInjectedInfo (URLHosts)

- (NSArray<NSString *> *)configFetchHosts {
    NSArray *customHosts = self.configHostArray;
    if (!HMDIsEmptyArray(customHosts)) {
        return customHosts;
    }
    return nil;
}

- (NSArray<NSString *> *)crashUploadHosts {
    return [self p_uploadHosts:self.crashUploadHost];
}

- (NSArray<NSString *> *)exceptionUploadHosts {
    return [self p_uploadHosts:self.exceptionUploadHost];
}

- (NSArray<NSString *> *)userExceptionUploadHosts {
    return [self p_uploadHosts:self.userExceptionUploadHost];
}

- (NSArray<NSString *> *)performanceUploadHosts {
    return [self p_uploadHosts:self.performanceUploadHost];
}

- (NSArray<NSString *> *)fileUploadHosts {
    return [self p_uploadHosts:self.fileUploadHost];
}

- (NSArray<NSString *> *)p_uploadHosts:(NSString *)customHost {
    if (!HMDIsEmptyString(customHost)) {
        return @[customHost];
    }
    NSString *allHost = self.allUploadHost;
    if (!HMDIsEmptyString(allHost)) {
        return @[allHost];
    }
    return nil;
}

@end

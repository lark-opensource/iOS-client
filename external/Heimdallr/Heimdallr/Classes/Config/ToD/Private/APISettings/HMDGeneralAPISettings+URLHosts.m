//
//  HMDGeneralAPISettings+URLHosts.m
//  HeimdallrFinder
//
//  Created by Nickyo on 2023/8/21.
//

#import "HMDGeneralAPISettings+URLHosts.h"
#import "HMDMacro.h"

@implementation HMDGeneralAPISettings (URLHosts)

- (NSArray<NSString *> *)configFetchHosts {
    NSArray *customHosts = self.fetchAPISetting.hosts;
    if (!HMDIsEmptyArray(customHosts)) {
        return customHosts;
    }
    return nil;
}

- (NSArray<NSString *> *)crashUploadHosts {
    return [self p_uploadHosts:self.crashUploadSetting.hosts];
}

- (NSArray<NSString *> *)exceptionUploadHosts {
    return [self p_uploadHosts:self.exceptionUploadSetting.hosts];
}

- (NSArray<NSString *> *)userExceptionUploadHosts {
    return [self p_uploadHosts:self.exceptionUploadSetting.hosts];
}

- (NSArray<NSString *> *)performanceUploadHosts {
    return [self p_uploadHosts:self.performanceAPISetting.hosts];
}

- (NSArray<NSString *> *)fileUploadHosts {
    return [self p_uploadHosts:self.fileUploadSetting.hosts];
}

- (NSArray<NSString *> *)p_uploadHosts:(NSArray *)customHosts {
    if (!HMDIsEmptyArray(customHosts)) {
        return customHosts;
    }
    NSArray *allHosts = self.allAPISetting.hosts;
    if (!HMDIsEmptyArray(allHosts)) {
        return allHosts;
    }
    return nil;
}

@end

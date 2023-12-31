//
//  HMDFileUploadRequest+URLPathProvider.m
//  AppHost-HeimdallrFinder-Unit-Tests
//
//  Created by Nickyo on 2023/8/18.
//

#import "HMDFileUploadRequest+URLPathProvider.h"

@implementation HMDFileUploadRequest (URLPathProvider)

#pragma mark - HMDURLPathProvider

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return self.path;
}

@end

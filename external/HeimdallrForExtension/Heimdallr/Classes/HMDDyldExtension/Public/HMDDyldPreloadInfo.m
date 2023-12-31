//
//  HMDDyldPreloadInfo.m
//  HeimdallrForExtension
//
//  Created by APM on 2022/10/18.
//

#import "HMDDyldPreloadInfo.h"

@implementation HMDDyldPreloadInfo

- (nonnull instancetype)initWithError:(NSError *)error {
    if (self = [super init]) {
        self.error = error;
    }
    return self;
}

@end

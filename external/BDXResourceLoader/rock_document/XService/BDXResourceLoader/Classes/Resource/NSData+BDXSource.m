//
//  NSData+BDXSource.m
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <objc/runtime.h>
#import "NSData+BDXSource.h"

@implementation NSData (BDXSource)

- (void)setBdx_SourceFrom:(NSInteger)bdx_SourceFrom
{
    objc_setAssociatedObject(self, @selector(bdx_SourceFrom), @(bdx_SourceFrom), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)bdx_SourceFrom
{
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj) {
        return [obj integerValue];
    }
    return NSIntegerMax;
}

- (void)setBdx_SourceUrl:(NSString *)bdx_SourceUrl
{
    objc_setAssociatedObject(self, @selector(bdx_SourceUrl), bdx_SourceUrl, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bdx_SourceUrl
{
    return objc_getAssociatedObject(self, _cmd);
}

- (NSString *)bdx_SourceFromString
{
    NSInteger resourceStatus = [self bdx_SourceFrom];
    NSString *status = @"";
    if (resourceStatus == 0) {
        status = @"gecko";
    } else if (resourceStatus == 1) {
        status = @"cdn";
    } else if (resourceStatus == 2) {
        status = @"cdnCache";
    } else if (resourceStatus == 3) {
        status = @"buildIn";
    } else if (resourceStatus == 4) {
        status = @"offline";
    }
    return status;
}

- (void)setBdx_SourceFromString:(NSString *)bdx_SourceFromString
{
    // do nothing
}

@end

//
//  IESPrefetchCacheModel+RequestModel.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/16.
//

#import "IESPrefetchCacheModel+RequestModel.h"
#import <objc/runtime.h>

@implementation IESPrefetchCacheModel (RequestModel)

- (void)setRequestDescription:(NSString *)requestDescription
{
    objc_setAssociatedObject(self, _cmd, requestDescription, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)requestDescription
{
    NSString *model = objc_getAssociatedObject(self, @selector(setRequestDescription:));
    return model;
}

@end

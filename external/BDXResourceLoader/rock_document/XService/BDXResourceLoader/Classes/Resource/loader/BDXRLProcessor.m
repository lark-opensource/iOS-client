//
//  BDXResourceLoaderProcessor.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/14.
//

#import "BDXRLProcessor.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

#pragma mark-- BDXResourceLoaderBaseProcessor

@implementation BDXRLBaseProcessor

- (NSString *)resourceLoaderName
{
    return @"XDefaultBaseLoader";
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //
    }
    return self;
}

- (void)fetchResourceWithURL:(NSString *)url container:(UIView *__nullable)container loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler
{
    rejectHandler([NSError new]);
}

- (void)cancelLoad
{
}

- (void)dealloc
{
    // do nothing
}

@end

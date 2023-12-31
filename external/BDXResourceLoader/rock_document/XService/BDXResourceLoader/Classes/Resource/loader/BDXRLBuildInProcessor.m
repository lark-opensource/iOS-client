//
//  BDXResourceLoaderLocalProcessor.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import "BDXRLBuildInProcessor.h"

#import "BDXResourceProvider.h"
#import "NSData+BDXSource.h"
#import "NSError+BDXRL.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdDelegateDispatcher.h>
#import <IESGeckoKit/IESGurdKit+InternalPackages.h>

@interface BDXRLBuildInProcessor ()

@end

@implementation BDXRLBuildInProcessor

- (NSString *)resourceLoaderName
{
    return @"XDefaultBuildInLoader";
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
    NSString *sourceURL = url;
    if (!BTD_isEmptyString([self.paramConfig sourceURL])) {
        sourceURL = [self.paramConfig sourceURL];
    }
    if (!BTD_isEmptyString([self.paramConfig channelName]) && !BTD_isEmptyString([self.paramConfig bundleName]) && !BTD_isEmptyString([self.paramConfig accessKey])) {
        NSString *dirName = [IESGurdKit internalRootDirectoryForAccessKey:[self.paramConfig accessKey] channel:[self.paramConfig channelName]];
        NSString *path = @"";
        if ([[self.paramConfig bundleName] hasPrefix:@"/"]) {
            path = [NSString stringWithFormat:@"%@%@", dirName, [self.paramConfig bundleName]];
        } else {
            path = [NSString stringWithFormat:@"%@/%@", dirName, [self.paramConfig bundleName]];
        }

        if ([path containsString:@"../"]) {
            if (rejectHandler && !self.isCanceled) {
                rejectHandler([NSError errorWithCode:BDXRLErrorCodeGurdFaile message:@"XDefaultBuildInLoader path contains ../"]);
            }
            return;
        }

        NSData *falconBuiltInData = nil;
        BOOL isDirectory = NO;
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        if (fileExist && !isDirectory) {
            if ([self.paramConfig onlyPath]) {
                falconBuiltInData = [[NSData alloc] init];
                falconBuiltInData.bdx_SourceFrom = BDXResourceStatusBuildIn;
            } else {
                falconBuiltInData = [NSData dataWithContentsOfFile:path];
                if (falconBuiltInData.length == 0) {
                    falconBuiltInData = nil;
                }
                falconBuiltInData.bdx_SourceFrom = BDXResourceStatusBuildIn;
            }
        }
        if (falconBuiltInData) {
            BDXResourceProvider *resourceProvider = [BDXResourceProvider new];
            resourceProvider.res_originSourceURL = url;
            resourceProvider.res_sourceURL = sourceURL;
            resourceProvider.res_Data = falconBuiltInData;
            resourceProvider.res_sourceFrom = BDXResourceStatusBuildIn;
            resourceProvider.res_localPath = path;
            resourceProvider.res_accessKey = [self.paramConfig accessKey];
            resourceProvider.res_channelName = [self.paramConfig channelName];
            resourceProvider.res_bundleName = [self.paramConfig bundleName];
            if (resolveHandler && !self.isCanceled) {
                resolveHandler(resourceProvider, [self resourceLoaderName]);
            }
        } else {
            if (rejectHandler && !self.isCanceled) {
                rejectHandler([NSError errorWithCode:BDXRLErrorCodeNoData message:@"XDefaultBuildInLoader no BuildIn data"]);
            }
        }
    } else {
        if (rejectHandler && !self.isCanceled) {
            rejectHandler([NSError errorWithCode:BDXRLErrorCodeGurdNoParams message:@"XDefaultBuildInLoader no channelName or bundleName or accessKey"]);
        }
    }
}

- (void)cancelLoad
{
    self.isCanceled = YES;
}

@end

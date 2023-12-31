//
//  BDXLynxKit.m
//  Pods
//
//  Created by tianbaideng on 2021/3/3.
//

#import "BDXLynxKit.h"
#import "BDXLynxResourceProvider.h"
#import <BDALog/BDAgileLog.h>
#import <BDWebImage/BDWebImageManager.h>
#import <BDWebImage/UIImage+BDWebImage.h>
#import <BDWebImage/BDImage.h>
#import <BDXResourceLoader/BDXResourceLoader.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxEnv.h>
#import <Lynx/LynxLog.h>
#import "BDXLynxView.h"

#if __has_include(<Lynx/LynxDebugger.h>)
#import <Lynx/LynxDebugger.h>
#endif

#if __has_include(<Lynx/LynxHelium.h>)
#import <Lynx/LynxHelium.h>
#endif

@BDXSERVICE_REGISTER(BDXLynxKit)

@implementation BDXLynxKit

- (void)initLynxKit
{
    [self initLogObserver];
#if __has_include(<Lynx/LynxDebugger.h>)
    // 打开devtool开关
    // [[LynxEnv sharedInstance] setDevtoolEnabled:YES];

    // 注册devtool OpenCard回调
    [LynxDebugger setOpenCardCallback:^(NSString *url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id <BDXLynxDevtoolProtocol> devtoolDelegate in self.devtoolDelegateSet) {
                if ([devtoolDelegate openDevtoolCard:url]) {
                  break;
                }
            }
        });
    }];
#endif

#if __has_include(<Lynx/LynxHelium.h>)
    [LynxHeliumConfig setOnErrorCallback:^(NSString *_Nullable errorMessage) {
        BDALOG_ERROR_TAG(@"lynx", @"%@", errorMessage);
    }];
    [LynxComponentRegistry registerUI:[LynxHeliumCanvas class] withName:@"canvas"];
#endif
}

- (void)initLogObserver
{
    LynxLogObserver *observer = [[LynxLogObserver alloc]
        initWithLogFunction:^(LynxLogLevel level, NSString *message) {
            switch (level) {
                case LynxLogLevelInfo:
                    BDALOG_INFO_TAG(@"lynx", @"%@", message);
                    break;
                case LynxLogLevelWarning:
                    BDALOG_WARN_TAG(@"lynx", @"%@", message);
                    break;
                case LynxLogLevelError:
                    BDALOG_ERROR_TAG(@"lynx", @"%@", message);
                    break;
                case LynxLogLevelFatal:
                    BDALOG_FATAL_TAG(@"lynx", @"%@", message);
                    break;
                case LynxLogLevelReport: {
                    BDALOG_WARN_TAG(@"lynx", @"%@", message);

                    id<BDXMonitorProtocol> monitor = BDXSERVICE(BDXMonitorProtocol, nil);
                    [monitor reportWithEventName:@"LynxLog" bizTag:nil commonParams:@{@"url": @""} metric:nil category:@{@"message": message ?: @""} extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:YES];
                    break;
                }
                default:
                    break;
            }
        }
                minLogLevel:LynxLogLevelInfo];
    observer.acceptSource = LynxLogSourceNaitve;
    LynxAddLogObserverByModel(observer);
}

- (UIView<BDXLynxViewProtocol> *)createViewWithFrame:(CGRect)frame
{
    BDXLynxView *view = [[BDXLynxView alloc] initWithFrame:frame params:nil];
    return view;
}

- (UIView<BDXLynxViewProtocol> *)createViewWithFrame:(CGRect)frame params:(BDXLynxKitParams *)params
{
    BDXLynxView *view = [[BDXLynxView alloc] initWithFrame:frame params:params];
    return view;
}

#if __has_include(<Lynx/LynxDebugger.h>)
@synthesize devtoolDelegateSet;
- (BOOL)enableLynxDevtool:(NSURL *)url withOptions:(NSDictionary *)options
{
    return [LynxDebugger enable:url withOptions:options];
}

- (void)addDevtoolDelegate:(nonnull id<BDXLynxDevtoolProtocol>)devtoolDelegate
{ 
    if (!self.devtoolDelegateSet) {
     self.devtoolDelegateSet = [NSMutableSet new];
    }
    [self.devtoolDelegateSet addObject:devtoolDelegate];
}

#endif

- (void)prefetchResourceWithURLs:(NSArray<NSString *> *)sourceURLs
{
    id<BDXResourceLoaderProtocol> resourceLoader = BDXSERVICE_WITH_DEFAULT(BDXResourceLoaderProtocol, nil);
    if (!resourceLoader || !sourceURLs || BTD_isEmptyArray(sourceURLs)) {
        return;
    }
    for (NSString *sourceURL in sourceURLs) {
        NSString *cacheKey = [sourceURL btd_md5String];
        [BDXImageURLCacheKeyStorage setPrefetchCacheKey:cacheKey];
        __block BDImageCacheType cacheType = BDImageCacheTypeMemory;
        [resourceLoader fetchResourceWithURL:sourceURL container:nil taskConfig:nil completion:^(id<BDXResourceProtocol> _Nullable resourceProvider, NSError *_Nullable error) {
            [BDXResourceLoader reportLog:[NSString stringWithFormat:@"Resource - prerenderImage url "
                                                                    @"fetched = %@ , error : %@",
                                                                    sourceURL, error.description]];
            if (resourceProvider.resourceData && sourceURL.length > 0) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    if (![[BDImageCache sharedImageCache] containsImageForKey:cacheKey type:cacheType]) {
                        BDImage *cdnImage = [BDImage imageWithData:resourceProvider.resourceData];
                        // 如果是图片 缓存到内存
                        if (cdnImage) {
                            [[BDImageCache sharedImageCache] setImage:cdnImage imageData:resourceProvider.resourceData forKey:cacheKey withType:cacheType];
                        }
                    }
                });
            }
        }];
    }
}

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeLynxKit;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

@end

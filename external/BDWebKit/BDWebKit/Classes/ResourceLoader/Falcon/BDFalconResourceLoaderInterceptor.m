//
//  BDFalconResourceLoaderInterceptor.m
//  Indexer
//
//  Created by pc on 2022/3/22.
//

#import "BDFalconResourceLoaderInterceptor.h"

#import "IESFalconManager.h"
#import "BDResourceLoaderPluginObject.h"

#import "BDResourceLoaderMetricHelper.h"
#import <BDXResourceLoader/BDXResourceLoader.h>
#import <BDALogProtocol/BDALogProtocol.h>

static NSString * const kLogTag = @"ResourceLoaderInterceptor";


@interface BDFalconResourceLoaderMetaData : NSObject<IESFalconMetaData>
@end
@implementation BDFalconResourceLoaderMetaData
@synthesize falconData = _falconData;
@synthesize statModel = _statModel;
@end

@interface BDFalconResourceLoaderInterceptor ()

@property (nonatomic, weak) WKWebView *webview;
@property (nonatomic, strong) NSCache<NSString *, id<BDXResourceProtocol>> *cache;

@end

@implementation BDFalconResourceLoaderInterceptor

+ (void)setupWithWebView:(WKWebView *)webview
{
    if (![webview isKindOfClass:[WKWebView class]]) {
        return;
    }
    BDFalconResourceLoaderInterceptor *interceptor = [[BDFalconResourceLoaderInterceptor alloc] init];
    [webview bdw_registerFalconCustomInterceptor:interceptor];
    interceptor.webview = webview;
    
    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"register ResourceLoaderInterceptor with %@", webview);
    
    return;
}

- (instancetype)init
{
    if ([super init]) {
        _cache = [[NSCache alloc] init];
        _cache.totalCostLimit = 6 * 1024 * 1024;
        _cache.countLimit = 2;
    }
    
    return self;
}


#pragma mark - IESFalconCustomInterceptor

- (id<IESFalconMetaData>)falconMetaDataForURLRequest:(NSURLRequest *)request {
    NSData *falconData = [self falconDataForURLRequest:request];
    if (!falconData) {
        return nil;
    }
    id<IESFalconMetaData> metaData = [[BDFalconResourceLoaderMetaData alloc] init];
    metaData.falconData = falconData;
    return metaData;
}

- (NSData *)falconDataForURLRequest:(NSURLRequest *)request
{
    if ([request.URL.absoluteString hasPrefix:@"about://waitfix"]) { //过滤掉离线化的请求
        return nil;
    }
    BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
    taskConfig.callerPlatform = @(BDXRLMonitorPlatformWebView);
    
    if (self.webview.bdwrl_taskBuilder) {
        self.webview.bdwrl_taskBuilder(taskConfig);
    }
    
    NSError *error;
    id<BDXResourceProtocol> resource = [self.cache objectForKey:request.URL.absoluteString];
    if (!resource) {
        resource = [[BDXResourceLoader sharedInstance] fetchLocalResourceWithURL:request.URL.absoluteString
                                                                      taskConfig:taskConfig
                                                                           error:&error];
    }
    NSData *resourceData = resource.resourceData;
    if (error || resourceData.length == 0) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"not offline resource for %@, error:%@", request.URL, error);
        if (error) {
            [request.bdw_falconProcessInfoRecord setValue:@(error.code) forKey:@"res_loader_error_code"];
            [request.bdw_falconProcessInfoRecord setValue:error.localizedDescription ?: @"" forKey:@"res_error_msg"];
        }
        return nil;
    } else if (!error && resource){
        NSString *containerId = [BDResourceLoaderMetricHelper webContainerId:self.webview];
        NSDictionary *metricInfo = [BDResourceLoaderMetricHelper monitorDict:resource containerId:containerId];
        [request.bdw_falconProcessInfoRecord addEntriesFromDictionary:metricInfo];
    }
    
    if (resource) {
        [self.cache removeObjectForKey:request.URL.absoluteString];
    } else {
        [self.cache setObject:resource
                       forKey:request.URL.absoluteString
                         cost:resource.resourceData.length];
    }
    
    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"get offline resource for %@, from:%@", request.URL, @(resource.resourceType));
    return resource.resourceData;
}

- (NSUInteger)falconPriority
{
    return 10;
}

- (BOOL)shouldInterceptForRequest:(NSURLRequest*)request
{
    BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
    taskConfig.callerPlatform = @(BDXRLMonitorPlatformWebView);
    
    if (self.webview.bdwrl_taskBuilder) {
        self.webview.bdwrl_taskBuilder(taskConfig);
    }
    
    NSError *error;
    id<BDXResourceProtocol> resource
    = [[BDXResourceLoader sharedInstance] fetchLocalResourceWithURL:request.URL.absoluteString
                                                         taskConfig:taskConfig
                                                              error:&error];
    if (error || resource.resourceData.length == 0) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"not offline resource for %@, error:%@", request.URL, error);
        return NO;
    }
    
    [self.cache setObject:resource
                   forKey:request.URL.absoluteString
                     cost:resource.resourceData.length];
    
    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"find offline resource for %@, path:%@", request.URL, resource.absolutePath);
    
    return YES;
}


@end
 

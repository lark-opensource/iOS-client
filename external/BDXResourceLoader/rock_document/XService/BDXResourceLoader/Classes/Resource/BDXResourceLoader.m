//
//  BDXResourceLoader.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/14.
//

#import "BDXResourceLoader.h"

#import "BDXGurdSyncTask.h"
#import "BDXRLBuildInProcessor.h"
#import "BDXRLCDNProcessor.h"
#import "BDXRLGurdProcessor.h"
#import "BDXRLOperator.h"
#import "BDXRLPipeline.h"
#import "BDXRLProcessor.h"
#import "NSData+BDXSource.h"
#import "NSError+BDXRL.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceDefines.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#include <pthread/pthread.h>

static inline void dispatch_BDX_safe_main(BOOL onlySync, dispatch_block_t block)
{
    if (onlySync) {
        // 不强制在主线程，在本线程执行block
        block();
        return;
    }
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

NSString *const kBDXRLDomain = @"BDXDownloaderErrorDomain";

#pragma mark-- BDXResourceLoaderTask

@interface BDXRLTask ()

@property(nonatomic, strong) BDXRLPipeline *loaderPipeline;

@end

@implementation BDXRLTask

@synthesize url;

- (BOOL)cancelTask
{
    return [self.loaderPipeline cancelLoad];
}

- (void)dealloc
{
    // do nothing
}

@end

#pragma mark-- BDXResourceLoader

@BDXSERVICE_REGISTER(BDXResourceLoader);

@interface BDXResourceLoader ()
{
    pthread_mutex_t _taskPoolLock;
}
@property(nonatomic, strong) NSMutableArray<id<BDXResourceLoaderTaskProtocol>> *taskPool;
@property(nonatomic, strong) BDXRLOperator *advancedOperator;
@property(nonatomic, copy) NSArray<NSNumber *> *processorsDefaultSequence;
@property(nonatomic, copy) NSString *appId;

@end

@implementation BDXResourceLoader

#pragma mark-- BDXService

BDXSERVICE_SINGLETON_IMP

- (instancetype)init
{
    if (self = [super init]) {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutex_init(&_taskPoolLock, &attr);
        pthread_mutexattr_destroy(&attr);
        self.taskPool = [NSMutableArray new];
        self.processorsDefaultSequence = @[@(BDXProcessTypeGecko), @(BDXProcessTypeBuildin), @(BDXProcessTypeCdn)];
        BDXRLOperator *temp = [BDXRLOperator new];
        temp.resourceLoader = self; // weak 引用self
        self.advancedOperator = temp;
    }
    return self;
}

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeResourceLoader;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

#pragma mark-- BDXResourceLoaderConfigProtocol

- (void)updateLoaderConfig:(BDXResourceLoaderConfig *)loaderConfig
{
    self.loaderConfig = loaderConfig;
}

- (id<BDXResourceLoaderTaskProtocol>)fetchResourceWithURL:(NSString *)url container:(UIView *__nullable)container taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig completion:(BDXResourceLoaderCompletionHandler __nullable)completionHandler
{
    // 使用ParamConfig来兼容处理taskConfig 和 url中参数。
    // 可以认为ParamConfig是taskConfig的超集
    BDXRLUrlParamConfig *paramConfig = [[BDXRLUrlParamConfig alloc] initWithUrl:url loaderConfig:self.loaderConfig taskConfig:taskConfig advOperator:self.advancedOperator];

    // 创建此次获取任务的Pipeline
    BDXRLPipeline *loaderPipeline = [self createNewPipelineWith:url container:(UIView *)container taskConfig:taskConfig paramConfig:paramConfig];
    loaderPipeline.paramConfig = paramConfig;

    // 创建一个Task实例代表此次任务
    BDXRLTask *task = [[BDXRLTask alloc] init];

    pthread_mutex_lock(&_taskPoolLock);
    // 不是所有的调用者都关心返回Task，也就是说，返回Task可能不会被任何对象持有。
    // 这里将创建的Task统一加入到taskPool中，fetch成功后再移除。
    [self.taskPool btd_addObject:task];
    pthread_mutex_unlock(&_taskPoolLock);

    task.url = url;
    task.loaderPipeline = loaderPipeline;

    // 包装回调Block，做结束处理或埋点统计等逻辑
    @weakify(self);
    __weak typeof(task) weak_task = task;                //（注意task与complete的引用关系）
    __weak typeof(container) weak_container = container; // 这里也做weak处理，防止后面container再被持有
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    BDXResourceLoaderResolveHandler wrapResolveHandler = ^(id<BDXResourceProtocol> resourceProvider, NSString *resourceLoaderName) {
        @strongify(self);
        __strong typeof(weak_task) strong_task = weak_task;
        [self completeWithTask:strong_task paramConfig:paramConfig provider:resourceProvider loaderName:resourceLoaderName error:nil container:weak_container];
        // 上报数据
        CFTimeInterval loadDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
        [self reportEvent:@"bdx_resourceloader_fetch" paramConfig:paramConfig status:[resourceProvider resourceType] version:[resourceProvider version] categoryExt:@{
            @"res_state": @"success",
            @"res_message": resourceLoaderName ?: @""
        } metric:@{
            @"res_duration": @(loadDuration),
        }];
        dispatch_BDX_safe_main([paramConfig syncTask], ^{
            if (completionHandler) {
                completionHandler(resourceProvider, nil);
            }
        });
    };
    BDXResourceLoaderRejectHandler wrapRejectHandler = ^(NSError *error) {
        @strongify(self);
        __strong typeof(weak_task) strong_task = weak_task;
        [self completeWithTask:strong_task paramConfig:paramConfig provider:nil loaderName:nil error:error container:weak_container];
        // 上报数据
        CFTimeInterval loadDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
        [self reportEvent:@"bdx_resourceloader_fetch" paramConfig:paramConfig status:BDXResourceStatusGecko version:0 categoryExt:@{
            @"res_state": @"fail",
            @"res_message": error.localizedDescription ?: @""
        } metric:@{
            @"res_duration": @(loadDuration),
        }];
        dispatch_BDX_safe_main([paramConfig syncTask], ^{
            if (completionHandler) {
                completionHandler(nil, error);
            }
        });
    };

    // 开始加载资源
    [task.loaderPipeline fetchResourceWithContainer:container resolve:wrapResolveHandler reject:wrapRejectHandler];
    return task;
}

- (BOOL)cancelResourceLoad:(id<BDXResourceLoaderTaskProtocol>)task
{
    return [task cancelTask];
}

- (BOOL)deleteResource:(id<BDXResourceProtocol>)resource
{
    if ([resource resourceType] == BDXResourceStatusCdn) {
        [BDXRLCDNProcessor deleteCDNCacheForResource:resource];
    } else if ([resource resourceType] == BDXResourceStatusGecko) {
        [BDXRLGurdProcessor deleteGurdCacheForResource:resource];
    }
    return NO;
}

- (id<BDXResourceLoaderAdvancedOperatorProtocol>)getAdvancedOperator
{
    return self.advancedOperator;
}

#pragma mark-- 埋点统计

- (void)onResourceLoadCompleted:(NSString *)URL inContainer:(UIView *__nullable)container context:(NSDictionary *__nullable)context
{
    // no implement, just for xdebugger hook
}

#pragma mark private

- (void)completeWithTask:(BDXRLTask *)task paramConfig:(BDXRLUrlParamConfig *)paramConfig provider:(id<BDXResourceProtocol> __nullable)resourceProvider loaderName:(NSString *__nullable)loaderName error:(NSError *__nullable)error container:(UIView *__nullable)container
{
    /// 清除本次task
    pthread_mutex_lock(&self->_taskPoolLock);
    [self.taskPool removeObject:task];
    pthread_mutex_unlock(&self->_taskPoolLock);
    /// 上报统计
    if (resourceProvider.resourceData) {
        resourceProvider.resourceData.bdx_SourceUrl = task.url;
        [self onResourceLoadCompleted:task.url inContainer:container context:@{
            @"from": @(resourceProvider.resourceData.bdx_SourceFrom),
            @"version": @(resourceProvider.version),
            @"absolutePath": resourceProvider.absolutePath?:@""
        }];
        /// fetch SourceURL 需要上报 (子资源)
        if (container && ![paramConfig isSchema]) {
            [[BDXResourceLoader monitor] reportResourceStatus:container resourceStatus:resourceProvider.resourceData.bdx_SourceFrom resourceType:BDXMonitorResourceTypeRes resourceURL:task.url resourceVersion:[NSString stringWithFormat:@"%llu", resourceProvider.version] extraInfo:nil extraMetrics:nil];
        }
    }
}

- (BDXResourceLoaderConfig *)loaderConfig
{
    if (_loaderConfig == nil) {
        _loaderConfig = [BDXResourceLoaderConfig new];
    }
    return _loaderConfig;
}

/// @abstract 依次将high default以及low里的Processor创建出来，构造新的Pipeline
- (BDXRLPipeline *)createNewPipelineWith:(NSString *)url container:(UIView *)container taskConfig:(BDXResourceLoaderTaskConfig *)taskConfig paramConfig:(BDXRLUrlParamConfig *)paramConfig
{
    NSMutableArray<id<BDXResourceLoaderProcessorProtocol>> *processorArray = [NSMutableArray new];
    [taskConfig.processorConfig.highProcessorProviderArray enumerateObjectsUsingBlock:^(BDXResourceLoaderProcessorProvider processorProvider, NSUInteger idx, BOOL *stop) {
        id<BDXResourceLoaderProcessorProtocol> loaderProcessor = processorProvider();
        if ([loaderProcessor conformsToProtocol:@protocol(BDXResourceLoaderProcessorProtocol)]) {
            [processorArray btd_addObject:loaderProcessor];
        }
    }];

    /// 根据disableDefaultProcessors确定是否需要使用DefaultLoader
    if (!taskConfig.processorConfig.disableDefaultProcessors) {
        [self addDefaultProcessorsWith:processorArray url:url container:container paramConfig:paramConfig];
    }

    [taskConfig.processorConfig.lowProcessorProviderArray enumerateObjectsUsingBlock:^(BDXResourceLoaderProcessorProvider processorProvider, NSUInteger idx, BOOL *stop) {
        id<BDXResourceLoaderProcessorProtocol> loaderProcessor = processorProvider();
        if ([loaderProcessor conformsToProtocol:@protocol(BDXResourceLoaderProcessorProtocol)]) {
            [processorArray btd_addObject:loaderProcessor];
        }
    }];

    return [[BDXRLPipeline alloc] initWithProcessors:[processorArray copy] url:url loaderConfig:self.loaderConfig taskConfig:taskConfig];
}

- (void)addDefaultProcessorsWith:(NSMutableArray *)processorArray url:(NSString *)url container:(UIView *)container paramConfig:(BDXRLUrlParamConfig *)paramConfig
{
    NSArray<NSNumber *> *processorsSequence = self.processorsDefaultSequence;
    if (paramConfig.taskConfig.processorConfig.defaultProcessorsSequence.count > 0) {
        processorsSequence = [paramConfig.taskConfig.processorConfig.defaultProcessorsSequence copy];
    }
    for (NSNumber *type in processorsSequence) {
        BDXRLBaseProcessor *baseProcessor = nil;
        if (type.integerValue == BDXProcessTypeGecko) {
            if ([paramConfig disableGecko] == NO) {
                baseProcessor = [BDXRLGurdProcessor new];
            }
        } else if (type.integerValue == BDXProcessTypeBuildin) {
            if ([paramConfig disableBuildin] == NO) {
                baseProcessor = [BDXRLBuildInProcessor new];
            }
        } else if (type.integerValue == BDXProcessTypeCdn) {
            if ([paramConfig disableCDN] == NO) {
                baseProcessor = [BDXRLCDNProcessor new];
            }
        } else {
            [BDXResourceLoader reportLog:@"processors type not supportted"];
        }

        if (baseProcessor) {
            baseProcessor.paramConfig = paramConfig;
            baseProcessor.advancedOperator = self.advancedOperator;
            [processorArray btd_addObject:baseProcessor];
        }
    }
}

- (void)reportEvent:(NSString *)eventName paramConfig:(BDXRLUrlParamConfig *)paramConfig status:(BDXResourceStatus)status version:(uint64_t)version categoryExt:(NSDictionary *)category metric:(NSDictionary *)metric
{
    NSString *statusString = @"gecko";
    switch (status) {
        case BDXResourceStatusCdn:
            statusString = @"cdn";
            break;
        case BDXResourceStatusCdnCache:
            statusString = @"cdnCache";
            break;
        case BDXResourceStatusBuildIn:
            statusString = @"buildIn";
            break;
        case BDXResourceStatusOffline:
            statusString = @"offline";
            break;
        default:
            break;
    }
    NSString *url = [paramConfig sourceURL] ?: [paramConfig url];
    if ([paramConfig disableCDN]) {
        eventName = [NSString stringWithFormat:@"%@_disableCDN", eventName];
    }
    NSMutableDictionary *allCategory = [@{
        @"res_url": [paramConfig url] ?: @"",
        @"res_from": statusString,
        @"res_version": [NSString stringWithFormat:@"%llu", version], // 0
    } mutableCopy];
    [allCategory addEntriesFromDictionary:category ?: @{}];
    [[BDXResourceLoader monitor] reportWithEventName:eventName bizTag:nil commonParams:@{@"url": url ?: @""} metric:metric category:[allCategory copy] extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:YES];
}

- (NSString *)appId
{
    if (_appId == nil) {
        _appId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SSAppID"];
    }
    return _appId;
}

+ (void)reportLog:(NSString *)message
{
    if (message.length > 0) {
        [[self monitor] logWithTag:@"BDXResourceLoader" level:BDXMonitorLogLevelInfo format:@"%@", message];
    }
}

+ (void)reportError:(NSString *)message
{
    if (message.length > 0) {
        [[self monitor] logWithTag:@"BDXResourceLoader" level:BDXMonitorLogLevelError format:@"%@", message];
    }
}

+ (id<BDXMonitorProtocol>)monitor
{
    return BDXSERVICE(BDXMonitorProtocol, DEFAULT_SERVICE_BIZ_ID);
}

+ (NSString *)appid;
{
    return [BDXResourceLoader sharedInstance].appId;
}

@end

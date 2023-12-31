//
//  BDXResourceLoaderPipeline.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/14.
//

#import "BDXRLPipeline.h"
#import <ByteDanceKit/BTDMacros.h>
#import "NSError+BDXRL.h"

@interface BDXRLPipeline ()

@property(nonatomic, copy) NSString *url;
@property(nonatomic, strong) BDXResourceLoaderConfig *loaderConfig;
@property(nonatomic, strong) BDXResourceLoaderTaskConfig *taskConfig;
@property(nonatomic, strong) id<BDXResourceLoaderProcessorProtocol> currentProcessor;
@property(nonatomic, copy) NSArray<id<BDXResourceLoaderProcessorProtocol>> *processorArray;
@property(nonatomic, strong) NSEnumerator<id<BDXResourceLoaderProcessorProtocol>> *enumerator;
@property(nonatomic, copy) BDXResourceLoaderRejectHandler rejectHandler;

@property(nonatomic, assign) BOOL isCanceled;
@property(nonatomic, assign) BOOL isCompleted;

@end

@implementation BDXRLPipeline

- (instancetype)initWithProcessors:(NSArray<id<BDXResourceLoaderProcessorProtocol>> *)processorArray url:(NSString *)url loaderConfig:(BDXResourceLoaderConfig *)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *)taskConfig;
{
    self = [super init];
    if (self) {
        self.processorArray = processorArray;
        self.enumerator = [processorArray objectEnumerator];
        self.url = url;
        self.loaderConfig = loaderConfig;
        self.taskConfig = taskConfig;
    }
    return self;
}

- (BOOL)cancelLoad
{
    if (!self.isCompleted) {
        self.isCanceled = YES;
        self.isCompleted = YES;
        [self.currentProcessor cancelLoad];
        if (self.rejectHandler) {
            self.rejectHandler([NSError errorWithCode:BDXRLErrorCodeCancel message:@"was cancelled"]);
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)dealloc
{
}

- (void)fetchResourceWithContainer:(UIView *__nullable)container resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler
{
    /// syncTask 或  非runTaskInGlobalQueue 配置下，直接fetch
    if ([self.paramConfig syncTask] || ! [self.paramConfig runTaskInGlobalQueue]) {
        [self _fetchResourceWithContainer:container resolve:resolveHandler reject:rejectHandler];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _fetchResourceWithContainer:container resolve:resolveHandler reject:rejectHandler];
        });
    }
}

- (void)_fetchResourceWithContainer:(UIView *__nullable)container resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler
{
    // 将rejectHandler保存下来，在cancelLoad时需要使用
    if (!self.rejectHandler) {
        self.rejectHandler = rejectHandler;
    }

    // 如果当前没有任何处理器这直接失败
    if (self.processorArray.count == 0) {
        self.isCompleted = YES;
        if (rejectHandler) {
            rejectHandler([NSError errorWithCode:BDXRLErrorCodeNoProcessor message:@"no fetch processor added"]);
        }
        return;
    }

    // 包装回调Block，做一些状态改变和RejectContinue的处理
    @weakify(self);
    BDXResourceLoaderResolveHandler wrapResolveHandler = ^(id<BDXResourceProtocol> resourceProvider, NSString *resourceLoaderName) {
        @strongify(self);
        if (self.isCanceled) {
            /// 当前加载任务被取消，无需处理
            /// rejectHandler在cancel方法执行时被调用，此处不再调用rejectHandler
            return;
        }
        self.isCompleted = YES;
        if (resolveHandler) {
            resolveHandler(resourceProvider, resourceLoaderName);
        }
    };
    /// 这里也做weak处理，防止后面container再被持有
    __weak typeof(container) weak_container = container;
    BDXResourceLoaderRejectHandler wrapRejectHandler = ^(NSError *error) {
        @strongify(self);
        if (self.isCanceled) {
            /// 当前加载任务被取消，无需处理
            /// rejectHandler在cancel方法执行时被调用，此处不再调用rejectHandler
            return;
        }
        if (self.currentProcessor == self.processorArray.lastObject) {
            /// 如果是最后一个处理器，则调用失败Handler
            self.isCompleted = YES;
            if (rejectHandler) {
                rejectHandler(error);
            }
        } else {
            /// 如果不是最后一个处理器，则递归调用此方法，交由下个处理器执行
            [self _fetchResourceWithContainer:weak_container resolve:resolveHandler reject:rejectHandler];
        }
    };

    // 调用下一个处理器进行资源获取
    self.currentProcessor = [self.enumerator nextObject];
    if (self.currentProcessor) {
        [self.currentProcessor fetchResourceWithURL:self.url container:container loaderConfig:self.loaderConfig taskConfig:self.taskConfig resolve:wrapResolveHandler reject:wrapRejectHandler];
    }
}

@end

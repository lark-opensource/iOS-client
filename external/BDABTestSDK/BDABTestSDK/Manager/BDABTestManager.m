//
//  BDABTestManager.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestManager.h"
#import "BDABTestExposureManager.h"
#import "BDABTestManager+Cache.h"
#import "BDABTestExperimentUpdater.h"
#import "BDABTestValuePanelViewController.h"
#import "BDClientABManager.h"
#include <pthread.h>

static pthread_rwlock_t experimentsLock = PTHREAD_RWLOCK_INITIALIZER;


@interface BDABTestManager()<BDABTestValuePanelDelegate>

@property (nonatomic, weak) id<BDABTestLogDelegate> logDelegate;
@property (nonatomic, strong) BDABTestExperimentUpdater *updater; //负责网络数据请求
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDABTestBaseExperiment *> *experiments; //注册的所有实验，以{key:experiment}的方式维护

@end

@implementation BDABTestManager

+ (instancetype)sharedManager
{
    static BDABTestManager *sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [self new];
    });
    return sharedInst;
}

- (instancetype)init
{
    if ((self = [super init])) {
        self.enableLockOpt = YES;
        self.updater = [[BDABTestExperimentUpdater alloc] init];
        self.experiments = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)doLog:(NSString *)log
{
    if (self.logDelegate && [self.logDelegate respondsToSelector:@selector(onLog:)]) {
        [self.logDelegate onLog:log];
    }
}

+ (void)registerLogDelegate:(id<BDABTestLogDelegate>)logDelegate
{
    if (logDelegate && [logDelegate respondsToSelector:@selector(onLog:)]) {
        [BDABTestManager sharedManager].logDelegate = logDelegate;
    }
}

+ (void)unregisterLogDelegate
{
    [BDABTestManager sharedManager].logDelegate = nil;
}

+ (void)fetchExperimentDataWithURL:(NSString *)url maxRetryCount:(NSInteger)maxRetryCount completionBlock:(void (^)(NSError *error, NSDictionary *data))completionBlock
{
    [self fetchExperimentDataWithURL:url currentRetryCount:0 maxRetryCount:maxRetryCount completionBlock:completionBlock];
}

/**
 通过接口取得改设备命中的实验数据
 支持多线程调用
 */
+ (void)fetchExperimentDataWithURL:(NSString *)url currentRetryCount:(NSInteger)currentRetryCount maxRetryCount:(NSInteger)maxRetryCount completionBlock:(void (^)(NSError *error, NSDictionary *data))completionBlock;
{
    [[BDABTestManager sharedManager].updater fetchABTestExperimentsWithURL:url completionBlock:^(NSDictionary<NSString *,NSDictionary *> *jsonData, NSDictionary<NSString *,BDABTestExperimentItemModel *> *itemModels, NSError *error) {
        if (error) {
            if (![error.domain isEqualToString:kFetchABResultErrorDomain]) {
                //如果是网络错误，则重试
                if (currentRetryCount < maxRetryCount) {
                    [BDABTestManager fetchExperimentDataWithURL:url currentRetryCount:(currentRetryCount+1) maxRetryCount:maxRetryCount completionBlock:completionBlock];
                } else {
                    completionBlock ? completionBlock(error, nil) : nil;
                }
            } else {
                completionBlock ? completionBlock(error, nil) : nil;
            }
        } else {
            [[BDABTestManager sharedManager] saveFetchedJsonData:jsonData];
            if (completionBlock) {
                completionBlock(nil, jsonData);
            }
        }
    }];
}

/**
 注册实验。只有已经注册的实验才能取值。
 支持多线程调用
 */
+ (void)registerExperiment:(BDABTestBaseExperiment *)experiment
{
    NSString *key = experiment.key;
    if (!key || key.length == 0) {
        NSAssert(NO, @"Key can not be empty");
        return;
    }
    
    BDABTestManager *manager = [BDABTestManager sharedManager];
    if (manager.enableLockOpt) {
        pthread_rwlock_rdlock(&experimentsLock);
        BDABTestBaseExperiment *oldExperiment = [manager.experiments objectForKey:experiment.key];
        pthread_rwlock_unlock(&experimentsLock);
        
        if (oldExperiment) {
            NSAssert(NO, @"Experiment %@ already registered by %@, check it up or use another experimentKey.", experiment.key, oldExperiment.owner);
            return;
        }
        
        pthread_rwlock_wrlock(&experimentsLock);
        [manager.experiments setValue:experiment forKey:experiment.key];
        pthread_rwlock_unlock(&experimentsLock);
    } else {
        BDABTestBaseExperiment *oldExperiment;
        @synchronized ([BDABTestManager sharedManager].experiments) {
            oldExperiment = [[BDABTestManager sharedManager].experiments objectForKey:experiment.key];
        }
        if (oldExperiment) {
            NSAssert(NO, @"Experiment %@ has been registed by %@, please change the key", experiment.key, oldExperiment.owner);
            return;
        }
    
        @synchronized ([BDABTestManager sharedManager].experiments) {
            [[BDABTestManager sharedManager].experiments setValue:experiment forKey:experiment.key];
        }
    }
}

/**
 取得key对应的实验的值。只有已经注册的实验才能取值。
 支持多线程调用
 
 @param key 实验的key
 @param withExposure 取值的同时是否触发曝光
 @return 实验的值
 */
+ (id)getExperimentValueForKey:(NSString *)key withExposure:(BOOL)withExposure
{
    BDABTestManager *manager = [BDABTestManager sharedManager];
    if (manager.enableLockOpt) {
        pthread_rwlock_rdlock(&experimentsLock);
        BDABTestBaseExperiment *experiment = [manager.experiments objectForKey:key];
        pthread_rwlock_unlock(&experimentsLock);
        if (!experiment) {
            [manager doLog:[NSString stringWithFormat:@"Experiment %@ does not exist，please confirm registion", key]];
            return nil;
        }
        return [experiment getValueWithExposure:withExposure];
    } else {
        BDABTestBaseExperiment *experiment = nil;
        @synchronized ([BDABTestManager sharedManager].experiments) {
            experiment = [[BDABTestManager sharedManager].experiments objectForKey:key];
        }
        if (!experiment) {
            [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"Experiment %@ does not exist，please confirm registion", key]];
            return nil;
        }
        return [experiment getValueWithExposure:withExposure];
    }
}

/**
 实验配置界面（测试用）,需要业务方自行present
 
 @return 实验配置界面
 */
+ (UIViewController *)panelViewController
{
    BDABTestManager *manager = [BDABTestManager sharedManager];
    if (manager.enableLockOpt) {
        pthread_rwlock_rdlock(&experimentsLock);
        NSArray<BDABTestBaseExperiment *> *allExperiments = [manager.experiments allValues];
        pthread_rwlock_unlock(&experimentsLock);
        
        BDABTestValuePanelViewController *valuePanel = [[BDABTestValuePanelViewController alloc] initWithSourceData:allExperiments];
        valuePanel.delegate = manager;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:valuePanel];
        navController.view.backgroundColor = [UIColor whiteColor];
        return navController;
    } else {
        NSArray<BDABTestBaseExperiment *> *allExperiments = nil;
        @synchronized ([BDABTestManager sharedManager].experiments) {
            allExperiments = [[BDABTestManager sharedManager].experiments allValues];
        }
        
        BDABTestValuePanelViewController *valuePanel = [[BDABTestValuePanelViewController alloc] initWithSourceData:allExperiments];
        valuePanel.delegate = [BDABTestManager sharedManager];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:valuePanel];
        navController.view.backgroundColor = [UIColor whiteColor];
        return navController;
    }
}

/**
 已曝光实验的vid
 支持多线程调用
 
 @return 已曝光实验的vid
 */
+ (NSString *)queryExposureExperiments
{
    NSString *res = [[BDABTestExposureManager sharedManager] exposureVidString];
    return res;
}

+ (void)saveServerSettingsForServerExperiments:(NSDictionary<NSString *, NSDictionary *> *)dic
{
    [[BDABTestManager sharedManager] saveFetchedJsonData:dic];
}

#pragma mark Client AB Experiment

+ (BOOL)registerClientLayer:(BDClientABTestLayer *)clientLayer
{
    return [[BDClientABManager sharedManager] registerClientLayer:clientLayer];
}

+ (BDClientABTestLayer *)clientLayerByName:(NSString *)name
{
    return [[BDClientABManager sharedManager] clientLayerByName:name];
}

+ (void)launchClientExperimentManager
{
    [[BDClientABManager sharedManager] launchClientExperimentManager];
}

+ (void)saveServerSettingsForClientExperiments:(NSDictionary *)dict
{
    [[BDClientABManager sharedManager] saveServerSettingsForClientExperiments:dict];
}

+ (NSString *)ABGroup
{
    return [[BDClientABManager sharedManager] ABGroup];
}

+ (NSString *)ABVersion
{
    return [[BDClientABManager sharedManager] ABVersion];
}

+ (void)saveABVersion:(NSString *)abVersion
{
    [[BDClientABManager sharedManager] saveABVersion:abVersion];
}

+ (NSString *)ABTestClient
{
    NSMutableString * abClient = [NSMutableString stringWithCapacity:10];
    
    [abClient appendFormat:@"a1"];
    
#ifndef TTModule
    [abClient appendFormat:@",f2"];
    [abClient appendFormat:@",f7"];
#endif
    [abClient appendFormat:@",e1"];
    
    return abClient;
}

+ (void)enableEvent:(BOOL)enabled
{
//    [BDABTestExposureManager sharedManager].eventEnabled = enabled;
}

@end

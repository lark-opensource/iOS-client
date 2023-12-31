//
//  BDABTestBaseExperiment.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestBaseExperiment.h"
#import "BDABTestManager+Private.h"
#import "BDABTestManager+Cache.h"
#import "BDABTestExposureManager.h"
#import "BDABTestExperimentItemModel.h"
#import "BDClientABManager.h"

@interface BDABTestBaseExperiment()

/**
 实验的key,必须与libra平台的“配置参数”名字保持一致
 */
@property (nonatomic, copy) NSString *key;

/**
 实验的负责人
 */
@property (nonatomic, copy) NSString *owner;

/**
 实验的说明
 */
@property (nonatomic, copy) NSString *desc;

/**
 该实验的默认值
 */
@property (nonatomic, strong) id defaultValue;

/**
 实验取值的类型
 */
@property (nonatomic, assign) BDABTestValueType valueType;

/**
 该实验的取值，是否需要在一次启动期间保持一致
 */
@property (nonatomic, assign) BOOL isSticky;

/**
 这个实验在一次app生命周期内的首次取值
 */
@property (atomic, strong) BDABTestExperimentItemModel *stickyResult;

/**
 这个实验最新被下发的取值
 */
@property (atomic, strong) BDABTestExperimentItemModel *fetchedResult;

@property (atomic, copy) BDABSettingsValueBlock settingsValueBlock;

@end

@implementation BDABTestBaseExperiment

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithKey:(NSString *)key
                      owner:(NSString *)owner
                description:(NSString *)description
               defaultValue:(id)defaultValue
                  valueType:(BDABTestValueType)valueType
                   isSticky:(BOOL)isSticky
{
    return [self initWithKey:key
                       owner:owner
                 description:description
                defaultValue:defaultValue
                   valueType:valueType
                    isSticky:isSticky
          settingsValueBlock:nil];
}

- (instancetype)initWithKey:(NSString *)key
                      owner:(NSString *)owner
                description:(NSString *)description
               defaultValue:(id)defaultValue
                  valueType:(BDABTestValueType)valueType
                   isSticky:(BOOL)isSticky
         settingsValueBlock:(BDABSettingsValueBlock)settingsValueBlock
{
    
    if (!key || key.length == 0) {
        NSAssert(NO, @"Experiment key cannot be null of zero-length.");
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.key = key;
        self.owner = owner;
        self.desc = description;
        self.defaultValue = defaultValue;
        self.settingsValueBlock = settingsValueBlock;
        self.valueType = valueType;
        self.isSticky = isSticky;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFetchedResultUpdated:)
                                                     name:kBDABTestResultUpdatedNotificaion
                                                   object:nil];
    }
    return self;
}

- (void)handleFetchedResultUpdated:(NSNotification *)notification
{
    @synchronized (self.fetchedResult) {
        self.fetchedResult = nil;
    }
}

- (BDABTestExperimentItemModel *)freshValue
{
    if (self.fetchedResult) {
        return self.fetchedResult;
    }
    return [[BDABTestManager sharedManager] savedItemForKey:self.key];
}

/**
 获取实验取值
 支持多线程调用
 
 @param withExposure 是否触发曝光
 @return 实验取值model
 */
- (BDABTestExperimentItemModel *)getResultWithExposure:(BOOL)withExposure
{
    BDABTestExperimentItemModel *result = nil;
    @synchronized (self) {
        if (self.isSticky) {
            if (self.stickyResult) { //本次生命周期中取过sticky的值，则依然取出上次sticky值
                result = self.stickyResult;
            } else {
                if (self.fetchedResult) { //本次生命周期还未取过sticky的值，则尝试去取内存缓存中的值
                    result = self.fetchedResult;
                    self.stickyResult = self.fetchedResult;
                } else { //内存缓存中无值，则尝试去取磁盘中的值
                    self.fetchedResult = [self freshValue];
                    if (self.fetchedResult) { //磁盘中有值，则返回磁盘中的值
                        result = self.fetchedResult;
                        self.stickyResult = self.fetchedResult;
                    } else { //磁盘中无值
                        if (self.settingsValueBlock) { //磁盘中无值，首先返回settings的值
                            id settingsValue = self.settingsValueBlock(self.key);
                            self.stickyResult = [[BDABTestExperimentItemModel alloc] initWithVal:settingsValue vid:nil];
                            result = self.stickyResult;
                        } else {
                            self.stickyResult = [[BDABTestExperimentItemModel alloc] initWithVal:self.defaultValue vid:nil];
                            result = self.stickyResult;
                        }
                    }
                }
            }
        } else {
            self.fetchedResult = [self freshValue];
            if (self.fetchedResult) {
                result = self.fetchedResult;
            } else {
                if (self.settingsValueBlock) {
                    id settingsValue = self.settingsValueBlock(self.key);
                    result = [[BDABTestExperimentItemModel alloc] initWithVal:settingsValue vid:nil];
                } else {
                    result = [[BDABTestExperimentItemModel alloc] initWithVal:self.defaultValue vid:nil];
                }
            }
        }
        
        if (withExposure) {
            [[BDABTestExposureManager sharedManager] exposeVid:result.vid];
        }
    }
    
    if (result.val != nil && ![result.val isKindOfClass:[BDABTestBaseExperiment classForValueType:self.valueType]]) {
        NSAssert(NO, @"The expected value of %@ is %@, but get %@, plese contact %@", self.key, [BDABTestBaseExperiment classForValueType:self.valueType], [result.val class], self.owner);
    }
    
    return result;
}

/**
 获取实验取值
 支持多线程调用
 
 @param withExposure 是否触发曝光
 @return 实验取值
 */
- (id)getValueWithExposure:(BOOL)withExposure
{
    BDABTestExperimentItemModel *result = [self getResultWithExposure:withExposure];
    return result.val;
}

+ (Class)classForValueType:(BDABTestValueType)valueType
{
    switch (valueType) {
        case BDABTestValueTypeNumber:
            return [NSNumber class];
        case BDABTestValueTypeString:
            return [NSString class];
        case BDABTestValueTypeArray:
            return [NSArray class];
        case BDABTestValueTypeDictionary:
            return [NSDictionary class];
    }
    return nil;
}

@end

#pragma mark Client AB Experiment

const NSInteger kBDClientABTestMaxRegion = 999;

@implementation BDClientABTestGroup

- (instancetype)initWithName:(NSString *)name minRegion:(NSInteger)minRegion maxRegion:(NSInteger)maxRegion results:(NSDictionary *)results
{
    if (self = [super init]) {
        _name = name;
        _minRegion = minRegion;
        _maxRegion = maxRegion;
        _results = results;
    }
    return self;
}

- (BOOL)isLegal
{
    //合法性校验
    if (![self.name isKindOfClass:[NSString class]] || [self.name length] <= 0) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"group's name %@ is invalid.",self.name]];
        return NO;
    }
    if (self.minRegion < 0 || self.minRegion > self.maxRegion) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"group named %@ minRegion invalid, should be in the region of [0,maxRegion]",self.name]];
        return NO;
    }
    if (self.maxRegion > kBDClientABTestMaxRegion) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"group named %@ maxRegion invalid, should be in the region of [minRegion,%ld]",self.name,kBDClientABTestMaxRegion]];
        return NO;
    }
    if (![self.results isKindOfClass:[NSDictionary class]]) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"group named %@ results invalid, should be dictionary.",self.name]];
        return NO;
    }
    return YES;
}

@end

@implementation BDClientABTestLayer

- (instancetype)initWithName:(NSString *)name groups:(NSArray *)groups
{
    if (self = [super init]) {
        _name = name;
        _groups = groups;
    }
    return self;
}

- (BOOL)isLegal
{
    //合法性校验
    if (![self.name isKindOfClass:[NSString class]] || [self.name length] <= 0) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"layer's name %@ is invalid.",self.name]];
        return NO;
    }
    if (![self.groups isKindOfClass:[NSArray class]] || [self.groups count] <= 0) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"layer named %@ has no groups.",self.name]];
        return NO;
    }
    for (BDClientABTestGroup *group in self.groups) {
        if (![group isLegal]) {
            return NO;
        }
    }
    return YES;
}

@end

@implementation BDClientABTestExperiment

- (instancetype)initWithKey:(NSString *)key owner:(NSString *)owner description:(NSString *)description defaultValue:(id)defaultValue valueType:(BDABTestValueType)valueType isSticky:(BOOL)isSticky clientLayer:(BDClientABTestLayer *)clientLayer
{
    if (self = [super initWithKey:key owner:owner description:description defaultValue:defaultValue valueType:valueType isSticky:isSticky]) {
        _clientLayer = clientLayer;
    }
    return self;
}

- (BDABTestExperimentItemModel *)freshValue
{
    //服务端setting优先
    id value = [[BDClientABManager sharedManager] serverSettingValueForFeatureKey:self.key];
    if (value) {
        //实验结果被服务端setting修改了，与服务端确认过不再需要上报（可能实验有问题或已全量，总之实验结论已出），因此不需要同步更新当前命中分组
        return [[BDABTestExperimentItemModel alloc] initWithVal:value vid:nil];
    }
    //本地分流
    value = [[BDClientABManager sharedManager] valueForFeatureKey:self.key];
    if (value) {
        //有效vid
        return [[BDABTestExperimentItemModel alloc] initWithVal:value vid:[[BDClientABManager sharedManager] vidForLayerName:self.clientLayer.name]];
    }
    //默认值
    value = self.defaultValue;
    return [[BDABTestExperimentItemModel alloc] initWithVal:value vid:nil];
}

@end
